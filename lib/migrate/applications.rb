#
#  File: applications.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models application containers & their creation.

require_relative "artifacts"
require_relative "exceptions"
require_relative "parsers"
require_relative "sugar"
require_relative "validators"


module Migration

  # An Application Manager handles populating an
  # Application using some form of 'porter' object.
  class AppManager

    class << self

      # Given an app root & a porter, build a
      # fully-populated Application object.
      def produce(path, porter)
        app = Application.new root: path, filelist: porter.list( path )
        app.files.each do |file|
          content = Migration::Artifacts.produce porter.get( "#{ path }/#{ file }" )
          app.contents file, content
        end
        app
      end
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
      dirs = Parse.it path

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
end
