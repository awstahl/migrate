#
#  File: artifacts.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models config data.

require "#{ File.dirname __FILE__ }/applications"
require "#{ File.dirname __FILE__ }/exceptions"
require "#{ File.dirname __FILE__ }/logger"
require "#{ File.dirname __FILE__ }/parents"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/printers"
require "#{ File.dirname __FILE__ }/server"
require "#{ File.dirname __FILE__ }/sugar"
require "#{ File.dirname __FILE__ }/validators"


module Migration

  module Artifacts

    class << self
      def produce(content)
        art = Artifact.find content
        art ||= Artifact
        Log.puts "Creating #{ art } artifact"
        art.new content
      end
    end

    # An Artifact is a 'parsed data' container
    class Artifact
      extend Parent
      @children = []
      attr_reader :data, :content

      def initialize(content)
        @content = content
        parse
      end

      def parse(parse=Parse)
        @data = parse.it @content
      end

      def print(print=Print)
        print.it @data
      end

      def fix!(it)
        block_given? ? yield( @data ) : @data = it
      end

      def method_missing(key)
        @data.send key if @data.respond_to? key
      end
    end

    # Container for conf files w/ multiple stanzas
    class Conf < Artifact
      include Enumerable
      attr_reader :path, :content

      class << self
        def valid?(conf)
          Valid.conf? conf
        end
      end

      def parse
        super
        artifacts = []
        @data.each do |stanza|
          artifacts << Artifacts.produce( stanza )
        end
        @data = artifacts
      end

      def each
        @data.each do |stanza|
          yield stanza
        end
      end

      def find(filter=/.*/)
        @data.find {|ini| ini.name =~ filter.to_rex }
      end

      def add(stanza)
        art = ( stanza.kind_of?( Artifact ) ? stanza : Artifacts.produce( stanza ))
        @data << art if art
      end
      alias :<< :add

      def print
        Printers::ConfPrinter.print @data
      end
    end

    # An Ini (stanza, not file) is a specific type of artifact
    class Ini < Artifact
      attr_accessor :printer
      attr_reader :name

      class << self
        def valid?(ini)
          Valid.ini? ini
        end
      end

      def initialize(content)
        super
        @printer = Printers::Ini
      end

      def parse(parser=Parse)
        super
        @name = @data.delete @data.keys.find {|key| key =~ /name/ } if Hash === @data
      end

      def print
        @printer.print @name, @data
      end

      def has?(key)
        Hash === @data and @data.key? key
      end

      def fix!(key, content=nil, &block)
        return false unless has? key
        @data[ key ] = ( block_given? ? yield( @data[ key ]) : content )
        # block_given? ? yield( @data[ key ]) : @data[ key ] = content
      end

      def method_missing(key)
        @data[ key.to_s ]
      end
    end

    # XML file contents are another type of artifact
    class Xml < Artifact

      class << self
        def valid?(xml)
          Valid.xml? xml
        end
      end

      def initialize(xml)
        super xml
      end

      def has?(node)
        return nil unless @data.respond_to? :xpath
        array = @data.xpath "//#{ node }"
        array.size > 0 ? array : nil
      end

      def fix!(name, content=nil, &block)
        return false unless has? name

        @data.xpath( "//#{ name }").each do |node|
          node.content = ( block_given? ? yield( node.content ) : content )
        end
      end

      def method_missing(element)
        @data.xpath "//#{ element }"
      end
    end

  end
end

