#
#  File: parents_spec.rb
#  Author: alex@testcore.net
#
# Generic parent class for any subclass which needs a
# hook to track its subclasses



require 'rspec'
require "#{ File.dirname __FILE__ }/../lib/migrate/parents"

describe 'Parents' do

  before :all do
    class Subpar < Migration::Parent
      @children = []
    end

    class Junior < Subpar
      @children = []
    end
  end

  it 'tracks its children' do
    expect( Migration::Parent.children ).to include( Subpar )
  end

  it 'inherits parent behavior' do
    expect( Subpar.children ).to include( Junior )
  end

end
