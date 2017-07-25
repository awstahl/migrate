#
#  File: server.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models server communication.

require "#{ File.dirname __FILE__ }/artifacts"


module Migration

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

    # TODO: Refactor this after Application/AppManager are working...
    def fetch(app, filter=nil)

      # OLD:
      # app.porter = @porter
      # app.configure filter
      # @apps[ app.name ] = app

      # Simplest new form:
      # app = Migration::AppManager.produce app, @porter

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
        paths = Parse.it @conn.exec( "find #{ path } -type f -iname \"*\"" )
        paths.map {|path| path.gsub! /^\.\//, '' }
      end

      def get(file)
        raise InvalidPath unless valid? file
        @conn.exec "cat #{ file }"
      end

    end
  end
end
