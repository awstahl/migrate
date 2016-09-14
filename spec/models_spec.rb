#
#  File: models.rb
#  Author: alex@testcore.net
#
#  Tests for a set of classes that models config data.


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/models.rb"


describe 'Migration Artifact' do

  def mocks
    @parser = double
    allow( @parser ).to receive( :parse ).and_return({ a: 1, b: 2, 'name' => 'mockd' })

    @printer = double
    allow( @printer ).to receive( :print ).with( any_args ).and_return 'Damn yer pirate, feed the ale.'
  end

  before :all do
    @source = "[artifact name]\nkey = val\n"
  end

  before :each do
    mocks
    @art = Migration::Artifact.new @source
  end

  it 'exists' do
    expect( @art ).to be_truthy
  end

  it 'exposes the source string' do
    expect( @art.source ).to eq( @source )
  end

  it 'uses a default parser to parse' do
    expect( @art.data[ 'key' ]).to eq( 'val' )
  end

  it 'parses the name from the source' do
    expect( @art.name ).to eq( 'artifact name' )
  end

  it 'can inject a parser' do
    @art.parse @parser
    expect( @art.name ).to eq( 'mockd' )
  end

  it 'accepts a printer' do
    @art.printer = @printer
    expect( @art.printer ).to eq( @printer )
  end

  it 'uses the printer to print' do
    @art.printer = @printer
    expect( @art.print ).to eq( 'Damn yer pirate, feed the ale.' )
  end

  it 'defaults to the ini printer' do
    expect( @art.print ).to eq( "[artifact name]\nkey = val\n" )
  end

  it 'knows if it has some data' do
    expect( @art.has? 'key' ).to be_truthy
  end

  it 'knows if it does not have some data' do
    expect( @art.has? 'foo' ).to be_falsey
  end

  it 'knows it does not have data' do
    art = Migration::Artifact.new ''
    expect( art.has? :it ).to be_falsey
  end

  it 'can fix some data' do
    @art.fix! 'key', 'new val'
    expect( @art.data[ 'key' ]).to eq( 'new val' )
  end

end

describe 'Migration Application' do

  def mocks
    @porter = double
    allow( @porter ).to receive( :get ).with( any_args ).and_return @conffile
    allow( @porter ).to receive( :list ).with( any_args ).and_return @paths

    @portwo = double
    allow( @portwo ).to receive( :get ).with( any_args ).and_return @stanza
    allow( @portwo ).to receive( :list ).with( any_args ).and_return @paths

    @portre = double
    allow( @portre ).to receive( :get ).with( any_args ).and_return 3.14159
    allow( @portre ).to receive( :list ).with( any_args ).and_return @paths

    @container = double
    allow( @container ).to receive( :new ).with( any_args ).and_return @container
    allow( @container ).to receive( :name ).with( any_args ).and_return 'tstCntr'

    @printer = double
    allow( @printer ).to receive( :print ).with( any_args ).and_return @conffile
  end

  before :all do
    @paths = []
    @paths << 'bin/deploy.rb'
    @paths << 'bin/script.rb'
    @paths << 'default/app.conf'
    @paths << 'default/data/models/model.xml'
    @paths << 'default/data/ui/nav/bar.xml'
    @paths << 'default/data/ui/views/main.xml'
    @paths << 'local/inputs.conf'
    @stanza = "[artifact name]\nkey = val\n"
    @conffile = "#{ @stanza }\n[art Two]\nskel = lock\n"
  end

  before :each do
    mocks
    @conf = { root: '/path/to/apps/rspec_test_app', porter: @porter }
    @app = Migration::Application.new @conf
    @skel = Migration::Application.new root: '/path/to/somewhere/else'
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
    conf = { a: 1, b: 2 }
    expect{ Migration::Application.new conf }.to raise_exception( Migration::MissingPathRoot )
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
  end

  it 'can configure a file' do
    @app.configure 'local/inputs.conf'
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].first.name ).to eq( 'artifact name' )
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

  it 'can inject a new container for parsed file data' do
    @app.configure 'local/inputs.conf', @container
    expect( @app.conf[ 'local' ][ 'inputs.conf' ].first.name ).to eq( 'tstCntr' )
  end

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

  it 'can use the porter to list paths' do
    app = Migration::Application.new root: '/path/to/nowhere', porter: @porter
    expect( app.paths ).to eq( @paths )
  end

  it 'has a default printer' do
    expect( @app.printer ).to eq( Migration::Printer )
  end

  it 'can print all files to a hash' do
    expect( @app.print.class ).to eq( Hash )
  end

  it 'prints paths as keys' do
    expect( @app.print.keys ).to eq( @paths )
  end

  it 'prints contents as values' do
    @app.printer = @printer
    @app.print.each do |file, conf|
      expect( conf ).to eq( @conffile )
    end
  end

  it 'can print a single conf file' do
    @app.printer = @printer
    expect( @app.print 'local/inputs.conf' ).to eq( @conffile )
  end

  it 'can accept a printer' do
    @app.printer = @printer
    expect( @app.printer ).to eq( @printer )
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
      expect( Array === conf ).to be_truthy
    end
  end

end

describe 'Migration Server Connection' do

  def conf
    @conf = { host: 'localhost', user: 'root', keyfile: "#{ File.dirname __FILE__ }/data/sample.key" }
  end

  def mocks
    @remote = instance_double 'Net::SSH::Connection::Session'
    allow( @remote ).to receive( :exec! ) { 'll'}.and_return '/path/to/files...'

    @proto = class_double 'Net::SSH'
    allow( @proto ).to receive( :start ).and_return @remote
  end

  before :all do
    @file = "#{ File.dirname __FILE__ }/data/sample.conf"
  end

  before :each do
    conf
    mocks
    @conf[ :proto ] = @proto
    @conn = Migration::Server::Connection.new @conf
  end

  it 'exists' do
    expect( @conn ).to be_truthy
  end

  it 'exposes a connection hash' do
    expect( @conn.conf[ :host ] == 'localhost' ).to be_truthy
    expect( @conn.conf[ :user ] == 'root' ).to be_truthy
    expect( @conn.conf.key? :keyfile ).to be_truthy
  end

  it 'expects an existing key' do
    @conf[ :keyfile ] = '/path/to/n0where'
    expect { Migration::Server::Connection.new @conf }.to raise_exception( Migration::MissingKeyfile )
  end

  it 'executes remote commands' do
    expect(( @conn ).exec 'll' ).to eq('/path/to/files...')
  end
end

describe 'Migration Server Porter' do

  before :all do
    class Stub; end
  end

  before :each do
    @conn = double 'Migration::Server::Connection'
    allow( @conn ).to receive( :exec ).with( 'find /path/to/files -type f -iname "*"' ).and_return( "./sub/file1.txt\n./sub/file2.txt\n./sub2/file3.lst" )
    allow( @conn ).to receive( :exec ).with( 'cat /path/to/file' ).and_return( 'all your base are belong to us' )
    @porter = Migration::Server::Porter.new @conn
  end

  it 'exists' do
    expect( @porter ).to be_truthy
  end

  it 'requires an exec method' do
    expect { Migration::Server::Porter.new Stub.new }.to raise_exception( Migration::InvalidConnection )
  end

  it 'lists files using a connection' do
    expect( @porter.list '/path/to/files' ).to eq( %w[./sub/file1.txt ./sub/file2.txt ./sub2/file3.lst ])
  end

  it 'requires an actual file path' do
    expect{ @porter.list 'lorem ipsum' }.to raise_exception( Migration::InvalidPath )
  end

  it 'prints the contents of a file' do
    expect( @porter.get '/path/to/file' ).to eq( 'all your base are belong to us' )
  end

  it 'requires a full path to print' do
    expect{ @porter.get 'nothing' }.to raise_exception( Migration::InvalidPath )
  end
end

describe 'Migration Server Itself' do

  def mocks
    remote
    proto
    app
    @container = double
    loop_paths
  end

  def remote
    @remote = instance_double 'Net::SSH::Connection::Session'
    allow( @remote ).to receive( :exec! ) { 'll'}.and_return '/path/to/files...'
  end

  def proto
    @proto = class_double 'Net::SSH'
    allow( @proto ).to receive( :start ).and_return @remote
  end

  def app
    @app = double
    allow( @app ).to receive( :configure ).with( no_args ).and_return true
    allow( @app ).to receive( :name ).and_return 'mockApp'
    allow( @app ).to receive( :paths ).and_return @paths.keys
    allow( @app ).to receive( :porter= ).and_return true
    allow( @app ).to receive( :root ).and_return '/path/to/app'
  end

  def loop_paths
    @paths.each do |path, text|
      allow( @remote ).to receive( :exec! ).with( "cat #{ path }" ).and_return text
      allow( @app ).to receive( :configure ).with(path, any_args ).and_return text

      text.each do |item|
        allow( @container ).to receive( :new ).with( item ).and_return item
      end
    end
  end

  before :each do
    @paths = {
        '/path/to/app/default/file.conf' => %w[ Dozens of tragedies will be lost in beauties like sonic showers in understandings ],
        '/path/to/app/default/other.conf' => %w[ Not heavens or hell, absorb the samadhi. ],
        '/path/to/app/local/file.conf' => %w[ Yarr, lively fortune! ]
    }
    mocks
    @conf = { connection: { host: 'localhost', user: 'splunk', keyfile: "#{ File.dirname __FILE__ }/data/sample.key", proto: @proto }}
    @srv = Migration::Server.new @conf
  end

  it 'exists' do
    expect( @srv ).to be_truthy
  end

  it 'has a configuration' do
    expect( @srv.respond_to? :conf ).to be_truthy
  end

  it 'accepts a hash' do
    expect( @srv.conf[ :connection ][ :host ]).to eq( 'localhost' )
  end

  it 'has a connection' do
   expect( @srv.connection ).to be_truthy
  end

  it 'has a porter' do
    expect( @srv.porter ).to be_truthy
  end

  it 'has an application hash' do
    expect( @srv.apps ).to eq({})
  end

  it 'can fetch app configuration' do
    @srv.fetch @app
    expect( @srv.apps[ @app.name ]).to eq( @app )
  end

end
