#
#  File: migrate.gemspec
#  Author: alex@testcore.net
#

VERSION = '1.1.3.22'

Gem::Specification.new do |spec|

  spec.add_development_dependency 'rspec', '~>0'
  spec.author = [ 'A. W. Stahl']
  spec.date = Time.now.to_s.split.first 

  spec.description = 'A configuration migration and deployment tool. Fetch existing confs, parse & modify, then print.'
  spec.email = 'alex@testcore.net'
  spec.executables << 'migrate'

  spec.files = Dir[ 'lib/**/*.rb' ] + Dir[ 'bin/*' ]
  spec.files += Dir[ '[A-Z]*' ] + Dir[ 'spec/**/*' ]
  spec.files << 'migrate.gemspec'
  spec.license = 'MIT'

  spec.homepage = 'https://github.com/awstahl/migrate'
  spec.name = 'migrate'
  spec.summary = 'Configuration Migration Toolkit'

  spec.version = VERSION
end
