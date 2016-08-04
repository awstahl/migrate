require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/sugar"


describe 'Some Sugar' do

  it 'flattens hashes to paths' do
    hsh = { 'default' => { 'app.conf' => [] }, 'local' => { 'auth.conf' => [] }, 'meta' => { 'local.meta' => [] } }
    expect( hsh.to_paths ).to eq( "default/app.conf\nlocal/auth.conf\nmeta/local.meta\n" )
  end

  it 'accepts a prefix to hash paths' do
    hsh = { 'default' => { 'app.conf' => [] }, 'local' => { 'auth.conf' => [] }, 'meta' => { 'local.meta' => [] } }
    expect( hsh.to_paths '/path/to').to eq( "/path/to/default/app.conf\n/path/to/local/auth.conf\n/path/to/meta/local.meta\n" )
  end

  it 'adds to_uri to strings' do
    expect( 'a b c '.to_uri ).to eq( 'a%20b%20c%20')
  end

  it 'adds to_plain to strings' do
    expect( 'a%20b%20c%20'.to_plain ).to eq( 'a b c ')
  end

end
