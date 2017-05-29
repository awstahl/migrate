#
#  File: applications.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models application containers & their creation.


require "#{ File.dirname __FILE__ }/exceptions"
#require "#{ File.dirname __FILE__ }/logger"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/sugar"
require "#{ File.dirname __FILE__ }/validators"


module Migration

  # TODO: An application should not parse itself...
  # - Move parsing logic to an AppBuilder class
  # - Application container should only house data & accessor logic - IN PROGRESS

  # An Application Manager handles populating an
  # Application using some form of 'porter' object.
  class AppManager

    class << self

    end

  end

  # An Application is a smart container for a set of files.
  # Assumes an app's files live under one root, and consist
  # of files located under nested subdirectories.
  class Application

    attr_reader :files, :root

    def initialize(root:, filelist:[])
      raise InvalidPath unless Valid.path? root
      @root = root
      @files = filelist
      configure
    end

    def name
      File.basename @root
    end

    def files=(list)
      @files = list.select {|path| Valid.path? path }
      configure
    end

    def file(path, content=nil)
      dirs = Parse.it( path.gsub /^#@root/, '' )

      if @files.include? path

        if content
          last = dirs.pop
          @conf.dig( *dirs )[ last ] = content
        else
          @conf.dig *dirs
        end

      elsif content
        self << path
        contents path, content
      end
    end
    alias :contents :file

    def configure
      @conf = {}
      @files.each do |path|
        merge path
      end
    end
    private :configure

    def <<(path)
      if Valid.path? path
        @files << path
        merge path
      end
    end

    def merge(path)
      @conf.deep_merge path.to_keys( '/' )
    end
    private :merge

    def [](key)
      @conf[ key ]
    end

  end

# Original Application class
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
