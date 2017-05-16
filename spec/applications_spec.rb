#
#  File: applications_spec.rb
#  Author: alex@testcore.net
#
#  Tests for a set of classes that models config data.


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/applications.rb"

describe 'Migration Application' do

  def mocks
    @paths = @plist.clone

    @porter = double
    allow( @porter ).to receive( :get ).with( any_args ).and_return @conffile
    allow( @porter ).to receive( :list ).with( any_args ).and_return @paths

    @portwo = double
    allow( @portwo ).to receive( :get ).with( any_args ).and_return "#{ @stanza }\n"
    allow( @portwo ).to receive( :list ).with( any_args ).and_return @paths

    @portre = double
    allow( @portre ).to receive( :get ).with( any_args ).and_return 3.14159
    allow( @portre ).to receive( :list ).with( any_args ).and_return @paths

    @container = double
    allow( @container ).to receive( :produce ).with( any_args ).and_return @container
    allow( @container ).to receive( :name ).with( any_args ).and_return 'tstCntr'

    @print = double
    allow( @print ).to receive( :it ).with( any_args ).and_return @conffile
  end

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
    mocks
    apppath = '/path/to/apps/rspec_test_app'
    @app = Migration::Application.new root: apppath, porter: @porter
    @skel = Migration::Application.new root: apppath
  end

  it 'exists' do
    expect( @app ).to be_truthy
  end

  it 'has a name' do
    expect( @app.name ).to eq( 'rspec_test_app' )
  end

  it 'has a root directory' do
    expect( @app.root ).to eq( '/path/to/apps/rspec_test_app' )
  end

  it 'requires a root directory' do
    expect{ Migration::Application.new 'abc' }.to raise_exception( ArgumentError )
  end

  it 'has a paths array' do
    expect( @app.paths ).to eq( @paths )
  end

  it 'has a config hash' do
    expect( @app.conf.keys ).to eq( %w[ bin default local ])
  end

  it 'can be configured' do
    @app.configure
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].first.name ).to eq( 'artifact name' )
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].last.name ).to eq( 'art Two' )
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].size ).to eq( 2 )
  end

  it 'can configure a file' do
    @app.configure 'local/inputs.conf'
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].first.name ).to eq( 'artifact name' )
    expect( @app.conf[ 'default' ][ 'app.conf' ]).to eq({})
  end

  it 'configures single-stanza confs' do
    @app.porter = @portwo
    @app.configure 'local/inputs.conf'
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].first.name ).to eq( 'artifact name' )
  end

  it 'skips non-app files' do
    @app.configure 'this/is/not/a/file.conf'
    expect( @app.conf.key? 'this' ).to be_falsey
  end

  it 'requires a porter to configure' do
    @skel.configure 'local/inputs.conf'
    expect( @skel.conf ).to eq({})
  end

  it 'can set a porter' do
    @skel.porter = @porter
    @skel.configure 'local/inputs.conf'
    expect( @skel.conf[ 'local' ][ 'inputs.conf' ].first.name ).to eq( 'artifact name' )
  end

  # *** BUG HERE ***
  it 'wraps parsing results in an array' do
    @skel.porter = @portre
    @skel.configure 'local/inputs.conf'
    expect( @skel.conf[ 'local' ][ 'inputs.conf' ].first.data ).to eq( 3.14159 )
  end

  it 'can retrieve data by path' do
    expect( @app.retrieve( 'local/inputs.conf')).to eq({})
  end

  it 'can retrieve configured data by path' do
    @app.porter = @porter
    @app.configure 'local/inputs.conf'
    expect( @app.retrieve( 'local/inputs.conf').first.name ).to eq( 'artifact name' )
  end

  it 'can filter conf files by regex' do
    @app.configure /\.(conf|xml)$/
    expect( @app.retrieve( 'local/inputs.conf').first.name ).to eq( 'artifact name' )
  end

  it 'can use the porter to list paths' do
    app = Migration::Application.new root: '/path/to/nowhere', porter: @porter
    expect( app.paths ).to eq( @paths )
  end

  it 'has a default printer' do
    expect( @app.printer ).to eq( Migration::Print )
  end

  it 'can print all files to a hash' do
    expect( @app.print.class ).to eq( Hash )
  end

  it 'prints paths as keys' do
    expect( @app.print.keys ).to eq( @paths )
  end

  it 'prints contents as values' do
    @app.printer = @print
    @app.print.each do |file, conf|
      expect( conf ).to eq( @conffile )
    end
  end

  it 'can print a single conf file' do
    @app.printer = @print
    expect( @app.print 'local/inputs.conf' ).to eq( @conffile )
  end

  it 'can accept a printer' do
    @app.printer = @print
    expect( @app.printer ).to eq( @print )
  end

  it 'offers an enumerator' do
    expect( @app.respond_to? :each ).to be_truthy
  end

  it 'is enumerable' do
    expect( @app.is_a? Enumerable ).to be_truthy
  end

  it 'can enumerate configured confs' do
    @app.configure
    @app.each do |conf|
      expect( @paths ).to include( conf )
    end
  end

  it 'can filter by regex' do
    i = 0
    @app.each /conf$/ do |conf|
      i += 1
    end
    expect( i ).to eq( 2 )
  end

  it 'can filter by arbitrary regex' do
    i = 0
    @app.each /local\/.+\.conf$/ do |conf|
      i += 1
    end
    expect( i ).to eq( 1 )
  end

  it 'can yield the path and contents' do
    @app.configure
    @app.each /local\/.+\.conf$/ do |path, conf|
      expect( @paths ).to include( path )
      expect( conf.is_a? Enumerable ).to be_truthy
    end
  end

  it 'can add a file' do
    @app.add_file 'local/nonsense.conf'
    expect( @app.paths ).to include( 'local/nonsense.conf' )
  end

  it 'can add a file with contents' do
    @app.add_file 'local/nonsense.conf', @conffile
    expect( @app.retrieve( 'local/nonsense.conf' ).last.name ).to eq( 'art Two' )
  end

  it 'overwrites existing files' do
    @app.add_file 'local/nonsense.conf', @conffile
    @app.add_file 'local/nonsense.conf', @stanza
    expect( @app.retrieve( 'local/nonsense.conf' ).last.name ).to eq( 'artifact name' )
  end

  it 'can add a stanza to a file' do
    @app.add_file 'local/nonsense.conf', @conffile
    @app.add_stanza 'local/nonsense.conf', @stanza
    expect( @app.retrieve( 'local/nonsense.conf' ).last.name ).to eq( 'artifact name' )
  end

  it 'can only add to existing files' do
    expect( @app.add_stanza 'local/nonsense.conf', @stanza ).to be_falsey
  end

  it 'can fetch content of all files matching a criteria' do
    @app.configure 'local/inputs.conf'
    expect( @app.contents /\.conf$/  ).to be_a_kind_of( Enumerable )
  end

  it 'cat apply a block to content of all files matching a criteria' do
    @app.configure
    files = []
    @app.contents /\.conf$/ do |file, contents|
      files << file
    end
    expect( files.sort ).to eq( @paths.select{|file| file =~ /\.conf$/}.sort )
  end

end
