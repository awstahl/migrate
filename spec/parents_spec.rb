require 'rspec'

describe 'Parents' do

  it 'should be a parent' do

    true.should == false
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
