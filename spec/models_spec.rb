require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/models.rb"

# TODO: Moar tests

describe 'Some Sugar' do

  it 'adds  #class? sugar' do
    expect( ''.class? String ).to be true
  end

  it 'flattens hashes to paths' do
    hsh = { 'default' => { 'app.conf' => [] }, 'local' => { 'auth.conf' => [] }, 'meta' => { 'local.meta' => [] } }
    expect( hsh.to_paths ).to eq( "default/app.conf\nlocal/auth.conf\nmeta/local.meta\n" )
  end

  it 'accepts a prefix to hash paths' do
    hsh = { 'default' => { 'app.conf' => [] }, 'local' => { 'auth.conf' => [] }, 'meta' => { 'local.meta' => [] } }
    expect( hsh.to_paths '/path/to').to eq( "/path/to/default/app.conf\n/path/to/local/auth.conf\n/path/to/meta/local.meta\n" )
  end

end

describe 'Migration Validator' do

  it 'exists' do
    expect( Object.const_defined? 'Migration::Valid' ).to be_truthy
  end

  it 'validates a file' do
    expect( Migration::Valid.file? __FILE__ ).to be_truthy
  end

  it 'rejects a non-existent file' do
    expect( Migration::Valid.file? '/path/to/nowhere' ).to be_falsey
  end

  it 'validates an absolute path' do
    expect( Migration::Valid.absolute_path? '/path/to/nowhere' ).to be_truthy
  end

  it 'rejects relative paths' do
    expect( Migration::Valid.absolute_path? 'some/other/path' ).to be_falsey
  end

  it 'validates a yaml file' do
    expect( Migration::Valid.yaml? "#{ File.dirname __FILE__ }/data/sample.yml" ).to be_truthy
  end

  it 'rejects a non-yaml file' do
    expect( Migration::Valid.yaml? '/not/a/yaml.txt' ).to be_falsey
  end

  it 'validates a conf file' do
    expect( Migration::Valid.conf? "#{ File.dirname __FILE__ }/data/sample.conf" ).to be_truthy
  end

  it 'rejects a non-conf file' do
    expect( Migration::Valid.conf? '/not/a/conf.txt' ).to be_falsey
  end

  it 'validates an ini string' do
    expect( Migration::Valid.ini? "[Test]\naction.script = 1" ).to be_truthy
  end
end

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
    expect( artifact.source ).to eq('some text')
  end

  it 'requires a parser to parse' do
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

describe 'Migration Parsing' do

  before :all do
    class Migration::Foo < Migration::Parser
      class << self
        def parse(it)
          'pass'
        end

        def valid?(v)
          v == 'passme'
        end
      end
    end
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Parser' ).to be_truthy
  end

  it 'tracks its parsers' do
    expect( Migration::Parser.parsers.include? Migration::Foo ).to be_truthy
  end

  it 'selects a parser' do
    expect( Migration::Parser.parse 'passme' ).to eq( 'pass' )
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

  it 'performs validation' do
    notini = 'this is not an ini string'
    expect( Migration::StanzaParser.valid? notini ).to be_falsey
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

  it 'performs simple validation' do
    expect( Migration::YamlParser.valid? '/some/other/file.yml' ).to be_falsey
  end

  it 'is a parser' do
    expect( Migration::YamlParser.ancestors[1] ).to eq( Migration::Parser )
  end
end

describe 'Migration Conf Parsing' do

  before :all do
    @file = "#{ File.dirname __FILE__ }/data/sample.conf"
    @str = File.read "#{ File.dirname __FILE__ }/data/sample.conf"
  end

  it 'parses a config file to an array' do
    expect( Migration::ConfParser.parse( @file ).size ).to eq(3)
  end

  it 'contains the parsed content' do
    parsed = Migration::ConfParser.parse( @file )
    expect( parsed ).to include "[Test]\naction.script = 1"
    expect( parsed ).to include "[tstb]\naction.script.filename = pagerduty_index_alert"
    expect( parsed ).to include "[Test Cee]\naction.email.sendpdf = 1"
  end

  it 'can parse a string' do
    parsed = Migration::ConfParser.parse( @str )
    expect( parsed ).to include "[Test]\naction.script = 1"
    expect( parsed ).to include "[tstb]\naction.script.filename = pagerduty_index_alert"
    expect( parsed ).to include "[Test Cee]\naction.email.sendpdf = 1"
  end

  it 'performs simple validation' do
    expect( Migration::ConfParser.valid? '/some/file.conf').to be_falsey
  end

  it 'is a parser' do
    expect( Migration::ConfParser.ancestors[1] ).to eq( Migration::Parser )
  end
end

describe 'Migration File List Parsing' do

  before :all do
    @data = "./default/conf/data.conf\n./local/conf/web.conf\n/meta/conf/local.meta\n/meta/conf/default.meta"
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::ListParser' ).to be_truthy
  end

  it 'performs simple validation' do
    expect( Migration::ListParser.valid? 123 ).to be_falsey
  end

  it 'parses a file list to a nested hash' do
    expect( Migration::ListParser.parse( @data )['local'].key? 'conf' ).to be_truthy
  end

  it 'parses the elements to an array' do
    parsed = Migration::ListParser.parse( @data )
    expect( parsed[ 'default' ][ 'conf' ][ 'data.conf' ].class? Array ).to be_truthy
    expect( parsed[ 'local' ][ 'conf' ][ 'web.conf' ].class? Array ).to be_truthy
    expect( parsed[ 'meta' ][ 'conf' ][ 'local.meta' ].class? Array ).to be_truthy
    expect( parsed[ 'meta' ][ 'conf' ][ 'default.meta' ].class? Array ).to be_truthy
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

  it 'expects an existing key' do
    expect { @conn.call @host, @user, @key }.to raise_exception( Migration::MissingKeyfile )
  end

  it 'accepts an existing file' do
    expect( (@conn.call @host, @user, @file, @proto).class ).to eq( Migration::Server::Connection )
  end

  it 'executes remote commands' do
    expect( (@conn.call @host, @user, @file, @proto).exec 'll' ).to eq('/path/to/files...')
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

describe 'Migration Server' do

  before :each do
    @conf = { host: 'localhost', user: 'splunk' }
  end



end

describe 'Migration Options' do

  before :all do

    class OptTesting < Migration::Options

      @opts = OptionParser.new do |opts|
        opts.banner = 'Usage: opttesting -p STRING'
        opts.on '-p', '--print STRING', 'the string to print back' do |arg|
          @runtime[:string] = "the string to print back: #{ arg }"
        end
      end

      class << self
        attr_reader :runtime

        def parse(args)
          @runtime = {}
          @opts.parse args
          @runtime
        end
      end
    end
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Options' ).to be_truthy
  end

  it 'tracks its commands' do
    expect( Migration::Options.cmds.key? 'opttesting' ).to be_truthy
  end

  it 'holds a reference to its cmd objects' do
    expect( Migration::Options.cmds['opttesting'].allocate.class ).to eq( OptTesting )
  end

  it 'parses an args array' do
    expect( Migration::Options.parse(%w[opttesting -p foobar])[:string] ).to eq('the string to print back: foobar')
  end

  it 'provides help by default' do
    expect { Migration::Options.parse %w[notacmd] }.to output("Usage: migrate <CMD>\n").to_stdout
  end

  it 'provides help by default pt. 2' do
    expect { Migration::Options.parse [] }.to output("Usage: migrate <CMD>\n").to_stdout
  end

end
