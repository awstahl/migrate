require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/models.rb"


describe 'Migration Artifact' do

  before :all do
    @source = "[artifact name]\nkey = val\n"
  end

  before :each do
    @art = Migration::Artifact.new @source
  end

  it 'exists' do
    expect( @art ).to be_truthy
  end

  it 'exposes the source string' do
    expect( @art.source ).to eq( @source )
  end

  it 'exposes a data container' do
    expect( @art.data ).to eq( nil )
  end

  it 'uses a default parser to parse' do
    @art.parse
    expect( @art.data[ :key ]).to eq( 'val' )
  end

  it 'parses the name from the source' do
    @art.parse
    expect( @art.name ).to eq( 'artifact name' )
  end

  # it 'can print itself formatted' do
  #   expect( @art.to_s ).to eq( @source )
  # end
  #
  # it 'prints in alpha order by keys' do
  #   @str.parser = @parser
  #   @str.parse
  #   @str[ :cat ] = 'bar'
  #   @str[ :manx ] = 'zoo'
  #   @str[ :abc ] = 'foo'
  #   expect( @str.to_s ).to eq( "[artifact name]\nabc = foo\ncat = bar\nmanx = zoo\nsearch = index=foobar\n\n")
  # end

end

describe 'Migration Application' do

  before :all do
    @paths = []
    @paths << 'bin/deploy.rb'
    @paths << 'bin/script.rb'
    @paths << 'default/app.conf'
    @paths << 'default/data/models/model.xml'
    @paths << 'default/data/ui/nav/bar.xml'
    @paths << 'default/data/ui/views/main.xml'
    @paths << 'local/inputs.conf'
    @conf = {
        paths: @paths,
        root: '/path/to/apps/rspec_test_app'
    }
  end

  before :each do
    @app = Migration::Application.new @conf
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
    @app.configure 'local/inputs.conf', 'some file contents'
    expect( @app.conf[ 'local' ][ 'inputs.conf' ]).to include( 'some file contents')
  end

  it 'really can be configured' do
    @app.configure 'default/data/models/model.xml', "<xml>\n<head>some xml data</head>\n</xml>"
    expect( @app.conf[ 'default' ][ 'data' ][ 'models' ][ 'model.xml' ]).to include( "<xml>\n<head>some xml data</head>\n</xml>" )
  end

  it 'can be configured with arbitrary content' do
    @app.configure 'default/data/models/model.xml', 3.14159
    expect( @app.conf[ 'default' ][ 'data' ][ 'models' ][ 'model.xml' ]).to include( 3.14159 )
  end

  it 'adds new paths to the paths array' do
    @app.configure 'some/new/file.conf', 'Where is the proud ship?'
    expect( @app.paths ).to include( 'some/new/file.conf' )
  end

  it 'adds new content to a new file' do
    @app.configure 'some/new/file.conf', 'Where is the proud ship?'
    expect( @app.conf[ 'some' ][ 'new' ][ 'file.conf' ]).to include( 'Where is the proud ship?' )
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
    @remote = instance_double 'Net::SSH::Connection::Session'
    allow( @remote ).to receive( :exec! ) { 'll'}.and_return '/path/to/files...'

    @proto = class_double 'Net::SSH'
    allow( @proto ).to receive( :start ).and_return @remote
  end

  before :each do
    mocks
    @conf = { connection: { host: 'localhost', user: 'splunk', keyfile: "#{ File.dirname __FILE__ }/data/sample.key", proto: @proto }}
    @srv = Migration::Server.new @conf
  end

  it 'exists' do
    expect( @srv ).to be_truthy
  end

  it 'is accessible' do
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

  it 'can fetch an application' do

  end

end
