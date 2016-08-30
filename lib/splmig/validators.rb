#
#  File: validators.rb
#  Author: alex@testcore.net
#
# Collection of utility methods to validate data

module Migration

  class Valid

    class << self

      # Those that take blocks are helpers for the others...
      def string?(string, &block)
        String === string  && string !~ /\0/ && ( block_given? ? yield( string ) : true )
      end

      def array?(array, &block)
        Array === array && ( block_given? ? yield( array ) : true ) # Hrm... how to dry out?
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
          path =~ /\// && path.split( '/' ).size > 0
        end
      end

      def ini?(ini)
        ini =~ /^\[.+\]\n.+=.+/m and not conf? ini
      end

      def yaml?(yml)
        yml =~ /^-{3}\s/
      end

      def conf?(conf)
        conf =~ /.+\n\n/
      end

      def list?(list)
        list =~ /\n/ and not conf? list
      end

      def path_array?(paths)
        array? paths do
          paths == paths.select {|path| Valid.relative_path? path }
        end
      end
    end
  end
end