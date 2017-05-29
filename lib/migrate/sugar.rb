#
#  File: sugar.rb
#  Author: alex@testcore.net
#
#  ADd some sugar onto the core classes.


class Object
  def to_rex
    ( Regexp === self ) ? self : /#{ self }/
  end
end

class String
  def to_uri
    require 'uri'
    URI.encode( self ).gsub( ':', '%3A' ).gsub( '*', '%2A' )
  end

  def to_plain
    require 'uri'
    URI.decode self
  end

  def to_keys(delim=/\s/)

    out = {}
    dirs = self.split delim
    count = dirs.size - 1
    pointer = out

    0.upto ( count ) do |i|
      key = dirs[ i ]
      pointer[ key ] = {} unless pointer.key? key
      pointer = pointer[ key ]
    end
    out
  end
end

class Hash

  # TODO: think this needs to go...
  def to_paths(prefix=nil, stack=[])
    out=''

    self.each do |k,v|
      stack << k

      if v.is_a? Hash and not v.empty?
        out += v.to_paths prefix, stack
      else
        out += ( prefix ? prefix : '' ) + stack.join( '/' ) + "\n"
      end

      stack.pop
    end
    out
  end

  def deep_merge(other)
    self.merge! other do | k, v1, v2|
      ( Hash === v1 && Hash === v2 ) ? v1.deep_merge( v2 ) : v1
    end
  end

end
