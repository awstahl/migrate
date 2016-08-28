require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/sugar"


describe 'Some Sugar' do

  before :each do
    @hash = {
        foo: {
            'bar.txt': 'contents',
            'baz.txt': 'contempt'
        },
        lorem: {
            ipsum: {
                'roman.conf': 'numerals',
                'greek.conf': 'philos'
            },
            amit: 'dolor'
        }
    }
  end

  it 'adds to_uri to strings' do
    expect( 'a b c :*'.to_uri ).to eq( 'a%20b%20c%20%3A%2A')
  end

  it 'adds to_plain to strings' do
    expect( 'a%20b%20c%20'.to_plain ).to eq( 'a b c ')
  end

  it 'adds a to_paths printer to nested hashes' do
    expect( @hash.to_paths ).to eq( "foo/bar.txt\nfoo/baz.txt\nlorem/ipsum/roman.conf\nlorem/ipsum/greek.conf\nlorem/amit\n" )
  end

  it 'can prepend a prefix when printing paths' do
    expect( @hash.to_paths '/opt/').to eq( "/opt/foo/bar.txt\n/opt/foo/baz.txt\n/opt/lorem/ipsum/roman.conf\n/opt/lorem/ipsum/greek.conf\n/opt/lorem/amit\n" )
  end

  it 'handles empty hashes' do
    h = {
        'opt' => {
            'foo' => {
                'bar' => {},
                'baz' => {}
            },
            'lorem' => {
                'ipsum' => {}
            },
            'file' =>{}
        }
    }
    expect( h.to_paths ).to eq( "opt/foo/bar\nopt/foo/baz\nopt/lorem/ipsum\nopt/file\n" )
  end

  it 'can deep merge nested hashes' do
    addme = {
        foo: {
            'file.me': 'a file',
            'data.txt': 'ones and zeroes'
        },
        bar: 'none',
        lorem: {
            amit: 'changed'
        }
    }
    @hash.deep_merge addme
    expect( @hash ).to eq({
        foo: {
            'bar.txt': 'contents',
            'baz.txt': 'contempt',
            'file.me': 'a file',
            'data.txt': 'ones and zeroes'
        },
        lorem: {
            ipsum: {
                'roman.conf': 'numerals',
                'greek.conf': 'philos'
            },
            amit: 'dolor'
        },
        bar: 'none'
                          })
end

end
