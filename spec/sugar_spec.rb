#
#  File: models.rb
#  Author: alex@testcore.net
#
#  Tests for some sugar


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/sugar"


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

  it 'adds to_rex to Object' do
    expect( 'abc'.to_rex ).to eq( /abc/ )
  end

  it 'adds to_uri to strings' do
    expect( 'a b c :*'.to_uri ).to eq( 'a%20b%20c%20%3A%2A')
  end

  it 'adds to_plain to strings' do
    expect( 'a%20b%20c%20'.to_plain ).to eq( 'a b c ')
  end

  it 'adds a to_keys to strings to create nested hashes' do
    str = 'a b c'
    expect( str.to_keys ).to eq( 'a' => { 'b' => { 'c' => { }}})
  end

  it 'can convert to keys with a delimiter' do
    path = 'path/to/nowhere'
    expect( path.to_keys '/' ).to eq( 'path' => { 'to' => { 'nowhere' => { }}})
  end

  it 'returns a single-key hash for congruent strings' do
    str = 'string'
    expect( str.to_keys ).to eq( 'string' => { })
  end

  it 'ignores non-present delimiters' do
    str = 'string'
    expect( str.to_keys '.' ).to eq( 'string' => { })
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
            amit: 'changed',
            another: 'key'
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
            amit: 'dolor',
            another: 'key'
        },
        bar: 'none'
                          })
  end
end
