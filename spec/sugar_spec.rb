require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/sugar"


describe 'Some Sugar' do

  it 'adds to_uri to strings' do
    expect( 'a b c '.to_uri ).to eq( 'a%20b%20c%20')
  end

  it 'adds to_plain to strings' do
    expect( 'a%20b%20c%20'.to_plain ).to eq( 'a b c ')
  end

end
