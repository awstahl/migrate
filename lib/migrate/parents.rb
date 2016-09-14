#
#  File: parents.rb
#  Author: alex@testcore.net
#
# Reusable Parent hook class for
# classes which have children.


module Migration

  class Parent

    @children = []
    class << self
      attr_reader :children

      def inherited(klass)
        puts "had a kid! #{ klass }"
        @children << klass
      end
    end
  end
end
