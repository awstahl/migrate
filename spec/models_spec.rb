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
    expect { Migration::Server::Porter.new Stub.new }.to raise_exception( 'Migration::InvalidConnection' )
  end

  it 'lists files using a connection' do
    expect( @porter.list '/path/to/files' ).to eq( "./sub/file1.txt\n./sub/file2.txt\n./sub2/file3.lst" )
  end

  it 'prints the contents of a file' do
    expect( @porter.get '/path/to/file' ).to eq( 'all your base are belong to us' )
  end
end

describe 'Migration Server Itself' do

  before :each do
    @conf = { host: 'localhost', user: 'splunk' }
    @srv = Migration::Server.new @conf
  end

  it 'exists' do
    expect( @srv ).to be_truthy
  end

  it 'is accessible' do
    expect( @srv.respond_to? :conf ).to be_truthy
  end

  it 'accepts a hash' do
    expect( @srv.conf[ :host ]).to eq( 'localhost' )
  end

  it 'accepts a block' do
    srv = Migration::Server.new do |conf|
      conf[ :file ] = '/path/to/file.conf'
      conf[ :host ] = 'example.com'
      conf[ :key ] = '/path/to/key.pem'
      conf[ :path ] = '/path/to'
      conf[ :user ] = 'someone'
    end
    expect( srv.conf[ :file ] == '/path/to/file.conf' )
    expect( srv.conf[ :host ] == 'example.com' )
    expect( srv.conf[ :key ] == '/path/to/key.pem' )
    expect( srv.conf[ :path ] == '/path/to' )
    expect( srv.conf[ :user ] == 'someone' )
  end

  it 'has a connection' do

  end

end