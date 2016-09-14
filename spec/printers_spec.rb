#
#  File: printers_spec.rb
#  Author: alex@testcore.net
#
#  Tests for a set of Printers


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/printers.rb"


describe 'Migration Printing' do

  before :all do
    class Migration::FakePrinter < Migration::Print
      class << self
        def print(content)
          content
        end

        def valid?(it)
          it =~ /\.conf$/
        end
      end

    end
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Print' ).to be_truthy
  end

  it 'catches nil values' do
    expect( Migration::Print.it nil, nil ).to be_falsey
  end

  it 'tracks its printers' do
    expect( Migration::Print.children ).to include( Migration::FakePrinter )
  end

  it 'selects a printer based on file name' do
    expect( Migration::Print.it 'foo.conf', %w[ free as in beer ] ).to eq( "free\nas\nin\nbeer" )
  end

  it 'returns the content if no printer is found' do
    expect( Migration::Print.it 'file.bin', "\0\0\0\0\0" ).to eq( "\0\0\0\0\0" )
  end

end

describe 'Migration ini stanza printing' do

  it 'exists' do
    expect( Object.const_defined? 'Migration::IniPrinter' ).to be_truthy
  end

  it 'prints an ini stanza from a header string and hash' do
    expect( Migration::IniPrinter.print 'test ini stanza', enabled: true, zeta: 'maybe', queue: false ).to \
    eq( "[test ini stanza]\nenabled = true\nqueue = false\nzeta = maybe\n" )
  end

  it 'requires a valid hash' do
    expect( Migration::IniPrinter.print 3.14, 'not a hash' ).to eq( "[3.14]\n")
  end

end


describe 'Migration conf file printing' do

  it 'exists' do
    expect( Object.const_defined? 'Migration::ConfPrinter' ).to be_truthy
  end

  it 'prints a conf file' do
    expect( Migration::ConfPrinter.print [ "stanza\n", "block\n", "line\n" ]).to eq( "stanza\n\nblock\n\nline\n" )
  end

  it 'requires an array to print' do
    expect( Migration::ConfPrinter.print 'not an array' ).to be_falsey
  end

  it 'validates conf file name' do
    expect( Migration::ConfPrinter.valid? 'file.conf').to be_truthy
  end

  it 'is a printer' do
    expect( Migration::ConfPrinter.ancestors[ 1 ]).to eq( Migration::Print )
  end

end