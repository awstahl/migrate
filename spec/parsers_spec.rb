#
#  File: parsers_spec.rb
#  Author: alex@testcore.net
#
# Test of Classes to parse various data formats
# into native ruby data structures

require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/parsers"


# TODO: Bring consistency to the testing


describe 'Migration Parsing' do

  before :all do
    class Migration::Foo < Migration::Parse
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
    expect( Object.const_defined? 'Migration::Parse' ).to be_truthy
  end

  it 'catches nil values' do
    expect( Migration::Parse.it nil ).to eq( nil )
  end

  it 'tracks its parsers' do
    expect( Migration::Parse.children ).to include(Migration::Foo )
  end

  it 'selects a parser' do
    expect( Migration::Parse.it 'passme' ).to eq('pass' )
  end

  it 'returns the original value if no parser was found' do
    expect( Migration::Parse.it 'no parsers for me' ).to eq('no parsers for me' )
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
    expect( Migration::StanzaParser.parse @ini ).to include( :name => 'artifact name', 'owner' => 'admin', 'search' => 'index=foobar' )
  end

  it 'parses multiline statements' do
    ini = "[artifact name]\nowner = admin\nsearch = index=foobar some | \\nsearch terms here"
    expect( Migration::StanzaParser.parse ini ).to eq( :name => 'artifact name', 'owner' => 'admin', 'search' => "index=foobar some | \\nsearch terms here" )
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
    expect( Migration::YamlParser.parse @str ).to include( 'migration' => %w(search eventtypes))
  end

  it 'ignores non-yaml strings' do
    expect( Migration::YamlParser.parse 'some nonsense%$#@' ).to eq( nil )
  end

  it 'is a Parse' do
    expect( Migration::YamlParser.ancestors[1] ).to eq( Migration::Parse )
  end
end

describe 'Migration XML Parsing' do

  before :all do
    @xml = "<open>\n  <head meta=true>content</head>\n  <para font=yes size=3.14>contents\nkey = val\nidx = 123\n  <\para>\n<\open>"
  end

  it 'parses xml documents' do
    expect( Migration::XmlParser.parse( @xml ).child.node_name ).to eq( 'open' )
  end

  it 'ignores non-xml strings' do
    expect( Migration::XmlParser.parse 'this is a sentence' ).to be_falsey
  end

  it 'is a Parse' do
    expect( Migration::XmlParser.ancestors[1] ).to eq( Migration::Parse )
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
    expect( Migration::ConfParser.ancestors[1] ).to eq( Migration::Parse )
  end
end

describe 'Migration File Parsing' do

  it 'parses conf file contents' do
    expect( Migration::FileParser.parse "#{ File.dirname( __FILE__ )}/data/sample.conf" ).to include( "[Test]\naction.script = 1" )
  end

  it 'parses yaml file contents' do
    expect( Migration::FileParser.parse( "#{ File.dirname( __FILE__ )}/data/sample.yml" ).keys ).to include( 'ssh' ).and include( 'migration' )
  end

  it 'performs file validation' do
    expect( Migration::FileParser.parse '/path/to/nowhere' ).to be_falsey
  end

end

describe 'Migration File List Parsing' do

  before :all do
    @data = "default/conf/data.conf\nlocal/conf/web.conf\nmeta/conf/local.meta\nmeta/conf/default.meta"
  end

  it 'parses a multiline string to an array' do
    %w[ default/conf/data.conf local/conf/web.conf meta/conf/local.meta meta/conf/default.meta ].each do |file|
      expect( Migration::ListParser.parse @data ).to include( file )
    end
  end

  it 'performs simple validation' do
    expect( Migration::ListParser.valid? 123 ).to be_falsey
  end

  it 'validates the list' do
    expect( Migration::ListParser.valid? "a\nb" ).to be_truthy
  end
end

describe 'Migration Path Parsing' do

  before :all do
    @path = '/path/to/nowhere'
  end

  it 'parses a path to an array' do
    expect( Migration::PathParser.parse @path ).to eq( %w[ path to nowhere ])
  end

  it 'validates the path' do
    expect( Migration::PathParser.valid? 'this is not a path' ).to be_falsey
  end

end

describe 'Migration Path Hash Parsing' do

  before :all do
    @path = '/path/to/nowhere'
  end

  it 'parses a path to a hash' do
    expect( Migration::PathHashParser.parse @path ).to eq({ 'path' => { 'to' => { 'nowhere' => {} }}})
  end

  it 'handlles single element paths' do
    expect( Migration::PathHashParser.parse 'bin/' ).to eq( 'bin' => {})
  end

  it 'cannot parse a plain string' do
    expect( Migration::PathHashParser.parse 'not a path' ).to eq({})
  end

  it 'can only parse a path' do
    expect( Migration::PathHashParser.parse 3.14 ).to eq({})
  end

end
