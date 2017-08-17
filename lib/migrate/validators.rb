#
#  File: validators.rb
#  Author: alex@testcore.net
#
# Collection of utility methods to validate data

module Migration

  class Valid

    class << self

      def runner(klass, data, &block)
        klass === data && ( block_given? ? yield( data ) : true )
      end
      private :runner

      # Those that take blocks are helpers for the others...
      def string?(string, &block)
        string !~ /\0/ && runner( String, string, &block )
      end

      def array?(array, &block)
        runner Array, array, &block
      end

      def hash?(hash, &block)
        runner Hash, hash, &block
      end

      def file?(file)
        string? file do
          File.exists? file and File.readable? file and not File.directory? file
        end
      end

      def absolute_path?(path)
        path =~ /^\//
      end

      def relative_path?(path)
        string? path do
          path =~ /^[^\/]+\// && path.split( '/' ).size > 0
        end
      end

      def path?(path)
        absolute_path?( path ) || relative_path?( path )
      end

      def confname?(path)
        path =~ /\.conf$/
      end

      def ini?(ini)
        ini =~ /^\[.+\]\n/m and not conf? ini
      end

      def yaml?(yml)
        yml =~ /^-{3}\s/
      end

      def xml?(xml)
        xml =~ /^<.+?>.+<\/.+?>\s*$/m  # Nokogiri parsing should handle anything more complex
      end

      def conf?(conf)
        conf =~ /.+?\n\n/
      end

      def list?(list)
        list =~ /\n/ and
            not ini? list and
            not yaml? list and
            not xml? list and
            not conf? list
      end

      def path_array?(paths)
        array? paths do
          paths == paths.select {|path| Valid.relative_path? path }
        end
      end
    end
  end
end