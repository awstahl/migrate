#
#  File: applications_spec.rb
#  Author: alex@testcore.net
#
#  Tests for a set of classes that models config data.


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/applications.rb"


describe 'Migration Application' do

  before :all do
    @files = []
    @files << 'bin/deploy.rb'
    @files << 'bin/script.rb'
    @files << 'default/app.conf'
    @files << 'default/data/models/model.xml'
    @files << 'default/data/ui/nav/bar.xml'
    @files << 'default/data/ui/views/main.xml'
    @files << 'local/inputs.conf'

    @stanza = "[artifact name]\nkey = val\n"
    @conffile = "#{ @stanza }\n[art Two]\nskel = lock"
  end

  before :each do
    @apppath = '/path/to/apps/rspec_test_app'
    @app = Migration::Application.new root: @apppath if Object.const_defined? 'Migration::Application'
  end

  it 'exists' do
    expect( @app ).to be_truthy
  end

  it 'starts with a root directory' do
    expect( @app.root ).to eq( '/path/to/apps/rspec_test_app' )
  end

  it 'expects a valid path for root' do
    expect{ Migration::Application.new root: 'foobar-is-not-a-path' }.to raise_exception( Migration::InvalidPath )
  end

  it 'extracts a name' do
    expect( @app.name ).to eq( 'rspec_test_app' )
  end

  it 'has a file list' do
    expect( Array === @app.files ).to be_truthy
  end

  it 'can set a file list' do
    app = Migration::Application.new root: @apppath, filelist: @files
    expect( app.files ).to eq( @files )
  end

  it 'rejects invalid path list items' do
    @app.files = %w[ /path/to/a /path/to/b notapath]
    expect( @app.files ).to eq( %w[ /path/to/a /path/to/b ])
  end

  it 'exposes files as a hash' do
    @app.files = @files
    expect( @app[ 'local' ].key? 'inputs.conf' ).to be_truthy
  end

  it 'can add a file' do
    @app << 'local/new.file'
    expect( @app[ 'local' ].key? 'new.file' ).to be_truthy
  end

  it 'requires a valid path to add' do
    @app << 'opt'
    expect( @app[ 'opt' ]).to be_falsey
  end

  it 'adds new files to its list' do
    @app.files = @files
    @app << 'local/new.file'
    expect( @app.files ).to include( 'local/new.file' )
  end

  it 'plays nice with existing files' do
    @app.files = @files
    @app << 'default/data/another/file.new'
    expect( @app[ 'default' ][ 'data' ].keys ).to eq( %w[ models ui another ])
  end

  it 'should store file contents' do
    @app.files = @files
    @app[ 'local' ][ 'inputs.conf' ] = @conffile
    expect( @app[ 'local' ][ 'inputs.conf' ]).to eq( @conffile )
  end

  it 'returns a pointer to file contents' do
    @app.files = @files
    @app[ 'local' ][ 'inputs.conf' ] = @conffile
    file = @app.file 'local/inputs.conf'
    file.gsub! /artifact/, 'your'
    expect( @app[ 'local' ][ 'inputs.conf' ]).to eq( "[your name]\nkey = val\n\n[art Two]\nskel = lock" )
  end

  it 'really does return a pointer to file contents' do
    @app.files = @files
    @app[ 'local' ][ 'inputs.conf' ] = %w[ a b c ]
    file = @app.file 'local/inputs.conf'
    file << 'd'
    expect( @app[ 'local' ][ 'inputs.conf' ]).to eq( %w[ a b c d ] )
  end

  it 'can retrieve file contents by relative path' do
    @app.files = @files
    @app[ 'local' ][ 'inputs.conf' ] = @conffile
    expect( @app.file 'local/inputs.conf' ).to eq( @conffile )
  end

  it 'can retrieve file contents by absolute path' do
    @app.files = @files
    path = "#@apppath/local/inputs.conf"
    @app[ 'local' ][ 'inputs.conf' ] = @conffile
    expect( @app.file path ).to eq( @conffile )
  end

  it 'can add & set contents via path' do
    path = 'local/inputs,conf'
    @app.contents path, @conffile
    expect( @app.file path ).to eq( @conffile )
  end

end


describe 'Migration Appliction Manager' do

  before :each do

  end

  it '' do

  end

end