require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/splmig/options"


describe 'Migration Options' do

  before :all do

    class OptTesting < Migration::Options

      @opts = OptionParser.new do |opts|
        opts.banner = 'Usage: opttesting -p STRING'
        opts.on '-p', '--print STRING', 'the string to print back' do |arg|
          @runtime[:string] = "the string to print back: #{ arg }"
        end
      end

      class << self
        attr_reader :runtime

        def parse(args)
          @runtime = {}
          @opts.parse args
          @runtime
        end
      end
    end
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Options' ).to be_truthy
  end

  it 'tracks its commands' do
    expect( Migration::Options.cmds.key? 'opttesting' ).to be_truthy
  end

  it 'holds a reference to its cmd objects' do
    expect( Migration::Options.cmds['opttesting'].allocate.class ).to eq( OptTesting )
  end

  it 'parses an args array' do
    expect( Migration::Options.parse(%w[opttesting -p foobar])[:string] ).to eq('the string to print back: foobar')
  end

  it 'provides help by default' do
    expect { Migration::Options.parse %w[notacmd] }.to output("Usage: splmig <CMD>\n").to_stdout
  end

  it 'provides help by default pt. 2' do
    expect { Migration::Options.parse [] }.to output("Usage: splmig <CMD>\n").to_stdout
  end

end
