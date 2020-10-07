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

class Log
  attr_accessor :file, :line, :offet, :tag, :timestamp, :finished
  def initialize(path)
    @offset = 0
    if path.include?(':')
      parts = path.split(':')
      path = parts[0]
      @offset = parts[1].to_i
      if parts.size > 2
        @tag = parts[2]
      end
    end
    @file = File.open(path)
    @finished = false
    buffer
  end

  def parseTimestamp(line)
    # would be great to generalize this more
    if line[0] == '['
      # agent logs
      ts = DateTime.parse(line[1...24])
      ts = ts + @offset.seconds
      line[1...24] = ts.to_s
    else
      #mms logs
      ts = DateTime.parse(line[0...28])
      ts = ts + @offset.seconds
      line[0...28] = "[#{ts.to_s}]"
    end
    ts
  end

  def buffer
    begin
      @line = file.readline.strip
      @timestamp = parseTimestamp(line)
      line.prepend("[#{@tag}]") if @tag
    rescue Date::Error
      @timestamp = nil
    end
  rescue EOFError
    @line = nil
    @finished = true
    @timestamp = nil
  end

  def take
    ret = line
    buffer
    ret
  end
end

class LogMerge
  attr_reader :logs, :startTime, :endTime
  def initialize(files, startTime=Time.at(0), endTime=Time.at(2000000000000))
    @logs = files.map {|f| Log.new(f)}
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
      puts Colored.colorize(min_log.take, foreground: color)
    end
  end
end
