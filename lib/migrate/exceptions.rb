#
#  File: exceptions.rb
#  Author: alex@testcore.net
#
#  This is a set of exceptions for Migration failures


module Migration
  class InvalidConnection < Exception; end
  class InvalidPath < Exception; end
  class MissingConnection < Exception; end
  class MissingKeyfile < Exception; end
  class MissingPathRoot < Exception; end
end
