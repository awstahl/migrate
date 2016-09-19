#
#  File: models.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models config data.

require "#{ File.dirname __FILE__ }/options"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/printers"
require "#{ File.dirname __FILE__ }/sugar"


module Migration

  # An Artifact is a 'parsed data' container
  class Artifact
    attr_accessor :printer
    attr_reader :data, :name, :source

    def initialize(source)
      @source = source
      @printer = IniPrinter
      parse
    end

    def parse(parse=Parse)
      @data = parse.it @source
      @name = @data.delete @data.keys.find {|key| key =~ /name/ } if Hash === @data
    end

    def print
      @printer.print @name, @data
    end
    alias :to_s :print

    def has?(key)
      Hash === @data and @data.key? key
    end

    def fix!(key, content=nil, &block)
      return false unless has? key
      data[ key ] = ( block_given? ? yield( data[ key ]) : content )
    end
  end

  # An application is an encapsulation of the
  # data within a given structured subdirectory
  class Application
    include Enumerable
    attr_accessor :porter, :printer
    attr_reader :conf, :name, :paths, :porter, :root

    def initialize(conf)
      raise MissingPathRoot unless conf.key? :root
      @root = conf[ :root ]
      @name = Parse.it( conf[ :root ]).last
      @porter = conf[ :porter ]
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

    def populate(file, container)
      key = file[ /[^\/]+$/ ]
      pointer = retrieve( file.gsub( key, '' ))
      pointer[ key ] = [] unless Array === pointer

      content = Parse.it( fetch_file file )
      content = [ content ] unless Valid.array? content
      content.each do |stanza|
        pointer[ key ] << container.new( stanza )
      end
    end
    private :populate

    def configure(file=nil, container=Artifact)
      refresh_paths

      if file
        populate file, container if @paths.include? file
      else
        @paths.each do |path|
          populate path, container
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

  # A Server is a remote host serving an application.
  # To communicate with the remote host, the Server has
  # a Connection.  To ferry data back from the remote
  # host, a Server uses a Porter.
  class Server
    attr_reader :apps
    attr_accessor :conf, :conn, :porter
    alias :connection :conn

    def initialize(conf={})
      @apps = {}
      @conf = conf
      @conn = Connection.new @conf[ :connection ]
      @porter = Porter.new @conn
    end

    def fetch(app)
      app.porter = @porter
      app.configure
      @apps[ app.name ] = app
    end

    # Opens the connection to the remote server using
    # an injected protocol class. Default to SSH.
    class Connection
      attr_reader :conf

      def initialize(conf)
        raise MissingKeyfile unless valid? conf[ :keyfile ]
        require 'net/ssh'
        @conf = conf
        @conf[ :proto ] ? connect( @conf[ :proto ]) : connect
      end

      def valid?(key)
        Valid.file? key
      end
      private :valid?

      def connect(proto=::Net::SSH)
        @remote = proto.start @conf[ :host ], @conf[ :user ], keys: [ @conf[ :keyfile ]]
      end
      private :connect

      def exec(cmd)
        @remote.exec! cmd
      end
    end

    # A Porter communicates with the remote server, using
    # an 'exec' method of a Connection type to send
    # wrapped cmd strings.
    class Porter

      def initialize(conn)
        raise InvalidConnection unless conn.respond_to? :exec
        @conn = conn
      end

      def valid?(path)
        Valid.absolute_path? path
      end
      private :valid?

      def list(path)
        raise InvalidPath unless valid? path
        Parse.it @conn.exec( "find #{ path } -type f -iname \"*\"" )
      end

      def get(file)
        raise InvalidPath unless valid? file
        @conn.exec "cat #{ file }"
      end

    end
  end

  class InvalidConnection < Exception; end
  class InvalidPath < Exception; end
  class MissingConnection < Exception; end
  class MissingKeyfile < Exception; end
  class MissingPathRoot < Exception; end
end
