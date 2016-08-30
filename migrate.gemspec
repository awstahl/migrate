
Gem::Specification.new do |spec|

  spec.add_runtime_dependency 'net/ssh', '~>0'
  spec.add_runtime_dependency 'optparse', '~>0'
  spec.add_runtime_dependency 'uri', '~>0'
  spec.add_runtime_dependency 'yaml', '~>0'
  spec.add_development_dependency 'rspec', '~>0'

  spec.author = [ 'A. W. Stahl']
  spec.date = '2016-05-19'
  spec.description = 'A Splunk migration and deployment tool'
  spec.email = 'alex@testcore.net'
  spec.executables << 'migrate'
  spec.files = %w(lib/migrate.rb lib/migrate/models.rb)
  spec.license = 'MIT'
  spec.homepage = 'http://rubygems.org'
  spec.name = 'migrate'
  spec.summary = 'Splunk Migrator'
  spec.version = '0.0.1'

end