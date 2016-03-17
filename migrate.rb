#!/usr/bin/env ruby

# This script provides a CLI interface to the
# Migration module in models.rb.

require "#{ File.dirname __FILE__ }/lib/models.rb"

=begin

Command pattern?

Commands:
  list - retrieve splunk artifacts from a remote machine
  - Required params:
  -- host
  -- artifacts filename

  - Optional params:
  -- search path
  --- by base path
  --- by user

  merge - merge two collections of artifacts
  - Required params:
  -- source host
  -- dest host

  - Optional params:
  -- search path
  --- Required: file name
  -- full file path
  -- merge behavior

  migrate - execute migration rules on artifacts

  deploy - deploy a generated conf with artifacts to a server

Options:
-c <path> - Config file


Some desired command idioms:

- List all apps on a given server
[spl-mig] list apps -h example.com -u admin -k ~/path/to/key.pem

- List all alerts in search (connection defaults in config!)
[spl-mig] list alerts -a search -h example.com



=end

Migration::Options.parse ARGV
