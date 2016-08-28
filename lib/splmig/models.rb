#
#  File: models.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models config data.

require "#{ File.dirname __FILE__ }/sugar"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/options"

module Migration

  # An Artifact is a 'parsed data' container
  class Artifact
    attr_reader :data, :name, :source

    def initialize(source)
      @source = source
      @data = nil
    end

    def parse(parser=Parser)
      @data = parser.parse @source
      @name = @data.delete :name
    end
  end

  # An application is an encapsulation of the
  # data within a given structured subdirectory
  class Application
    attr_reader :conf, :name, :paths, :root

    def initialize(conf)
      raise MissingPathRoot unless conf.key? :root
      @root = conf[ :root ]
      @name = Parser.parse( conf[ :root ]).last
      @paths = conf[ :paths ] || []
      parse @paths
    end

    def parse(paths)
      @conf = {}
      paths.each do |path|
        parse_path path
      end
    end
    private :parse

    def parse_path(path)
      @conf.deep_merge PathHashParser.parse( path )
    end
    private :parse_path

    def add_file(file)
      ( parse_path( file ) && @paths << file ) unless @paths.include? file
    end
    private :add_file

    def configure(file, content)
      keys = Parser.parse file
      add_file file
      pointer = @conf

      keys.each do |key|
        pointer = pointer[ key ] unless keys.last == key
      end

      pointer[ keys.last ] = [] unless Array === pointer
      pointer[ keys.last ] << content
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
        Parser.parse @conn.exec( "find #{ path } -type f -iname \"*\"" )
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
