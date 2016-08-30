#
#  File: printers.rb
#  Author: alex@testcore.net
#
# Classes to convert various data structures
# to printable strings.

require "#{ File.dirname __FILE__ }/validators"

module Migration

  class IniPrinter

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


  class ConfPrinter

    class << self

      def print(stanzas)
        Valid.array? stanzas do
          stanzas.join "\n"
        end
      end

    end
  end
end
