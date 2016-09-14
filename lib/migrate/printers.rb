#
#  File: printers.rb
#  Author: alex@testcore.net
#
# Classes to convert various data structures
# to printable strings.

require "#{ File.dirname __FILE__ }/validators"
require "#{ File.dirname __FILE__ }/parents"


module Migration

  # Parent class to handle selecting a printer
  # based on a filename.
  class Print < Parent

    @children = []
    class << self
      attr_reader :children

      # def print(file, content)
      def it(file, content)
        return nil unless file && content  # prevents nasty nil exceptions
        printer = find file
        printer ? printer.print( content ) : content
      end
    end
  end


  # Is not really a printer...
  class IniPrint

    class << self

      def it(header, data)
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


  class ConfPrint < Print

    class << self

      def print(stanzas)
        Valid.array? stanzas do
          stanzas.join "\n"
        end
      end

      def valid?(conf)
        Valid.confname? conf
      end
    end
  end
end
