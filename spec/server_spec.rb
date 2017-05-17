#
#  File: server_spec.rb
#  Author: alex@testcore.net
#
#  Tests for a set of classes that model server communication


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/server.rb"


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
    @conn = Migration::Server::Connection.new @conf if Object.const_defined? 'Migration::Server::Connection'
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
    expect( @conn.exec( 'll' )).to eq( '/path/to/files...' )
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
    @porter = Migration::Server::Porter.new @conn if Object.const_defined? 'Migration::Server::Porter'
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
    @filter = /\.conf$/
    @app = double
    allow( @app ).to receive( :configure ).with( any_args ).and_return true
    allow( @app ).to receive( :name ).and_return 'mockApp'
    allow( @app ).to receive( :paths ).and_return @paths.keys
    allow( @app ).to receive( :porter= ).and_return true
    allow( @app ).to receive( :root ).and_return '/path/to/app'

    @app2 = double @app
    allow( @app2 ).to receive( :name ).and_return 'mockAppTwo'
    allow( @app2 ).to receive( :paths ).and_return @paths.keys.select {|key| key =~ @filter }
    allow( @app2 ).to receive( :porter= ).and_return true
  end

  def loop_paths
    @paths.each do |path, text|
      allow( @remote ).to receive( :exec! ).with( "cat #{ path }" ).and_return text
      allow( @app ).to receive( :configure ).with( path, any_args ).and_return text
      allow( @app2 ).to receive( :configure ).with( /\.conf$/, any_args ).and_return text

      text.each do |item|
        allow( @container ).to receive( :new ).with( item ).and_return item
      end
    end
  end

  before :each do
    @filter = /\.conf$/
    @paths = {
        '/path/to/app/default/file.conf' => %w[ Dozens of tragedies will be lost in beauties like sonic showers in understandings ],
        '/path/to/app/default/other.conf' => %w[ Not heavens or hell, absorb the samadhi. ],
        '/path/to/app/local/file.xml' => %w[ Yarr, lively fortune! ]
    }
    mocks
    @conf = { connection: { host: 'localhost', user: 'splunk', keyfile: "#{ File.dirname __FILE__ }/data/sample.key", proto: @proto }}
    @srv = Migration::Server.new @conf if Object.const_defined? 'Migration::Server'
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

  it 'can fetch filtered configs' do
    @srv.fetch @app2, @filter
    expect( @srv.apps[ @app2.name ].paths ).to eq( %w[ /path/to/app/default/file.conf /path/to/app/default/other.conf ])
  end

end
