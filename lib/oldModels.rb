#
#  File: models.rb
#  Author: alex.stahl@sephora.com
#
#  This is a set of classes that models splunk config data.
#  The purpose is to facilitate a clean migration from 
#  legacy to the cluster.
#
#  Entry point is the Artifacts factory class...

# NOTE: This is a working, but unfinished, piece of code.
# If you plan to use it, be aware of its shortcomings first.
# Alex Stahl; 1/4/16  "Not my finest piece of work."

=begin

In Order of Priority:

TODO: Refactor Artifact class
TODO: Refactor Artifact hierarchy to operate migrations via blocks
TODO: Refactor Artifacts class
TODO: Refactor Server class
TODO: Add logging class
TODO: Refactor to use logging
TODO: Finish Configuration class
TODO: Finish Options class

=end

# But first, some sugar...
class Object
  def class?(klass)
    self.class == klass
  end
end


module Migration

# Artifact - base class for a splunk config entry
# - Acts like a hash, but has specialty parsing methods
  class Artifact < Hash

    attr_accessor :name

    def initialize(name)

      puts "...creating a new artifact named #{ name }"
      clean = name.strip

      if clean =~ /^\[.+\]$/
        @name = clean.gsub /(\[|\])/, ''
      else
        raise "#{ clean } does not appear to be a valid artifact name! It's a #{ clean.class }"
      end

      @multi = false
    end

    def <<(line)
      multi_check line
      kv_check line
    end

    def kv_check(str)
      data = []

      if str =~ /\s=\s/
        data = str.split(' = ').map { |m| m.strip }
        self[data.first] = data.last
        @multi = data.first if data.last =~ /\\$/
      end

    end
    private :kv_check

    def multi_check(str)
      if @multi
        self[@multi] += ("\n" + str.strip)
        @multi = false unless str =~ /\\$/
      end
    end
    private :multi_check

    def to_s
      puts "...Printing out #@name"
      out = "[#@name]\n"
      out += params_to_s
      out
    end

    def params_to_s
      out = ''

      self.keys.sort.each do |k|
        out += "#{ k } = #{ self[k] }\n"
      end

      out += "\n"
      out
    end

    private :params_to_s

    def migrate

      puts "Migrating #@name"
      public_methods.each do |method|
        if method =~ /^migrate_/
          send method
        end
      end
    end

    alias :- :delete
    alias :list :keys
    alias :params :keys
  end


  class Search < Artifact
    def migrate_disable
      self['disabled'] = 1
    end

    def migrate_search
      puts "...Migrating searches"

      self['search'].gsub! /index=\*/, 'index=main' if self.key? 'search'

      if self['search'] !~ /index=/
        if self['search'] =~ /mpos/ or self['search'] =~ /sourcetype\s?=\s?\"?production/
          self['search'] = 'index=mpos ' + self['search']
        end
      end
    end

  end


  class Alert < Search

    def to_uri
      require 'uri'
      URI.encode @name
    end

    def migrate_vsid
      self.delete 'vsid'
    end

  end


  class Event < Search
  end


  class Meta < Artifact
    attr_reader :type

    def initialize(name)
      super name

      if @name =~ /\//
        @type, @name = @name.split '/'
      else
        raise "#@name does not appear to be a valid Meta artifact name!"
      end

    end

    def to_s
      "[#@type/#@name]\n#{ params_to_s }\n"
    end

    def migrate_access
      if @params.key? 'access'

        @@legacy_cluster_map.each do |legacy, cluster|
          @params['access'].gsub! /#{ legacy }/, cluster
        end

      end
    end
  end


  class Role < Artifact

    def initialize(name)
      super name
      @name = @name.split('role_').last
    end

    def to_s
      "[role_#@name]\n#{ params_to_s }\n"
    end
  end


  # TODO: Refactor this into appropriate parsing
  # and collection logic.  Is too burly....
  # A set of Artifacts is readily represented as a hash...
  # Break out parsing logic to simply return the hash instead.
  class Artifacts

    def initialize(data, type)

      raise "Source array is empty!" unless data.size > 0
      (type.allocate.kind_of? Artifact) ? @type = type : raise("#{ type } is not a valid type of artifact!")
      @artifacts = {}
      load data

    end

    private :initialize

    def load(data)

      artifact = nil
      data.each do |line|
        puts "...parsing source line data: #{ line }"

        if line =~ /^\[.+\]$/
          puts "...found a new artifact"
          artifact = @type.new line

        elsif line == "\n"
          puts "...found end of artifact, saving #{ artifact.name }"
          @artifacts[artifact.name] = artifact

        else
          puts "...adding line to artifact"
          artifact << line
        end
      end

      # Save the last one...
      @artifacts[artifact.name] = artifact
    end

    private :load

    def each(&block)
      @artifacts.each do |name, artifact|
        yield name, artifact
      end
    end

    def to_s(file=nil)

      out = (file ? File.new(file, 'w') : STDOUT)
      @artifacts.each do |name, artifact|
        puts "...Printing #{ name } with artifact name #{ artifact.name }"
        out.puts artifact.to_s
      end
      out.close

    end

    def migrate
      puts "...migrating artifacts"

      each do |name, artifact|

        if artifact.key? 'disabled' and artifact['disabled'] == "1" and name !~ /^BI:\sL/
          puts "Artifact #{ artifact.name } is disabled, deleting..."
          @artifacts.delete name
        else
          artifact.migrate
        end
      end
    end

    def keys
      @artifacts.keys
    end

    def key?(key)
      @artifacts.key? key
    end

    def [](file)
      @artifacts[file]
    end

    def merge(artifacts)
      artifacts.each do |name, artifact|
        @artifacts[name] = artifact unless @artifacts.key? name
      end
    end

    class << self
      def produce(src, type)
        puts "...Artifacts factory producing a #{ type } collection"

        # HBD - do NOT try to 'fix' this w/ a case statement
        if src.class? Array
          Artifacts.new src, type if src.size > 0

        elsif src.class? String and File.exist? src
          Artifacts.new File.open(src, 'r').readlines, type

        else
          raise "#{ src.class } is not a valid source!"
        end

      end
    end
  end


  # TODO: Refactor this to use parsing instead
  # of sets of Artifacts.  That was NOT DRY...
  # Artifacts hash maintains same content, but
  # retrieves from a parser factory.
  # Then refactor interface to be a little more usable.
  class Server
    attr_reader :host, :path, :artifacts

    def initialize(host, path)
      require 'net/ssh'
      @host = host
      @ssh = Net::SSH.start @host
      @path = path
      @artifacts = {}
      @merged = []
    end

    # Don't load a server... Fetch, List, etc...
    def load(conf, type)

      require 'uri/open-scp'
      puts "...finding files named #{ conf }"

      # NOTE: This requires that '.ssh/config' has the proper entries to connect to & read from the remote host
      flist = @ssh.exec!("find #@path -type f -name #{ conf } -path \"*local*\"").split.map! { |c| c[/(?<=#@path\/).+/] }

      puts "...found these files:"
      flist.each do |file|
        puts "...a found file: #{ file }"
      end

      flist.each do |file|
        puts "...fetching file #{ file } from #@host"
        lines = open("scp://root@#@host#@path/#{ file }").readlines
        @artifacts[file] = Artifacts.produce lines, type if lines.size > 0
      end
    end

    def migrate
      @artifacts.each do |file, artifacts|
        puts "...migrating file #{ file }"
        artifacts.migrate
      end
    end

    def merge(src)
      @artifacts.each do |file, artifacts|
        if src.key? file
          artifacts.merge src[file]
          @merged << file
        end
      end
    end

    def [](file)
      @artifacts[file]
    end

    def keys
      @artifacts.keys
    end

    def key?(key)
      @artifacts.key? key
    end

    def to_s(path, mode='s')

      if Dir.exist? path
        @artifacts.each do |file, artifacts|
          full = "#{ path }/#{ file }"

          if Dir.exist? File.dirname(path)
            dir = File.dirname full
            puts "Printing #{ full } to #{ dir }"
            mkdir dir if mode == 'c'
            artifacts.to_s full if Dir.exist? dir
          else
            puts "Skipping #{ full } as directory does not exist!"
          end

        end
      else
        puts "... #{ path } not found!"
      end
    end

    def mkdir(dir)
      unless Dir.exist? File.dirname dir
        mkdir File.dirname dir
      end
      Dir.mkdir dir unless Dir.exist? dir
    end

    private :mkdir
  end

  class Control
    @@path = '/opt/splunk/etc'
    @@fmap = {
        #'eventtypes.conf' => Event,
        'savedsearches.conf' => Alert
    }
    @@servermap = {

        'tdcvlog01' => @@fmap,
        #            'tewuvadspl02.tew' => @@fmap
        'tewuvapspl02' => @@fmap
    }
    @@servers = {}

    class << self

      def load
        @@servermap.each do |host, files|
          puts "Loading data for server #{ host }"
          @@servers[host] = Server.new(host, @@path)

          files.each do |file, type|
            puts "...loading file #{ file }"
            @@servers[host].load file, type
          end

        end
      end

      def migrate(host)
        puts "Migrating #{ host }"
        @@servers[host].migrate
      end

      def merge(src, dst)
        @@servers[dst].merge @@servers[src]
      end

      def generate(host, base, mode='s')
        puts "Generating for #{ host }"
        @@servers[host].to_s base, mode
      end

      def [](host)
        @@servers[host]
      end
    end

  end

  class << self
    @@dest = '/home/awstahl/Projects/sephora/repos/mudscripts/splunk-migrator/confs/gen/etc'

    def now
      Migration::Control.load
      Migration::Control.migrate 'tdcvlog01'
      #Migration::Control.merge 'tdcvlog01', 'tewuvapspl02'
      Migration::Control.merge 'tewuvapspl02', 'tdcvlog01'
      Migration::Control.generate 'tewuvapspl02', @@dest, 'c'
    end
  end

  class Configuration

    class << self
      attr_reader :config

      def load
        require 'yaml'
        @config = {}
        Dir.entries(File.dirname __FILE__).each do |conf|
          
        end
      end

    end

  end


  # OptionParser.new do |parser|
  #   parser.on("-c", "--conf CONFIG", "Specify an alternate config file") do |conf|
  #     puts "You required #{conf}!"
  #   end
  # end.parse!
  class Options
    require 'optparse'
    private :initialize

    class Command
      attr_accessor :name, :parser

      def initialize(name=nil, parser=nil)
        @name = name
        @parser = parser
        yield self if block_given?
      end

      def parse(args)
        begin
          @parser.parse! args
        rescue OptionParser::MissingArgument => e
          puts e
          puts @parser.help
        end
      end
      private :parse

      def execute(args)
        parse args
        # should probably have an actual cmd here...
      end
    end

    class << self
      COMMANDS = {

          'list' => Command.new('list') do |cmd|
            cmd.parser = OptionParser.new do |parser|
              #parser.on('-a')

              parser.on('-s', '--splunk HOST', '=MANDATORY', 'Specify a splunk host from which to list artifacts.') do |host|
                puts "Would connect to host #{ host }"
              end
            end
          end,

          'merge' => Command.new('merge') do |cmd|
            cmd.parser = OptionParser.new do |parser|
              parser.on('-d', '--dest HOST', 'Specify the destination splunk with which to merge artifacts.') do |dest|
                puts "Would merge to #{ dest }"
              end

              parser.on('-s', '--source HOST', 'Specify the source splunk from which to retrieve artifacts.') do |source|
                puts "Would retrieve from #{ source }"
              end

            end
          end,

          'migrate' => Command.new('migrate'),
          'deploy' => Command.new('deploy')
      }
      COMMANDS.each_value do |cmd|
        cmd.parser.banner = "migrate #{ cmd.name } [OPTIONS]" if cmd.parser
      end

      def commands
        COMMANDS
      end

      def bail(cmd)
        puts "Unknown command: #{ cmd }"
        puts "Usage: migrate <COMMAND> <OPTION>"
        puts "  Try: migrate <COMMAND> --help"
        exit 1
      end

      def parse(args)
        cmd = args.shift
        bail cmd unless commands.keys.include? cmd
        commands[cmd].execute args
      end
    end
  end
end
