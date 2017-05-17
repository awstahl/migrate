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

    if Object.const_defined? 'Migration::Parent'

      class Subpar
        @children = []
        extend Migration::Parent
      end

      class Junior < Subpar
        @children = []
        class << self

          def valid?(it)
            it unless it == 'foobar'
          end

        end
      end
    end
  end

  it 'exists' do
    expect( Object.const_defined? 'Migration::Parent' ).to be_truthy
  end

  it 'has children' do
    expect( Migration::Parent.instance_methods ).to include( :children )
  end

  it 'tracks its children' do
    expect( Subpar.children ).to include( Junior )
  end

  it 'can find a child' do
    expect( Subpar.find 'it' ).to eq( Junior )
  end

  it 'returns nil for not found' do
    expect( Subpar.find 'foobar' ).to be_falsey
  end
end
