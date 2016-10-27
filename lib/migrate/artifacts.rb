#
#  File: artifacts.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models config data.

require "#{ File.dirname __FILE__ }/exceptions"
require "#{ File.dirname __FILE__ }/logger"
require "#{ File.dirname __FILE__ }/server"
require "#{ File.dirname __FILE__ }/sugar"
require "#{ File.dirname __FILE__ }/parents"
require "#{ File.dirname __FILE__ }/validators"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/printers"


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
        ConfPrinter.print @data
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
        @printer = Print::Ini
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


  # An application is an encapsulation of the
  # data within a given structured subdirectory
  class Application
    include Enumerable
    include Log
    attr_accessor :porter, :printer
    attr_reader :conf, :name, :paths, :porter, :root

    def initialize(root:, porter: nil)
      @root = root
      @name = Parse.it( root ).last
      @porter = porter
      @printer = Print
      reconfigure
    end

    def reconfigure
      @paths = ( @porter ? @porter.list( @root ) : [] )
      @conf = {}
      @paths.each do |path|
        configure_file path
      end
    end
    private :reconfigure

    def configure_file(path)
      @conf.deep_merge path_to_keys( path )
    end
    private :configure_file

    def fetch_file(file)
      @porter.get file if @porter
    end
    private :fetch_file

    def add_file(file, contents=nil)
      @paths << file unless @paths.include? file
      configure_file file
      populate file, contents
    end

    def add_stanza(file, contents)
      return nil unless @paths.include? file
      puts "fucking add_stanza adding to file: #{ file }"
      pointer = retrieve file

      puts "got a fucking pointer: #{ pointer }"

      if pointer.size > 0
        pointer << contents
      else
        pointer = Migration::Artifacts.produce contents
      end
    end

    def contents(ffilt=/.*/)
      files = @paths.select {|path| path =~ ffilt.to_rex }
      files.map do |file|
        content = retrieve file
        yield file, content if block_given?
        file
      end
    end

    def path_to_keys(path)
      PathHashParser.parse( path )
    end
    private :path_to_keys

    def populate(file, contents=nil)

      with_logging 'starting populate' do |log|
        key = File.basename file
        pointer = retrieve "#{ File.dirname file }/"

        log.puts "populating pointer: #{ pointer } using key: #{ key }"
        pointer[ key ] = [] unless Array === pointer[ key ]
        contents ||= fetch_file file
        artifact = Migration::Artifacts.produce( contents )

        artifact.is_a?( Enumerable ) ? pointer[ key ] = artifact : pointer[ key ] << artifact
        log.puts "populated: #{ pointer[ key ].last } which is a #{ pointer[ key ].last.class }"
      end
    end
    private :populate

    def configure(filter=/.+/)
      reconfigure
      with_logging "Configuring app with filter #{ filter }" do |log|
        self.each filter do |path|
          populate path
        end
      end
    end

    def retrieve(path)
      keys = Parse.it path
      pointer = @conf

      keys.each do |key|
        pointer = pointer[ key ]
      end
      pointer
    end

    def print(file=nil)
      if file
        @printer.it file, retrieve( file ) if Valid.path? file
      else
        out = {}
        @paths.each do |path|
          out[ path ] = @printer.it path, retrieve( path )
        end
        out
      end
    end

    def each(filter=/.+/)
      paths = @paths.select {|path| path =~ filter.to_rex }

      paths.each do |path|
        yield path, retrieve( path )
      end
    end
  end
end

