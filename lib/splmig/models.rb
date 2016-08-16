#
#  File: models.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models splunk config data.

require "#{ File.dirname __FILE__ }/sugar"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/options"

module Migration

  # An Artifact is a parsed data container
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

  # An application is...
  class Application

    def initialize()
      @name = ''
      @files = {}
    end

  end

  class Server
    attr_accessor :conf, :conn, :porter

    def initialize(conf={})
      @conf = conf
      yield @conf if block_given?
      @conn = nil
      @porter = nil
    end

    # Opens the connection to the remote server using injected proto
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
    # an 'exec' method to send wrapped cmd strings.
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
        valid? path
        @conn.exec "find #{ path } -type f -iname \"*\""
      end

      def get(file)
        valid? file
        @conn.exec "cat #{ file }"
      end

    end
  end

  class InvalidConnection < Exception; end
  class InvalidPath < Exception; end
  class MissingKeyfile < Exception; end
end
