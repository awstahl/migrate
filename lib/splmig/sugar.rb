#
#  File: sugar.rb
#  Author: alex@testcore.net
#
#  ADd some sugar onto the core classes.


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
