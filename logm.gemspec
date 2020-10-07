Gem::Specification.new do |s|
  s.name        = 'logm'
  s.version     = '0.0.2'
  s.date        = '2020-10-07'
  s.summary     = 'Log Merge Utility!'
  s.description = 'A simple logmerge utility'
  s.authors     = ['Peter Vertenten']
  s.email       = 'peter.vertenten@gmail.com'
  s.files       = ['lib/logmerge.rb']
  s.homepage    = 'https://github.com/pvertenten/logmerge/'
  s.license     = 'MIT'
  s.add_runtime_dependency 'colored', ['= 1.2']
  s.add_runtime_dependency 'date', ['= 3.0.1']
  s.executables << 'logm'
end
