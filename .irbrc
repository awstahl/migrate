require './lib/migrate'

Conf = { connection: {
  host: 'splunk.lan',
  user: 'splunk',
  keyfile: '/path/to/key'
  }
}

Path = '/opt/splunk/etc/system'
Paths = [ "#{ Path }/local/inputs.conf", "#{ Path }/local/savedsearches.conf" ]
