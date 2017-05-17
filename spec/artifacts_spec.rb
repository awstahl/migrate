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
    if Object.const_defined? 'Migration::Artifacts::Artifact'
      class ArtSpec < Migration::Artifacts::Artifact; end
    end
    @source = 'a string of text'
  end

  after :all do
    if Object.const_defined? 'ArtSpec'
      Migration::Artifacts::Artifact.children.delete ArtSpec
    end
  end

  before :each do
    mocks
    @art = Migration::Artifacts::Artifact.new @source if Object.const_defined? 'Migration::Artifacts::Artifact'
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
    if Object.const_defined? 'Migration::Artifacts::Artifact'

      class ArtMock < Migration::Artifacts::Artifact
        class << self
          def valid?(mock)
            true if mock == 'codeword'
          end
        end
      end

    end
  end

  after :all do
    Migration::Artifacts::Artifact.children.delete ArtMock if Object.const_defined? 'Migration::Artifacts::Artifact'
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
    @content = Conf.new @conf if Object.const_defined? 'Migration::Artifacts::Conf'
  end

  it 'exists' do
    expect( @content ).to be_truthy
  end

  it 'accepts a source' do
    expect( @content.content ).to eq( @conf )
  end

  it 'is an artifact' do
    expect( Conf.ancestors[2] ).to eq( Migration::Artifacts::Artifact )
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

  it 'can print itself' do
    expect( @content.print ).to eq( File.open( @confpath, 'r' ).read )
  end

  it 'can find a stanza by name' do
    expect( @content.find( 'Test Cee' ).class ).to eq( Migration::Artifacts::Ini )
  end

  it 'can find a stanza by regex' do
    expect( @content.find( /stb$/ ).class ).to eq( Migration::Artifacts::Ini )
  end

  it 'returns nil for unmatched stanzas' do
    expect( @content.find /^nomatch$/  ).to eq( nil )
  end

  it 'can add a stanza' do
    stanza = "[louis the fourteenth]\nalpha = yes\nbeta = yes\nnerd = harder\nindex = true\n"
    @content.add stanza
    expect( @content.find( 'louis the fourteenth' ).name ).to eq( 'louis the fourteenth' )
  end

  it 'can push a stanza' do
    stanza = "[louis the fourteenth]\nalpha = yes\nbeta = yes\nnerd = harder\nindex = true\n"
    @content << stanza
    expect( @content.find( 'louis the fourteenth' ).name ).to eq( 'louis the fourteenth' )
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
    @ini = Migration::Artifacts::Ini.new @source if Object.const_defined? 'Migration::Artifacts::Ini'
  end

  it 'exists' do
    expect( @ini ).to be_truthy
  end

  it 'uses a default parser to parse' do
    expect( @ini.data[ 'key' ]).to eq( 'val' )
  end

  it 'can access data with arbitrary methods' do
    expect( @ini.key ).to eq( 'val' )
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
      content.gsub! /l$/, 'lue'
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
    @xml = Migration::Artifacts::Xml.new @source if Object.const_defined? 'Migration::Artifacts::Xml'
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