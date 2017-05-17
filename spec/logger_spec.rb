#
#  File: logger_spec.rb
#  Author: alex@testcore.net
#
# Tests for Logger method to centralize output


require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/logger"


describe 'Migration Logger' do

  before :all do
    @logfile = './spec/data/tst.log'

    if Object.const_defined? 'Migration::Log'

      class LogTest
        include Migration::Log

        def run
          with_logging do |log|
            log.puts 'a log entry'
          end
        end

        def entry
          with_logging 'passed log entry' do |log|
            log.puts 'hi from entry'
          end
        end

        def verify
          with_logging do |log|
            log.respond_to? :puts
          end
        end
      end
    end

    @dmtch = /[0-9]{4}(-[0-9]{2}){2}\s([0-9]{2}:?){3}\s-[0-9]{4}/
  end

  after :all do
    File.delete @logfile if File.exists? @logfile
  end

  before :each do
    @log = LogTest.new if Object.const_defined? 'LogTest'
    File.delete @logfile if File.exists? @logfile
    Migration::Log.file = STDOUT if Object.const_defined? 'Migration::Log'
  end

  it 'exists' do
    expect( @log ).to be_truthy
  end

  it 'adds a logging method' do
    expect( @log.respond_to? :with_logging ).to be_truthy
  end

  it 'can use the logger' do
    expect( LogTest.new.verify ).to be_truthy
  end

  it 'can set a log file' do
    Migration::Log.file = File.open @logfile, 'w'
    LogTest.new.run
    Migration::Log.file.close
    expect( File.open( @logfile, 'r').read ).to match( 'a log entry' )
  end

  it 'adds a timestamp' do
    Migration::Log.file = File.open @logfile, 'w'
    LogTest.new.run
    Migration::Log.file.close
    expect( File.open( @logfile, 'r').read ).to match( @dmtch )
  end

  it 'accepts an optional event entry' do
    Migration::Log.file = File.open @logfile, 'w'
    LogTest.new.entry
    Migration::Log.file.close
    match = /#{ @dmtch }\spassed\slog\sentry\nhi\sfrom\sentry\n/i
    expect( File.open( @logfile, 'r').read ).to match( match )
  end

  it 'can log at the module level' do
    Migration::Log.file = File.open @logfile, 'w'
    Migration::Log.puts 'a new log entry'
    Migration::Log.file.close
    match = /#{ @dmtch }\sa\snew\slog\sentry\n/i
    expect( File.open( @logfile, 'r').read ).to match( match )
  end

end