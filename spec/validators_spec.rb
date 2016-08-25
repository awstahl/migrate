require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/validators"


describe 'Migration Validator' do

  it 'exists' do
    expect( Object.const_defined? 'Migration::Valid' ).to be_truthy
  end

  it 'validates a file' do
    expect( Migration::Valid.file? __FILE__ ).to be_truthy
  end

  it 'rejects a non-existent file' do
    expect( Migration::Valid.file? '/path/to/nowhere' ).to be_falsey
  end

  it 'validates an absolute path' do
    expect( Migration::Valid.absolute_path? '/path/to/nowhere' ).to be_truthy
  end

  it 'rejects relative paths' do
    expect( Migration::Valid.absolute_path? 'some/other/path' ).to be_falsey
  end

  it 'validates a relative path' do
    expect( Migration::Valid.relative_path? 'bin/foo' ).to be_truthy
  end

  it 'must be a relative file path' do
    expect( Migration::Valid.relative_path? 'foobar/' ).to be_falsey
  end

  it 'validates an ini string' do
    expect( Migration::Valid.ini? "[Test]\naction.script = 1" ).to be_truthy
  end

  it 'rejects a non-ini string' do
    expect( Migration::Valid.ini? "Test\nfoo = bar" ).to be_falsey
  end

  it 'validates a yaml string' do
    expect( Migration::Valid.yaml? "---\n- a\n- b\n- c\n" ).to be_truthy
  end

  it 'rejects a non-yaml string' do
    expect( Migration::Valid.yaml? 'abc' ).to be_falsey
  end

  it 'validates a conf string' do
    expect( Migration::Valid.conf? "a\n\nb" ).to be_truthy
  end

  it 'rejects a non-conf string' do
    expect( Migration::Valid.conf? "a\nb" ).to be_falsey
  end

  it 'validates a list' do
    expect( Migration::Valid.list? "a\nb\nc" ).to be_truthy
  end

  it 'rejects a non-list' do
    expect( Migration::Valid.list? "abc" ).to be_falsey
  end

  it 'rejects a list with empty elements' do
    expect( Migration::Valid.list? "a\n\nb" ).to be_falsey
  end

  it 'validates a path array' do
    expect( Migration::Valid.path_array? %w[ bin/script.sh bin/doit.rb default/app.conf local/web.conf ]).to be_truthy
  end

  it 'detects an invalid path array' do
    expect( Migration::Valid.path_array? %w[ bin/script bin/ ]).to be_falsey
  end

  it 'detects an invalid array' do
    expect( Migration::Valid.path_array? 'string' ).to be_falsey
  end

end
