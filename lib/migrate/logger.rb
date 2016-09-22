#
#  File: logger.rb
#  Author: alex@testcore.net
#
# Logger method to centralize output

module Migration

  module Log

    class << self
      def file
        @log ||= STDOUT
      end

      def file=(log)
        @log = log if log.respond_to? :puts
      end

      def puts(event='')
        file.puts "#{ Time.now } #{ event }"
      end
    end

    def with_logging(event='')
      Log.puts event
      yield Log.file
    end
  end
end