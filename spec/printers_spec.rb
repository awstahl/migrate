require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/printers.rb"


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
    expect( Migration::ConfPrinter.print %w[ stanza block line ]).to eq( "stanza\n\nblock\n\nline" )
  end

  it 'requires an array to print' do
    expect( Migration::ConfPrinter.print 'not an array' ).to be_falsey
  end

end