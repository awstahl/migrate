#
#  File: artifacts.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models config data.

require "#{ File.dirname __FILE__ }/exceptions"
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

      def method_missing(key)
        @data.send key
      end
    end

    # Container for conf files w/ multiple stanzas
    class Conf < Artifact
      attr_reader :path, :content

      class << self
        def valid?(conf)
          Valid.conf? conf
        end
      end

      def initialize(path:, content:)
        raise InvalidPath unless Valid.absolute_path? path
        @path = path
        super content
      end

      def parse
        super
        artifacts = []
        @data.each do |stanza|
          artifacts << Artifacts.produce( stanza )
        end
        @data = artifacts
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
        data[ key ] = ( block_given? ? yield( data[ key ]) : content )
      end
    end

    # XML file contents are another type of artifact
    class Xml < Artifact

      class << self
        def valid?(xml)
          Valid.xml? xml
        end
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
    end

  end


  # An application is an encapsulation of the
  # data within a given structured subdirectory
  class Application
    include Enumerable
    attr_accessor :porter, :printer
    attr_reader :conf, :name, :paths, :porter, :root

    def initialize(root:, porter: nil)
      @root = root
      @name = Parse.it( root ).last
      @porter = porter
      @printer = Print
      refresh_paths
      parse @paths
    end

    def parse(paths)
      @conf = {}
      paths.each do |path|
        @conf.deep_merge parse_file( path )
      end
    end
    private :parse

    def refresh_paths
      @paths = ( @porter ? @porter.list( @root ) : [] )
      parse @paths
    end
    private :refresh_paths

    def add_file(file)
      ( parse_file( file ) && @paths << file ) unless @paths.include? file
    end
    private :add_file

    def fetch_file(file)
      puts "Fetching file: #{ file }"
      @porter.get file if @porter
    end
    private :fetch_file

    def parse_file(path)
      PathHashParser.parse( path )
    end
    private :parse_file


    # TODO: Migrate this to a file class... IN PROGRESS
    def populate(file)
      key = File.basename file
      pointer = retrieve File.dirname file
      pointer[ key ] = [] unless Array === pointer[ key ]
      pointer[ key ] << Migration::Artifacts.produce( fetch_file file )

      # content = Parse.it( fetch_file file )
      # # TODO: does it need to force an array?  NO!
      # content = [ content ] unless Valid.array? content
      # content.each do |stanza|
      #   pointer[ key ] << container.produce( stanza )
      # end
    end
    private :populate

=begin
    def configure(file=nil, container=Migration::Artifacts)
      refresh_paths

      if file
        if Regexp === file
          @paths.select {|path| path =~ file }.each do |path|
            populate path, container
          end
        elsif @paths.include? file
          populate file, container
        end
      else
        @paths.each do |path|
          populate path, container
        end
      end
    end
=end

    def configure()
      @paths.each do |path|
        puts "App configuring path: #{ path }"
        populate path
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

    def each(filter=nil)
      paths = nil
      if filter
        paths = @paths.select {|path| path =~ filter}
      else
        paths = @paths
      end

      paths.each do |path|
        yield path, retrieve( path )
      end
    end
  end
end

