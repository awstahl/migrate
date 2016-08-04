#
#  File: options.rb
#  Author: alex@testcore.net
#
# Base class to manage CLI options
# Sub-classes should go in their own file
# named after the command it implements.

require 'optparse'

module Migration

  # Options are passed at runtime
  class Options

    @cmds = {}
    @opts = ::OptionParser.new do |opts|
      opts.banner = 'Usage: splmig <CMD>'
    end

    class << self
      attr_reader :cmds

      # Call parse on the correct subparser
      def parse(args)
        cmd = args.shift
        ( valid? cmd ) ? ( @cmds[ cmd ].parse args ) : ( puts @opts.help )
      end

      # Do we have a command to use?
      def valid?(cmd=nil)
        cmd and @cmds.key? cmd
      end
      private :valid?

      # Subclass this class to create a new command
      def inherited(klass)
        @cmds[ klass.to_s.downcase ] = klass
      end
    end
  end

end