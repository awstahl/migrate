#
#  File: applications_spec.rb
#  Author: alex@testcore.net
#
#  Tests for a set of classes that models config data.


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/applications.rb"


describe 'Migration Application' do

  before :all do
    @plist = []
    @plist << 'bin/deploy.rb'
    @plist << 'bin/script.rb'
    @plist << 'default/app.conf'
    @plist << 'default/data/models/model.xml'
    @plist << 'default/data/ui/nav/bar.xml'
    @plist << 'default/data/ui/views/main.xml'
    @plist << 'local/inputs.conf'
    @stanza = "[artifact name]\nkey = val\n"
    @conffile = "#{ @stanza }\n[art Two]\nskel = lock"
  end

  before :each do
    @apppath = '/path/to/apps/rspec_test_app'
    if Object.const_defined? "Migration::Application"
      @app = Migration::Application.new root: @apppath
    end
  end

  it 'exists' do
    expect( @app ).to be_truthy
  end

  it 'starts with a root directory' do
    expect( @app.root ).to eq( '/path/to/apps/rspec_test_app' )
  end

  it 'can set a name' do
    @app.name = "123"
    expect( @app.name ).to eq( '123' )
  end

  it 'has a file list' do

  end

end
