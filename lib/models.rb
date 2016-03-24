#
#  File: models.rb
#  Author: alex@testcore.net
#
#  This is a set of classes that models splunk config data.


# But first, some sugar...
class Object
  def class?(klass)
    self.class == klass
  end
end

class Hash

  def to_paths(prefix=nil, stack=[])
    out=''

    self.each do |k,v|
      stack << k

      if v.class? Hash
        out += v.to_paths prefix, stack
      else
        out += ( prefix ? prefix + '/' : '' ) + stack.join('/') + "\n"
      end

      stack.pop
    end
    out
  end
end

class String
  def to_uri
    require 'uri'
    URI.encode self
  end

  def to_plain
    require 'uri'
    URI.decode self
  end
end

module Migration

  # Collection of utility methods to validate data
  class Valid

    class << self

      def file?(file)
        File.exists? file and File.readable? file
      end

      def absolute_path?(path)
        path =~ /^\//
      end

      def ini?(ini)
        ini =~ /^\[.+\n.+=.+/m
      end

      def yaml?(yml)
        yml =~ /^-{3}\s/
      end

      def conf?(conf)
        conf =~ /\n\n/
      end

      def list?(list)
        list =~ /\n/ and list !~ /\n\n/
      end

    end

  end

  # Options are passed at runtime
  class Options
    require 'optparse'

    @cmds = {}
    @opts = ::OptionParser.new do |opts|
      opts.banner = 'Usage: migrate <CMD>'
    end

    class << self
      attr_reader :cmds

      # Call parse on the correct subparser
      def parse(args)
        cmd = args.shift
        ( valid? cmd ) ? ( @cmds[cmd].parse args ) : ( puts @opts.help )
      end

      # Do we have a command to use?
      def valid?(cmd=nil)
        cmd and @cmds.key? cmd
      end
      private :valid?

      def inherited(klass)
        @cmds[ klass.to_s.downcase ] = klass
      end
    end
  end

  # An Artifact is a decorated hash
  class Artifact
    attr_accessor :parser, :source

    def initialize(source='', parser=nil)
      @source = source
      @data = {}
      @parser = parser || Migration::Parser
      yield self if block_given?
    end

    def name
      @data[ :name ]
    end

    def [](key)
      @data[ key ]
    end

    def []=(key, value)
      @data[ key ] = value
    end

    def keys
      @data.keys
    end

    def parse
      @data = @parser.parse @source
    end

    def migrate
      yield @data if block_given?
    end

    def to_s
      "[#{ @data[ :name ] }]\n" + data_to_s
    end

    def data_to_s
      out = ''
      @data.each do |k,v|
        out += "#{ k } = #{ v }\n" unless k == :name
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

    def [](key)
      @data[key]
    end

    def list
      @data.to_paths @source
    end

    def valid?(path)
      Valid.absolute_path? path
    end
    private :valid?

  end

  # Master Parser class to track others...
  class Parser
    @parsers = []
    class << self
      attr_reader :parsers

      def inherited(klass)
        Parser.parsers << klass
      end

      def parse(it)
        klass = Parser.parsers.find do |parser|
          parser.valid? it
        end
        klass ? klass.parse( it ) : raise( ParserNotFound )
      end
    end
  end

  # The StanzaParser converts an INI-formatted text stanza and extracts it into a hash
  # TODO: Rewrite this to use Ini gem... maybe.
  class StanzaParser < Parser
    MULTILINE = /\\$/

    class << self

      def parse(stanza)
        return nil unless valid? stanza
        @lines = stanza.split "\n"
        @results = {}
        name
        process
        @results
      end

      def valid?(stanza)
        # @lines = stanza.split "\n"
        # @lines.first =~ /^\[.+\]$/
        Valid.ini? stanza
      end

      def name
        @results[:name] = @lines.shift[/(?<=\[).+(?=\])/]
      end
      private :name

      def process
        multi = nil

        @lines.each do |line|
          if multi
            @results[ multi ] += "\n#{ line }"
            multi = nil unless line =~ MULTILINE
          else
            multi = extract line
          end
        end

      end
      private :process

      def extract(line)
        key = nil

        if line =~ /\s=\s{1}/
          data = line.split(/\s=\s/).map { |m| m.strip }
          key = data.first.to_sym
          @results[ key ] = data.last
        end

        (line =~ MULTILINE) ? key : nil
      end
      private :extract
    end
  end

  # The YamlParser loads a YAML string into its corresponding ruby data structure
  class YamlParser < Parser
    class << self

      def parse(yml)
        if valid? yml
          require 'yaml'
          YAML.load yml
        end
      end

      def valid?(yml)
        Valid.yaml? yml
      end
    end
  end

  # The FileParser loads a string from a file then parses it
  class FileParser < Parser
    class << self

      def parse(file)
        Migration::Parser.parse File.read( file ) if valid? file
      end

      def valid?(file)
        Valid.file? file
      end
    end
  end

  # The ConfParser parses a stanza-based file into its constituent stanzas as an array
  class ConfParser < Parser

    class << self
      def parse(conf)
        conf.split( "\n\n" ).map { |i| i.strip }
      end

      def valid?(conf)
        Valid.conf? conf
      end
    end
  end

  # The ListParser creates an array from a multiline string
  class ListParser < Parser

    class << self
      def parse(list)
        list.split if valid? list
      end

      def valid?(list)
        Valid.list? list
      end
    end

    # The PathParser creates a nested hash with directories as keys
    #   add path[ /[A-z0-9].+$/ ].split( '/' ), @out

    #   def add(path, out)
    #     latest = path.shift
    #
    #     if path.size == 0
    #       out[ latest ] = []
    #     else
    #       out[ latest ] = {} unless out.key? latest
    #       add path, out[ latest ]
    #     end
    #     out
    #
    #   end
    #   private :add


  end

  class Server
    # TODO: Get config data from injected Configuration hash

    # Opens the connection to the remote server using injected proto
    class Connection

      def initialize(host, user, keyfile=nil, proto=nil)
        raise MissingKeyfile unless valid? keyfile
        require 'net/ssh'
        @keyfile = keyfile
        @host = host
        @user = user
        proto ? connect(proto) : connect
      end

      def valid?(key)
        Valid.file? key
      end
      private :valid?

      def connect(proto=::Net::SSH)
        @remote = proto.start @host, @user, keys: [ @keyfile ]
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
  class ParserNotFound < Exception; end
end
