Gem::Specification.new do |s|
  s.name        = 'logmerge'
  s.version     = '0.0.1'
  s.date        = '2020-10-07'
  s.summary     = "LogMerge!"
  s.description = "A simple logmerge utility"
  s.authors     = ["Peter Vertenten"]
  s.email       = 'peter.vertenten@gmail.com'
  s.files       = ["lib/logmerge.rb"]
  s.homepage    =
    'https://github.com/pvertenten/logmerge/'
  s.license       = 'MIT'
  s.add_runtime_dependency "colored", ["= 1.2"]
  s.executables << 'logmerge'
end
