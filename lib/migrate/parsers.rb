#
#  File: parsers.rb
#  Author: alex@testcore.net
#
# Classes to parse various data formats
# into native ruby data structures

# noinspection RubyResolve
require_relative "validators"
require_relative "parents"
require_relative "logger"


module Migration

  # Master Parse class to track & find other parsers
  class Parse
    extend Parent
    @children = []

    class << self

      def it(content)
        return nil unless content  # Required to prevent calls to #valid? to fail awkwardly
        parser = find content
        Log.puts "Parsing with parser: #{ parser }"
        parser ? parser.parse( content ) : content
      end
    end
  end

  module Parsers

    # The StanzaParser converts an INI-formatted text stanza and extracts it into a hash
    class StanzaParser < Parse
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
            data = line.split( ' = ', 2 ).map { |m| m.strip }
            key = data.first
            @results[ key ] = data.last
          end

          ( line =~ MULTILINE ) ? key : nil
        end
        private :extract
      end
    end

    # The YamlParser loads a YAML string into its corresponding ruby data structure
    class YamlParser < Parse
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

    # The XmlParser creates a Nokogiri xml doc from the data
    class XmlParser < Parse
      class << self

        def parse(xml)
          if valid? xml
            require 'nokogiri'
            Nokogiri.parse xml
          end
        end

        def valid?(xml)
          Valid.xml? xml
        end
      end
    end

    # The FileParser loads a string from a file then parses it
    class FileParser < Parse
      class << self

        def parse(file)
          Parse.it File.read( file ) if valid? file
        end

        def valid?(file)
          Valid.file? file
        end
      end
    end

    # The ConfParser parses a stanza-based file into its constituent stanzas as an array
    class ConfParser < Parse

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
    class ListParser < Parse

      class << self
        def parse(list)
          list.split if valid? list
        end

        def valid?(list)
          Valid.list? list
        end
      end
    end

    class PathParser < Parse

      class << self
        def parse(path)
          return [] unless valid? path
          dirs = path.split '/'
          dirs.shift if dirs.first == ''
          dirs
        end

        def valid?(path)
          Valid.relative_path? path or Valid.absolute_path? path
        end
      end
    end

  end
end
