#
#  File: models.rb
#  Author: alex.stahl@sephora.com
#
#  This is a set of classes that models splunk config data.
#  The purpose is to facilitate a clean migration from
#  legacy to the cluster.
#

# But first, some sugar...
class Object
  def class?(klass)
    self.class == klass
  end
end

class Hash

  # Recursively convert all hash keys to symbols
  def to_sym!
    keys.each do |key|
      keysym = key.to_sym
      self[ keysym ] = delete key unless key.class? Symbol
      self[ keysym ].to_sym! if self[ keysym ].class? Hash
    end
    self
  end
end

module Migration

  # An Artifact is a decorated hash
  class Artifact
    attr_accessor :parser, :source

    def initialize(source='', parser=nil)
      @source = source
      @data = {}
      @parser = parser
    end

    def name
      @data[:name]
    end

    def keys
      @data.keys
    end

    def parse
      raise MissingParser unless @parser
      @data = @parser.parse @source
    end

    def migrate
      yield @data if block_given?
    end

    def to_s
      "[#{ @data[:name] }]\n" + data_to_s + "\n"
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

  # The StanzaParser converts an INI-formatted text stanza and extracts it into a hash
  class StanzaParser
    MULTILINE = /\\$/

    class << self
      def parse(str='')
        validate str
        @results = {}
        name
        process
        @results
      end

      def validate(str)
        @lines = str.split "\n"
        raise InvalidIniString unless @lines.first =~ /^\[.+\]$/ and @lines.size > 1
      end

      def name
        @results[:name] = @lines.shift[/(?<=\[).+(?=\])/]
      end
      private :name

      def process
        multi = nil

        @lines.each do |line|
          if multi
            @results[multi] += "\n#{ line }"
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

  # The YamlParser loads a YAML file into its corresponding ruby data structure
  class YamlParser

    class << self
      def parse(it)
        require 'yaml'
        YAML.load pick(it)
      end

      def pick(it)
        if File.exist? it
          return File.open it, 'r'
        else
          return it
        end
      end
      private :pick
    end
  end

  # The ConfParser parses a stanza-based file into its constituent stanzas as an array
  class ConfParser
    class << self
      def parse(file)
        File.open(file, 'r').read.split "\n\n" if File.exist? file
      end
    end
  end

  class Server
    # Gets config data from Configuration hash - no, inject it
    # Holds a Files hash, with collections of Artifacts?
    # Need to manage file paths - paths as keys?
    # - search paths (config)
    # - found files
    # Need to find, fetch files
    # Need to output artifacts in new files
    # Use Artifactory to create artifact collections from files

    # Opens the connection to the remote server using injected proto
    class Connection
      attr_reader :remote

      def initialize(host, user, keyfile=nil, proto=nil)
        validate keyfile
        @host = host
        @user = user
        proto ? connect(proto) : connect
      end

      def validate(keyfile)
        raise MissingKeyfile unless File.exist? keyfile
        require 'net/ssh'
        @keyfile = keyfile
      end
      private :validate

      def connect(proto=::Net::SSH)
        @remote = proto.start @host, @user, keys: [ @keyfile ]
      end
      private :connect
    end

    # Container for file path & content data
    class Confset
      attr_reader :basepath

      def initialize(base)
        @basepath = base
      end
    end
  end

  class MissingParser < Exception
  end

  class InvalidIniString < Exception
  end

  class MissingKeyfile < Exception
  end
end
