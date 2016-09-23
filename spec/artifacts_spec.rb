#
#  File: artifacts_spec.rb
#  Author: alex@testcore.net
#
#  Tests for a set of classes that models config data.

require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/artifacts.rb"


describe 'Migration Artifact' do

  def mocks
    @parser = double
    allow( @parser ).to receive( :it ).and_return( @source.split )

    @printer = double
    allow( @printer ).to receive( :it ).and_return( { str: 'a string of text' })
  end

  before :all do
    class ArtSpec < Migration::Artifacts::Artifact; end
    @source = 'a string of text'
  end

  after :all do
    Migration::Artifacts::Artifact.children.delete ArtSpec
  end

  before :each do
    mocks
    @art = Migration::Artifacts::Artifact.new @source
  end

  it 'exists' do
    expect( @art ).to be_truthy
  end

  it 'exposes the source string' do
    expect( @art.content ).to eq( @source )
  end

  it 'tracks its children' do
    expect( Migration::Artifacts::Artifact.children ).to include( ArtSpec )
  end

  it 'attempts to parse on instantiation' do
    expect( @art.data ).to eq( @source )
  end

  it 'can inject a parser' do
    @art.parse @parser
    expect( @art.data ).to eq( @source.split )
  end

  it 'provides a passthru interface to parsed data' do
    @art.parse @parser
    expect( @art.first ).to eq( @art.data.first )
    expect( @art.last ).to eq( @art.data.last )
    expect( @art.size ).to eq( @art.data.size )
  end

  it 'has a default printer' do
    expect( @art.print ).to eq( 'a string of text' )
  end

  it 'can inject a printer' do
    expect( @art.print @printer ).to eq( { str: 'a string of text' })
  end

end

describe 'Migration Artifacts module' do

  before :all do
    class ArtMock < Migration::Artifacts::Artifact
      class << self
        def valid?(mock)
          true if mock == 'codeword'
        end
      end
    end
  end

  after :all do
    Migration::Artifacts::Artifact.children.delete ArtMock
  end

  it 'can produce an Artifact' do
    expect( Migration::Artifacts.produce( 'codeword' ).class ).to eq( ArtMock )
  end

  it 'can produce a generic Artifact' do
    expect( Migration::Artifacts.produce( 3.14 ).data ).to eq( 3.14 )
  end

end

describe 'Migration Conf' do

  before :all do
    Conf = Migration::Artifacts::Conf
    local = File.dirname __FILE__
    %w[ conf xml yml ].each do |ftype|
      eval "@#{ ftype }path = \"#{ local }/data/sample.#{ ftype }\""
      eval "@#{ ftype } = File.open( @#{ ftype }path, 'r' ).read"
    end
  end

  before :each do
    @content = Conf.new @conf
  end

  it 'exists' do
    expect( @content ).to be_truthy
  end

  it 'accepts a source' do
    expect( @content.content ).to eq( @conf )
  end

  it 'is an artifact' do
    expect( Conf.ancestors[2]).to eq( Migration::Artifacts::Artifact )
  end

  it 'validates a multi-stanza file' do
    expect( Conf.valid? @conf ).to be_truthy
  end

  it 'only validates multi-stanza confs' do
    expect( Conf.valid? @yml ).to be_falsey
    expect( Conf.valid? @xml ).to be_falsey
  end

  it 'parses to an array' do
    expect( @content.data.class ).to eq( Array )
  end

  it 'parses array contents to Artifacts' do
    expect( @content.data.first.is_a? Migration::Artifacts::Artifact ).to be_truthy
  end

  it 'offers an enumerator' do
    expect( @content.respond_to? :each ).to be_truthy
  end

  it 'is enumerable' do
    expect( @content.is_a? Enumerable ).to be_truthy
  end

  it 'enumerates its stanzas' do
    iter = false
    @content.each do |stanza|
      iter = true
      expect( Migration::Artifacts::Ini === stanza ).to be_truthy
    end
    expect( iter ).to be_truthy
  end

end

describe 'Migration Ini' do

  def mocks
    @parser = double
    allow( @parser ).to receive( :it ).and_return({ a: 1, b: 2, 'name' => 'mockd' })

    @print = double
    allow( @print ).to receive( :print ).with( any_args ).and_return 'Damn yer pirate, feed the ale.'
  end

  before :all do
    @source = "[artifact name]\nkey = val\n"
  end

  before :each do
    mocks
    @ini = Migration::Artifacts::Ini.new @source
  end

  it 'exists' do
    expect( @ini ).to be_truthy
  end

  it 'uses a default parser to parse' do
    expect( @ini.data[ 'key' ]).to eq( 'val' )
  end

  it 'parses the name from the source' do
    expect( @ini.name ).to eq( 'artifact name' )
  end

  it 'can inject a parser' do
    @ini.parse @parser
    expect( @ini.name ).to eq( 'mockd' )
  end

  it 'accepts a printer' do
    @ini.printer = @print
    expect( @ini.printer ).to eq( @print )
  end

  it 'uses the printer to print' do
    @ini.printer = @print
    expect( @ini.print ).to eq( 'Damn yer pirate, feed the ale.' )
  end

  it 'defaults to the ini printer' do
    expect( @ini.print ).to eq( "[artifact name]\nkey = val\n" )
  end

  it 'knows if it has some data' do
    expect( @ini.has? 'key' ).to be_truthy
  end

  it 'knows if it does not have some data' do
    expect( @ini.has? 'foo' ).to be_falsey
  end

  it 'knows it does not have data' do
    ini = Migration::Artifacts::Ini.new ''
    expect( ini.has? :it ).to be_falsey
  end

  it 'can fix some data' do
    @ini .fix! 'key', 'new val'
    expect( @ini.data[ 'key' ]).to eq( 'new val' )
  end

  it 'only fixes data it has' do
    expect( @ini.fix! 'notakey' ).to be_falsey
  end

  it 'can fix with a block' do
    @ini.fix! 'key' do |content|
      content.gsub! /^va/, 'Va'
      content.gsub /l$/, 'lue'
    end
    expect( @ini.data[ 'key' ]).to eq( 'Value' )
  end

  it 'is an Artifact' do
    expect( Migration::Artifacts::Ini.ancestors[1] ).to eq( Migration::Artifacts::Artifact )
  end

  it 'can validate an ini string' do
    expect( Migration::Artifacts::Ini.valid? @source ).to be_truthy
  end

end

describe 'Migration Xml' do

  before :all do
    @source = File.open( "#{ File.dirname __FILE__ }/data/sample.xml", 'r' ).read
  end

  before :each do
    @xml = Migration::Artifacts::Xml.new @source
  end

  it 'exists' do
    expect( @xml ).to be_truthy
  end

  it 'is an Artifact' do
    expect( Migration::Artifacts::Xml.ancestors[1]).to eq( Migration::Artifacts::Artifact )
  end

  it 'parses data to an xml doc' do
    expect( @xml.data.class ).to eq( Nokogiri::XML::Document )
  end

  it 'knows if it has some xml data' do
    expect( @xml.has? 'query' ).to be_truthy
  end

  it 'knows if it does not have some xml data' do
    expect( @xml.has? 'not.a.tag.at.all').to be_falsey
  end

  it 'knows it does not have data' do
    xml = Migration::Artifacts::Xml.new ''
    expect( xml.has? 'query' ).to be_falsey
  end

  it 'can fix xml data' do
    @xml.fix! 'query', 'lol all replaced'
    @xml.data.xpath( '//query' ).each do |query|
      expect( query.content ).to eq( 'lol all replaced' )
    end
  end

  it 'only fixes xml data it has' do
    expect( @xml.fix! 'notanode', 'does not matter').to be_falsey
  end

  it 'can fix xml with a block' do

    @xml.fix! 'query' do |query|
      query.gsub /index=mpos/, 'index=mpos*'
    end

    @xml.data.xpath( '//query' ).each do |query|
      expect( query.content ).to match( /index=mpos*/ )
    end
  end

  it 'can validate an xml string' do
    expect( Migration::Artifacts::Xml.valid? @source ).to be_truthy
  end

end

describe 'Migration Application' do

  def mocks
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
    @paths = []
    @paths << 'bin/deploy.rb'
    @paths << 'bin/script.rb'
    @paths << 'default/app.conf'
    @paths << 'default/data/models/model.xml'
    @paths << 'default/data/ui/nav/bar.xml'
    @paths << 'default/data/ui/views/main.xml'
    @paths << 'local/inputs.conf'
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

end
