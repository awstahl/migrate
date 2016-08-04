#
#  File: parsers.rb
#  Author: alex@testcore.net
#
# Classes to parse various data formats
# into native ruby data structures

require "#{ File.dirname __FILE__ }/validators"

module Migration

  # Master Parser class to track others...
  class Parser
    @parsers = []
    class << self
      attr_reader :parsers

      def inherited(klass)
        Parser.parsers << klass
      end

      def parse(it)
        klass = Parser.parsers.find do |parser|
          parser.valid? it
        end
        klass ? klass.parse( it ) : raise( ParserNotFound )
      end
    end
  end

  # The StanzaParser converts an INI-formatted text stanza and extracts it into a hash
  # TODO: Rewrite this to use Ini gem... maybe.
  class StanzaParser < Parser
    MULTILINE = /\\$/

    class << self

      def parse(stanza)
        return nil unless valid? stanza
        @lines = stanza.split "\n"
        @results = {}
        name
        process
        @results
      end

      def valid?(stanza)
        Valid.ini? stanza
      end

      def name
        @results[ :name ] = @lines.shift[ /(?<=\[).+(?=\])/ ]
      end
      private :name

      def process
        multi = nil

        @lines.each do |line|
          if multi
            @results[ multi ] += "\n#{ line }"
            multi = nil unless line =~ MULTILINE
          else
            multi = extract line
          end
        end

      end
      private :process

      def extract(line)
        key = nil

        if line =~ /\s=\s{1}/
          data = line.split(/\s=\s/).map { |m| m.strip }
          key = data.first.to_sym
          @results[ key ] = data.last
        end

        (line =~ MULTILINE) ? key : nil
      end
      private :extract
    end
  end

  # The YamlParser loads a YAML string into its corresponding ruby data structure
  class YamlParser < Parser
    class << self

      def parse(yml)
        if valid? yml
          require 'yaml'
          YAML.load yml
        end
      end

      def valid?(yml)
        Valid.yaml? yml
      end
    end
  end

  # The FileParser loads a string from a file then parses it
  class FileParser < Parser
    class << self

      def parse(file)
        Migration::Parser.parse File.read( file ) if valid? file
      end

      def valid?(file)
        Valid.file? file
      end
    end
  end

  # The ConfParser parses a stanza-based file into its constituent stanzas as an array
  class ConfParser < Parser

    class << self
      def parse(conf)
        conf.split( "\n\n" ).map { |i| i.strip }
      end

      def valid?(conf)
        Valid.conf? conf
      end
    end
  end

  # The ListParser creates an array from a multiline string
  class ListParser < Parser

    class << self
      def parse(list)
        list.split if valid? list
      end

      def valid?(list)
        Valid.list? list
      end
    end

    # The PathParser creates a nested hash with directories as keys
    #   add path[ /[A-z0-9].+$/ ].split( '/' ), @out

    #   def add(path, out)
    #     latest = path.shift
    #
    #     if path.size == 0
    #       out[ latest ] = []
    #     else
    #       out[ latest ] = {} unless out.key? latest
    #       add path, out[ latest ]
    #     end
    #     out
    #
    #   end
    #   private :add


  end

  class ParserNotFound < Exception; end
end
