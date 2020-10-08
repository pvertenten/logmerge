require 'colored'
require 'date'
require 'optparse'



class Numeric
  def minutes; self/1440.0 end
  alias :minute :minutes

  def seconds; self/86400.0 end
  alias :second :seconds

  def milliseconds; self/86400000.0 end
  alias :millisecond :milliseconds
end

class File
  alias :old_initialize :initialize
  alias :old_readline :readline
  def initialize (*args)
    @buf=[]
    old_initialize(*args)
  end
  def unreadline (str)
    @buf.push(str)
  end
  def readline (*args)
    @buf.empty? ? old_readline(*args) : @buf.pop
  end

  def buf
    @buf
  end
end

class Log
  attr_accessor :file, :line, :next, :offet, :tag, :timestamp, :next_timestamp, :finished
  def initialize(path, autotag=false)
    @offset = 0
    if path.include?(':')
      parts = path.split(':')
      path = parts[0]
      @offset = parts[1].to_i
      if parts.size > 2
        @tag = parts[2]
      end
    end
    if @tag.nil? && autotag
      @tag = File.basename(path)
    end
    @file = File.open(path)
    @finished = false
    buffer
  end

  def parseTimestamp(current)
    # puts "parsingTimestamp: #{current}"
    # would be great to generalize this more
    ts = nil
    if current =~ /^\[\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d\.\d\d\d\]/
      # agent logs
      ts_part = current[1...24]
      # puts "ts_part: #{ts_part}"
      ts = DateTime.parse(ts_part)
      ts = ts + @offset.seconds
    elsif current =~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\d[+-]\d\d\d\d/
      #mms logs
      ts_part = current[0...28]
      # puts "ts_part: #{ts_part}"
      ts = DateTime.parse(current[0...28])
      ts = ts + @offset.seconds
    end
    ts
  rescue Date::Error
    nil
  end

  def applyTimestamp(current, timestamp)
    if current =~ /^\[\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d\.\d\d\d\]/
      current[1...24] = timestamp.to_s
    elsif current =~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\d[+-]\d\d\d\d/
      current[0...28] = "[#{timestamp.to_s}]"
    end
    current.prepend("[#{@tag}]") if @tag && timestamp
    current
  end

  def buffer
    @count ||= 0
    # puts "buffer: #{@count}"
    # puts "file buffer: #{file.buf}"
    @count = @count + 1
    # TODO: add support for multiline log statements
    # basically read until next timestamp found including all lines as an entry
    @line = []
    @timestamp = nil
    timestamp_index = 0
    while @timestamp.nil? do
      current = file.readline.strip
      # puts "current: #{current}"
      @timestamp = parseTimestamp(current)
      # puts "timestamp: #{@timestamp}"
      @line.push(current)
      timestamp_index = timestamp_index + 1 if @timestamp.nil?
    end

    applyTimestamp(line[timestamp_index], @timestamp) if line.size > timestamp_index

    next_timestamp = nil
    while next_timestamp.nil? do
      current = file.readline.strip
      # puts "nextcurrent: #{current}"
      next_timestamp = parseTimestamp(current)
      # puts "next_timestamp: #{next_timestamp}"
      file.unreadline(current + "\n") && break unless next_timestamp.nil?
      @line.push(current)
    end
  rescue EOFError
    @finished = true if @line.empty?
  end

  def take
    ret = line
    buffer
    ret
  end
end

class LogMerge
  attr_reader :logs, :startTime, :endTime
  def initialize(files, startTime=Time.at(0), endTime=Time.at(2000000000000), autotag=false)
    @logs = files.map {|f| Log.new(f, autotag)}
    @startTime = DateTime.parse(startTime.to_s)
    @endTime = DateTime.parse(endTime.to_s)
  end

  def merge
    colors = Colored::COLORS.keys.dup
    colors.delete('black')
    while true
      min_log = logs.select {|l| !l.finished}.sort { |a,b| a.timestamp && b.timestamp ? a.timestamp <=> b.timestamp : b.timestamp ? -1 : 1 }.first #could be priority queue instead
      break if min_log.nil?
      next min_log.take unless min_log.timestamp
      next min_log.take if min_log.timestamp < startTime
      break if min_log.nil?
      break if min_log.timestamp > endTime
      index = logs.index(min_log)
      color_index = index % colors.size
      color = colors[color_index]
      loglines = min_log.take
      puts applyColor(loglines, color).join("\n")
    end
  end

  def applyColor(loglines, color)
    loglines.map{|l| Colored.colorize(l, foreground: color)}
  end
end
