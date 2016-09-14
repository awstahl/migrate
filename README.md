# migrate
A configuration artifact migration tool

Migrate configuration artifacts from one system to another - say, dev to test, or legacy to new.  Currently is a collection of objects designed to retrieve conf data; model said data as ruby objects to allow for programmatic modification; and to print the modeled data as a conf file.

Requires: ruby 2.x, optparse, yaml, and net/ssh gems, a server w/ ssh access

Usage
-----

###### >irb
``` shell
require 'migrate'

# First, create a (SSH-based) connection hash
connection = host: 'myhost', user: 'myuser', keyfile: '/path/to/mykey.pem'

# Create a server object with it
srv = Migration::Server.new connection: connection

# Create an application object
app = Migration::Application.new root: '/path/to/app/conf.d'

# Fetch the app configuration with the server
srv.fetch app
> # iterates files under app.root, fetching contents of each

# Explore the contents of the app through its config hash
app.conf
> { 'path' => { 'to' => { 'app' => { 'conf.d' => { 'auth.conf' => [ #parsed content array ], 'web.conf' => [] }}}}

# Paths become hash keys
app.conf[ 'path' ][ 'to' ][ 'app' ][ 'conf.d' ][ 'auth.conf' ]
> structured file contents

# Alternately, retrieve contents via the path string
app.retrieve '/path/to/app/conf.d/auth.conf'
> structured file contents

# Conf data is auto-parsed based on what it looks like.
# In the case of an INI-style file, with named stanzas,
# the result is an array of Artifacts containing the 
# parsed stanza.
stanza = app.retrieve( '/path/to/app/conf.d/auth.conf' ).first

# The artifact provides methods to view its contents
stanza.name             # INI header
stanza.source           # pre-parsed source text
stanza.data             # parsed source text (typically a hash)
stanza.has? key         # test if stanza has a particular key
stanza.fix! key, 'val'  # explicitly set key to 'val'

# ...or set with a block:
index = 'bar'
stanza.fix! key do |v|
  v.gsub /index\s?=\s?foo/, "index = #{ index }"
end

...
```

