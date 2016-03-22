# migrate
A (splunk) config artifact migration tool

Migrate configuration artifacts from one system to another (say, dev to test). Currently is a collection of objects designed for use with a splunk server.

Requires: ruby 2.x, a optparse, yaml, net/ssh gems, a (splunk) server w/ ssh access

Usage
-----

###### >irb
``` shell
require './lib/models'

# First, create a (SSH-based) connection object
connection = Migration::Server::Connection.new 'myhost', 'myuser', '/path/to/mykey.pem'

# Pass it to a porter
porter = Migration::Server::Porter.new connection

# Use the porter & Parser to fetch file lists
flist = Migration::Parser.parse porter.list( '/path/to/confs' )

# Use the porter & Parser to retrieve file contents
slist = Migration::Parser.parse porter.get( flist.first )

...
```

#### TODO

1. Bug extermination
2. Add configuration instance
3. Add server manager class
4. Add option parsers for CLI
