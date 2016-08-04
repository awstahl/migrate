require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/models.rb"

# TODO: Moar tests

describe 'Migration Artifact' do

  def parsers
    @parser = double 'Migration::Parser'
    allow( @parser ).to receive( :parse ).and_return( name: 'artifact name', search: 'index=foobar' )
  end

  def artifacts

    # Basic, unpopulated Artifact
    @str = Migration::Artifact.new 'artifact'

    # Parsed artifact (using a mock)
    @art = Migration::Artifact.new '[artifact name]'
    @art.parser = @parser
    @art.parse
  end

  before :each do
    parsers
    artifacts
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Artifact' ).to be_truthy
  end

  it 'accepts a string' do
    expect( @str.class ).to eq( Migration::Artifact )
  end

  it 'exposes the source string' do
    expect( @str.source ).to eq( 'artifact' )
  end

  it 'can set the source string' do
    @str.source = 'difference'
    expect( @str.source ).to eq( 'difference' )
  end

  it 'accepts a block' do
    artifact = Migration::Artifact.new do |art|
      art.source = 'some text'
    end
    expect( artifact.source ).to eq( 'some text' )
  end

  it 'uses a default parser to parse' do
    art = Migration::Artifact.new "[stanza]\nkey = val\n"
    art.parse
    expect( art.name ).to eq( 'stanza' )
  end

  it 'accepts a parser' do
    expect( @art.parser ).to eq( @parser )
  end

  it 'parses the name from the source' do
    expect( @art.name ).to eq( 'artifact name' )
  end

  it 'can list its parsed keys' do
    expect( @art.keys ).to include( :search )
  end

  it 'can verify a key' do
    expect( @art.key? :search ).to be_truthy
  end

  it 'yields itself for migration' do
    @art.migrate { |a| a[ :name ] = 'migrated' }
    expect( @art.name ).to eq( 'migrated' )
  end

  it 'can print itself formatted' do
    expect( @art.to_s ).to eq( "[artifact name]\nsearch = index=foobar\n\n" )
  end

  it 'prints in alpha order by keys' do
    @str.parser = @parser
    @str.parse
    @str[ :cat ] = 'bar'
    @str[ :manx ] = 'zoo'
    @str[ :abc ] = 'foo'
    expect( @str.to_s ).to eq( "[artifact name]\nabc = foo\ncat = bar\nmanx = zoo\nsearch = index=foobar\n\n")
  end

end

describe 'Migration Application' do

  def parsers
    @parser = double 'Migration::Parser'
    @result = { 'default' => { 'app.conf' => [] }, 'local' => { 'auth.conf' => [] }, 'meta' => { 'local.meta' => [] } }
    allow( @parser ).to receive( :parse ).and_return( @result )
  end

  def apps
    @base = "#{ File.dirname __FILE__ }/data/app"
    @appp = Migration::Application.new @base, @parser
  end

  before :each do
    @base = "#{ File.dirname __FILE__ }/data"
    parsers
    apps
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Application' ).to be_truthy
  end

  it 'is a type of Artifact' do
    expect( Migration::Application.allocate.kind_of? Migration::Artifact ).to be_truthy
  end

  it 'requires an absolute path' do
    expect { Migration::Application.new( 'relative/path') }.to raise_exception (Migration::InvalidPath )
  end

  it 'provides a hash interface to its contents' do
    @appp.parse
    expect( @appp[ 'default' ][ 'app.conf' ] ).to eq([])
    expect( @appp[ 'local' ][ 'auth.conf' ] ).to eq([])
    expect( @appp[ 'meta' ][ 'local.meta' ] ).to eq([])
  end

  it 'prints a file list' do
    @appp.parse
    expect( @appp.list ).to eq( "#{ @base }/default/app.conf\n#{ @base }/local/auth.conf\n#{ @base }/meta/local.meta\n" )
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
    @conn = Migration::Server::Connection.method :new
    @file = "#{ File.dirname __FILE__ }/data/sample.conf"
  end

  before :each do
    conf
    mocks
    @conf[ :proto ] = @proto
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Server::Connection' ).to be_truthy
  end

  it 'is a connection' do
    expect( (@conn.call @conf ).class ).to eq( Migration::Server::Connection )
  end

  it 'accepts a connection hash' do
    c = @conn.call @conf
    expect( c.conf[ :host ] == 'localhost' ).to be_truthy
    expect( c.conf[ :user ] == 'root' ).to be_truthy
    expect( c.conf.key? :keyfile ).to be_truthy
  end

  it 'expects an existing key' do
    @conf[ :keyfile ] = '/path/to/n0where'
    expect { @conn.call @conf }.to raise_exception( Migration::MissingKeyfile )
  end


  it 'executes remote commands' do
    expect(( @conn.call @conf ).exec 'll' ).to eq('/path/to/files...')
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
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Server::Porter' ).to be_truthy
  end

  it 'accepts an executor' do
    expect( Migration::Server::Porter.new @conn ).to be_truthy
  end

  it 'requires an exec method' do
    expect { Migration::Server::Porter.new Stub.new }.to raise_exception( 'Migration::InvalidConnection' )
  end

  it 'lists files using a connection' do
    expect( Migration::Server::Porter.new( @conn ).list '/path/to/files' ).to eq( "./sub/file1.txt\n./sub/file2.txt\n./sub2/file3.lst" )
  end

  it 'prints the contents of a file' do
    expect( Migration::Server::Porter.new( @conn ).get '/path/to/file' ).to eq( 'all your base are belong to us' )
  end
end

describe 'Migration Server Itself' do

  before :each do
    @default = Migration::Server.new
    @conf = { host: 'localhost', user: 'splunk' }
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Server::Conf' ).to be_truthy
  end

  it 'is accessible' do
    expect( @default.respond_to? :conf ).to be_truthy
  end

  it 'accepts a hash' do
    srv = Migration::Server.new @conf
    expect( @srv.conf.host ).to eq( 'localhost' )
  end

  it 'accepts a block' do
    @srv = Migration::Server.new do |conf|
      conf.file = '/path/to/file.conf'
      conf.host = 'example.com'
      conf.key = '/path/to/key.pem'
      conf.path = '/path/to'
      conf.user = 'someone'
    end
    expect( @srv.conf.file == '/path/to/file.conf' )
    expect( @srv.conf.host == 'example.com' )
    expect( @srv.conf.key == '/path/to/key.pem' )
    expect( @srv.conf.path == '/path/to' )
    expect( @srv.conf.user == 'someone' )
  end

end