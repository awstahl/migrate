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

    class LogTest
      include Migration::Log

      def run
        with_logging do |log|
          log.puts 'a log entry'
        end
      end

      def verify
        with_logging do |log|
          log.respond_to? :puts
        end
      end
    end
  end

  after :all do
    File.delete @logfile if File.exists? @logfile
  end

  before :each do
    @log = LogTest.new
    Migration::Log.file = STDOUT
  end

  it 'adds a logging method' do
    expect( @log.respond_to? :with_logging ).to be_truthy
  end

  it 'can set a log file' do
    Migration::Log.file = File.open @logfile, 'w'
    LogTest.new.run
    Migration::Log.file.close
    expect( File.open( @logfile, 'r').read ).to eq( "a log entry\n" )
  end

  it 'can use the logger' do
    expect( LogTest.new.verify ).to be_truthy
  end

end