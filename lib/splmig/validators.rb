#
#  File: validators.rb
#  Author: alex@testcore.net
#
# Collection of utility methods to validate data

module Migration

  class Valid

    class << self

      def file?(file)
        File.exists? file and File.readable? file
      end

      def absolute_path?(path)
        path =~ /^\//
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
    end
  end


end