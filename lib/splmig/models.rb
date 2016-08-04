#
#  File: models.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models splunk config data.

require "#{ File.dirname __FILE__ }/sugar"
require "#{ File.dirname __FILE__ }/parsers"
require "#{ File.dirname __FILE__ }/options"

module Migration

  # An Artifact is a decorated hash
  class Artifact
    attr_accessor :parser, :source

    def initialize(source='', parser=Migration::Parser)
      @source = source
      @data = {}
      @parser = parser
      yield self if block_given?
    end

    def name
      @data[ :name ]
    end

    def [](key)
      @data[ key ]
    end

    def []=(key, value)
      @data[ key.to_sym ] = value
    end

    def keys
      @data.keys
    end

    def key?(key)
      @data.key? key
    end

    def parse
      @data = @parser.parse @source
    end

    def migrate
      yield @data if block_given?
    end

    def to_s
      "[#{ @data[ :name ] }]\n" + data_to_s + "\n"
    end

    def data_to_s
      out = ''
      @data.keys.sort.each do |key|
        out += "#{ key } = #{ @data[ key ]}\n" unless key == :name
      end
      out
    end
    private :data_to_s

  end

  class Application < Artifact

    def initialize(source = '', parser = nil)
      raise InvalidPath unless valid? source
      super source, parser
    end

    def list
      @data.to_paths @source
    end

    def valid?(path)
      Valid.absolute_path? path
    end
    private :valid?

  end

  class Server

    attr_accessor :conf
    Conf = Struct.new :file, :host, :key, :path, :user

    def initialize(conf=nil)
      @conf = Conf.new
      map_conf conf
      yield @conf if block_given?
    end

    def map_conf(conf)
      @conf.members.each do |member|
        # wat?
        eval "@conf.#{ member.to_s } = conf[ member ] if conf.key? member"
      end
    end
    private :map_conf

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
