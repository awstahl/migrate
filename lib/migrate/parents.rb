#
#  File: parents.rb
#  Author: alex@testcore.net
#
# Reusable Parent hook class for
# classes which have children.


module Migration

  class Parent

    # OBS: this is not inherited, yet can be
    # accessed by subclasses in #inherited
    @children = []
    class << self
      attr_reader :children

      def inherited(klass)
        @children << klass
      end

      def find(it)
        @children.find do |child|
          child.valid? it
        end
      end
    end
  end
end