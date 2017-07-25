#
#  File: printers.rb
#  Author: alex@testcore.net
#
# Classes to convert various data structures
# to printable strings.

require_relative "logger"
require_relative "parents"
require_relative "validators"


module Migration

  # Parent class to handle selecting a printer
  # based on a filename.
  class Print
    extend Parent

    @children = []
    class << self
      attr_reader :children

      def it(content, file=nil)
        return nil unless content
        printer = find file if file
        printer ||= Printers::Default
        Migration::Log.puts "Selected a printer: #{ printer }"
        printer.print content
      end
    end
  end

  module Printers

    # Child classes under Print are data, and not file-type, based
    class Default
      class << self
        def print(it)
          it.to_s
        end
      end
    end

    # Print an Ini stanza from a header & hash
    class Ini
      class << self

        def print(header, data)
          out = "[#{ header }]\n"
          Valid.hash? data do
            data.keys.sort.each do |key|
              out += "#{ key } = #{ data[ key ]}\n"
            end
          end
          out
        end
      end
    end

    # Subclassed printers are for a specific filetype
    # and can implement a unique #valid? test
    class ConfPrinter < Print
      class << self

        def print(stanzas)
          Valid.array? stanzas do
            stanzas.map {|stanza| stanza.respond_to?( :print ) ? stanza.print : stanza }.join "\n"
          end
        end

        def valid?(conf)
          Valid.confname? conf or Valid.array? conf
        end
      end
    end
  end
end
