#
#  File: validators.rb
#  Author: alex@testcore.net
#
# Tests of Collection of utility methods to validate data

require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/validators"

# Validator contains logic to determine if a
# thing appears to meet some characteristic
describe 'Migration Validator' do

  before :all do
    @pi = 3.14
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Valid' ).to be_truthy
  end


  # String tests

  it 'validates a string' do
    expect( Migration::Valid.string? 'C-beam of a reliable voyage, convert the collision course!' ).to be_truthy
  end

  it 'rejects a non-string nil value' do
    expect( Migration::Valid.string? nil ).to be_falsey
  end

  it 'rejects non-strings' do
    expect( Migration::Valid.string? @pi ).to be_falsey
  end

  it 'rejects null characters' do
    expect( Migration::Valid.string? "\0" ).to be_falsey
  end


  # Array tests

  it 'validates an array' do
    expect( Migration::Valid.array? %w[ a b c ]).to be_truthy
  end

  it 'rejects a non-array nil value' do
    expect( Migration::Valid::array? nil ).to be_falsey
  end

  it 'rejects a non-array value' do
    expect( Migration::Valid.array? @pi ).to be_falsey
  end


  # File tests

  it 'validates a file' do
    expect( Migration::Valid.file? __FILE__ ).to be_truthy
  end

  it 'rejects a non-existant file' do
    expect( Migration::Valid.file? '/path/to/nowhere' ).to be_falsey
  end

  it 'rejects an existant path' do
    expect( Migration::Valid.file? File.dirname( __FILE__ ) ).to be_falsey
  end

  it 'rejects non-path nil values' do
    expect( Migration::Valid.file? nil ).to be_falsey
  end

  it 'rejects non-string paths' do
    expect( Migration::Valid.file? @pi ).to be_falsey
  end


  # Absolute Path tests

  it 'validates an absolute path' do
    expect( Migration::Valid.absolute_path? '/path/to/nowhere' ).to be_truthy
  end

  it 'rejects relative paths' do
    expect( Migration::Valid.absolute_path? 'some/other/path' ).to be_falsey
  end

  it 'rejects non-absolute nil values' do
    expect( Migration::Valid.absolute_path? nil ).to be_falsey
  end

  it 'rejects non-string non-absolute paths' do
    expect( Migration::Valid.absolute_path? @pi ).to be_falsey
  end


  # Relative Path tests

  it 'validates a relative path' do
    expect( Migration::Valid.relative_path? 'bin/foo' ).to be_truthy
  end

  it 'can be a relative path' do
    expect( Migration::Valid.relative_path? 'foobar/' ).to be_truthy
  end

  it 'rejects non-relative nil values' do
    expect( Migration::Valid.relative_path? nil ).to be_falsey
  end

  it 'rejects non-string non-relative paths' do
    expect( Migration::Valid.relative_path? @pi ).to be_falsey
  end


  # Generic Path tests

  it 'validates an arbitrary relative path' do
    expect( Migration::Valid.path? 'bin/foo' ).to be_truthy
  end

  it 'validates an arbitrary absolute path' do
    expect( Migration::Valid.path? '/bin/foo' ).to be_truthy
  end


  # Ini tests

  it 'validates an ini string' do
    expect( Migration::Valid.ini? "[Test]\naction.script = 1" ).to be_truthy
  end

  it 'rejects a non-ini string' do
    expect( Migration::Valid.ini? "Test\nfoo = bar" ).to be_falsey
  end

  it 'rejects non-ini nil values' do
    expect( Migration::Valid.ini? nil ).to be_falsey
  end

  it 'rejects non-string non-ini stanzas' do
    expect( Migration::Valid.ini? @pi ).to be_falsey
  end


  # YAML tests

  it 'validates a yaml string' do
    expect( Migration::Valid.yaml? "---\n- a\n- b\n- c\n" ).to be_truthy
  end

  it 'rejects a non-yaml string' do
    expect( Migration::Valid.yaml? 'abc' ).to be_falsey
  end

  it 'rejects non-yaml nil values' do
    expect( Migration::Valid.yaml? nil ).to be_falsey
  end

  it 'rejects non-string non-yaml paths' do
    expect( Migration::Valid.yaml? @pi ).to be_falsey
  end


  # Conf text tests

  it 'validates a conf string' do
    expect( Migration::Valid.conf? "a\n\nb" ).to be_truthy
  end

  it 'rejects a non-conf string' do
    expect( Migration::Valid.conf? "a\nb" ).to be_falsey
  end

  it 'rejects non-conf nil values' do
    expect( Migration::Valid.conf? nil ).to be_falsey
  end

  it 'rejects non-string non-conf paths' do
    expect( Migration::Valid.conf? @pi ).to be_falsey
  end


  # List tests

  it 'validates a list' do
    expect( Migration::Valid.list? "a\nb\nc" ).to be_truthy
  end

  it 'rejects a non-list' do
    expect( Migration::Valid.list? 'abc').to be_falsey
  end

  it 'rejects a list with empty elements' do
    expect( Migration::Valid.list? "a\n\nb" ).to be_falsey
  end

  it 'rejects non-list nil values' do
    expect( Migration::Valid.list? nil ).to be_falsey
  end

  it 'rejects non-string non-list paths' do
    expect( Migration::Valid.list? @pi ).to be_falsey
  end


  # Path Array tests

  it 'validates a path array' do
    expect( Migration::Valid.path_array? %w[ bin/script.sh bin/doit.rb default/app.conf local/web.conf ]).to be_truthy
  end

  it 'detects an invalid path array' do
    expect( Migration::Valid.path_array? %w[ bin/script bin/ 123 ]).to be_falsey
  end

  it 'detects an invalid array' do
    expect( Migration::Valid.path_array? 'string' ).to be_falsey
  end

  it 'detects another invalid array' do
    expect( Migration::Valid.path_array? @pi ).to be_falsey
  end

  it 'detects a non-array nil' do
    expect( Migration::Valid.path_array? nil ).to be_falsey
  end


  # Conf file name tests

  it 'validates a conf file name' do
    expect( Migration::Valid.confname? 'file.conf' ).to be_truthy
  end

  it 'rejects non-conf names' do
    expect( Migration::Valid.confname? 'file.xml' ).to be_falsey
    expect( Migration::Valid.confname? 'file.json' ).to be_falsey
  end

  it 'ignores the path segment' do
    expect( Migration::Valid.confname? '/path/to/file.conf' ).to be_truthy
  end

end
