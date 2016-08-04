#
#  File: sugar.rb
#  Author: alex@testcore.net
#
#  This is some sugar added onto the core classes.

# TODO: Don't think this does what you think it does...
class Hash

  def to_paths(prefix=nil, stack=[])
    out=''

    self.each do |k,v|
      stack << k

      if v.is_a? Hash
        out += v.to_paths prefix, stack
      else
        out += ( prefix ? prefix + '/' : '' ) + stack.join('/') + "\n"
      end

      stack.pop
    end
    out
  end
end

class String
  def to_uri
    require 'uri'
    URI.encode( self ).gsub( ":", "%3A" ).gsub( "*", "%2A" )
  end

  def to_plain
    require 'uri'
    URI.decode self
  end
end
