#
#  File: applications.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models application containers & their creation.

require "#{ File.dirname __FILE__ }/logger"

module Migration

  # An application is an encapsulation of the
  # data within a given structured subdirectory

  # TODO: An application should not parse itself...
  # - Move parsing logic to an AppBuilder class
  # - Application container should only house data & accessor logic

  class AppBuilder

    class << self

    end

  end

  class Application
    # Model contains:
    # 1. application name
    # 2. root application path
    # 3. (relative) file list
    # 4. structured file data
  end

=begin
  class Application
    include Enumerable
    include Log
    attr_accessor :porter, :printer
    attr_reader :conf, :name, :paths, :root

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

    # TODO: find a cleaner way to do this...
    def add_stanza(file, contents)
      return nil unless @paths.include? file
      key = File.basename file
      pointer = retrieve File.dirname file

      if pointer[ key ].size > 0
        pointer[ key ] << contents
        puts "added stanza to existing array: #{ pointer[ key ]}"
      else
        pointer[ key ] = Migration::Artifacts.produce contents
        puts "added stanza to new array: #{ pointer[ key ]}"
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
=end
end
