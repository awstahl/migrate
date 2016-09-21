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
    end

    def with_logging
      yield Log.file
    end
  end
end