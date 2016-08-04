require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/parsers"


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

  it 'raises an exception if a parser is not found' do
    expect { Migration::Parser.parse 'invalid' }.to raise_exception( 'Migration::ParserNotFound' )
  end

end

describe 'Migration Stanza Parsing' do

  before :all do
    @ini = "[artifact name]\nowner = admin\nsearch = index=foobar\n"
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::StanzaParser' ).to be_truthy
  end

  it 'expects an ini formatted string' do
    expect( Migration::StanzaParser.parse 'not an ini string' ).to be_falsey
  end

  it 'parses an ini string into a hash' do
    expect( Migration::StanzaParser.parse @ini ).to include( name: 'artifact name', owner: 'admin', search: 'index=foobar' )
  end

  it 'parses multiline statements' do
    ini = "[artifact name]\nowner = admin\nsearch = index=foobar some | \\nsearch terms here"
    expect( Migration::StanzaParser.parse ini ).to include( search: 'index=foobar some | \\nsearch terms here' )
  end

  it 'performs validation' do
    notini = 'this is not an ini string'
    expect( Migration::StanzaParser.valid? notini ).to be_falsey
  end
end

describe 'Migration Yaml Parsing' do

  before :all do
    @str = "---\nssh:\n  keyfile: \"/path/to/key\"\n  user: admin\nmigration:\n- search\n- eventtypes\n"
  end

  it 'parses a yaml string' do
    expect( Migration::YamlParser.parse @str ).to include( 'migration' => ['search', 'eventtypes' ] )
  end

  it 'is a parser' do
    expect( Migration::YamlParser.ancestors[1] ).to eq( Migration::Parser )
  end
end

describe 'Migration Conf Parsing' do

  before :all do
    @str = File.read "#{ File.dirname __FILE__ }/data/sample.conf"
  end

  it 'parses a string' do
    parsed = Migration::ConfParser.parse( @str )
    expect( parsed ).to include "[Test]\naction.script = 1"
    expect( parsed ).to include "[tstb]\naction.script.filename = pagerduty_index_alert"
    expect( parsed ).to include "[Test Cee]\naction.email.sendpdf = 1"
  end

  it 'performs simple validation' do
    expect( Migration::ConfParser.valid? 'not a conf string' ).to be_falsey
  end

  it 'is a parser' do
    expect( Migration::ConfParser.ancestors[1] ).to eq( Migration::Parser )
  end
end

describe 'Migration File Parsing' do

  # TODO: Need to finish string-based parsing first...

end

describe 'Migration File List Parsing' do

  before :all do
    @data = "./default/conf/data.conf\n./local/conf/web.conf\n/meta/conf/local.meta\n/meta/conf/default.meta"
  end

  it 'parses a multiline string to an array' do
    expect( Migration::ListParser.parse @data ).to include( './default/conf/data.conf' )
    expect( Migration::ListParser.parse @data ).to include( './local/conf/web.conf' )
    expect( Migration::ListParser.parse @data ).to include( '/meta/conf/local.meta' )
    expect( Migration::ListParser.parse @data ).to include( '/meta/conf/default.meta' )
  end

  it 'performs simple validation' do
    expect( Migration::ListParser.valid? 123 ).to be_falsey
  end

  it 'validates the list' do
    expect( Migration::ListParser.valid? "a\nb" ).to be_truthy
  end
end

# describe 'Migration Path Parsing' do
#   it 'parses a file list to a nested hash' do
#     expect( Migration::ListParser.parse( @data )['local'].key? 'conf' ).to be_truthy
#   end
#
#   it 'parses the elements to an array' do
#     parsed = Migration::ListParser.parse( @data )
#     expect( parsed[ 'default' ][ 'conf' ][ 'data.conf' ].class? Array ).to be_truthy
#     expect( parsed[ 'local' ][ 'conf' ][ 'web.conf' ].class? Array ).to be_truthy
#     expect( parsed[ 'meta' ][ 'conf' ][ 'local.meta' ].class? Array ).to be_truthy
#     expect( parsed[ 'meta' ][ 'conf' ][ 'default.meta' ].class? Array ).to be_truthy
#   end
#
# end
