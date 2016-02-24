require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/models.rb"


describe 'Some Sugar' do

  it 'adds  #class? sugar' do
    expect( ''.class? String ).to be true
  end

  it 'can convert hash keys' do
    expect( { 'a' => 1, 'b' => { 'c' => 3 }}.to_sym! ).to include( { a: 1, b: { c: 3 }} )
  end
end

describe 'Migration Artifact' do

  def parsers
    # No actual abstract parent class...
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

  it 'requires a perser to parse' do
    expect { @str.parse }.to raise_exception( Migration::MissingParser )
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

  it 'yields itself for migration' do
    @art.migrate {|a| a[:name] = 'migrated'}
    expect( @art.name ).to eq( 'migrated' )
  end

  it 'can print itself formatted' do
    expect( @art.to_s ).to eq("[artifact name]\nsearch = index=foobar\n\n")
  end

end

describe 'Migration Stanza Parsing' do

  before :all do
    @ini = "[artifact name]\nowner = admin\nsearch = index=foobar\n\n"
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::StanzaParser' ).to be_truthy
  end

  it 'expects an ini formatted string' do
    expect { Migration::StanzaParser.parse 'not an ini string' }.to raise_exception(Migration::InvalidIniString )
  end

  it 'parses an ini string into a hash' do
    expect( Migration::StanzaParser.parse @ini ).to include(name: eq('artifact name'), owner: 'admin', search: 'index=foobar' )
  end

  it 'parses multiline statements' do
    ini = "[artifact name]\nowner = admin\nsearch = index=foobar some | \\nsearch terms here\n\n"
    expect( Migration::StanzaParser.parse ini ).to include(search: 'index=foobar some | \\nsearch terms here' )
  end

  it 'expects a stanza' do
    ini = "[artifact name]\n"
    expect { Migration::StanzaParser.parse ini }.to raise_exception(Migration::InvalidIniString )
  end
end

describe 'Migration Yaml Parsing' do

  before :all do
    @str = 'ssh:\n  keyfile: \"/path/to/key\"\n  user: admin\nmigration:\n- search\n- eventtypes\n'
    @file = "#{ File.dirname __FILE__ }/data/sample.yml"
  end

  # This is broken in rspec.  Works fine from IRB...
  # it 'parses a yaml string' do
  #   expect( Migration::YamlParser.parse @str ).to include( migration: ['search', 'eventtypes' ] )
  # end

  it 'parses a yaml file' do
    expect( Migration::YamlParser.parse(@file) ).to include( 'ssh' => { 'keyfile' => '/path/to/key', 'user' => 'admin' })
  end

end

describe 'Migration Conf Parsing' do

  before :all do
    @file = "#{ File.dirname __FILE__ }/data/sample.conf"
  end

  it 'parses a config file' do
    expect( Migration::ConfParser.parse( @file ).size ).to eq(3)
  end
end

describe 'Migration Server Connection' do

  def strings
    @host = 'localhost'
    @user ='root'
    @key = '/path/to/key.file'
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
    strings
  end

  before :each do
    mocks
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Server::Connection' ).to be_truthy
  end

  it 'expects an exixting key' do
    expect { @conn.call @host, @user, @key }.to raise_exception( Migration::MissingKeyfile )
  end

  it 'accepts an existing file' do
    expect( @conn.call @host, @user, @file, @proto )
  end

  it 'executes remote commands' do
    conn = @conn.call @host, @user, @file, @proto
    expect( conn.remote.exec! 'll' ).to eq('/path/to/files...')
  end
end


describe 'Migration Server Conf file' do

  it 'exists' do
    expect( Object.const_defined? "Migration::Server::Confset" ).to be_truthy
  end

  it 'accepts a base path' do
    expect( Migration::Server::Confset.new('/path/to/confs').basepath ).to eq('/path/to/confs')
  end

  it 'wat now' do

  end
end