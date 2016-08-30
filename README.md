# migrate
A configuration artifact migration tool

Migrate configuration artifacts from one system to another - say, dev to test, or legacy to new.  Currently is a collection of objects designed to retrieve conf data; model said data as ruby objects to allow for programmatic modification; and to print the modeled data as a conf file.

Requires: ruby 2.x, optparse, yaml, and net/ssh gems, a (splunk) server w/ ssh access

Usage
-----

###### >irb
``` shell
require './lib/migrate'

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
> { 'path' => { 'to' => { 'app' => { 'conf.d' => [ #parsed content array ] }}}}

# Paths become hash keys
app.conf[ 'path' ][ 'to' ][ 'app' ][ 'conf.d' ][ 'auth.conf' ]
> structured file contents

#Alternately, retrieve contents via the path string
app.retrieve '/path/to/app/conf.d/auth.conf'
> structured file contents

...
```

