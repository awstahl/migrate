#
#  File: parsers.rb
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


=begin
class Parser < Migration::Parent
  # @parsers = @children
  @children = []

  class << self
    attr_reader :children

    def parse
      puts "wat the fuk:"
      puts"class children member: #{ @children }"
      puts "children is a: #{ @children.class }"
      puts "class children accessor: #{ children }"
    end
  end
end

class Foo < Parser

end

puts "Parser has hook? #{ Parser.respond_to? :inherited}"
Parser.parse
=end
