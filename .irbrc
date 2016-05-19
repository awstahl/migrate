require './lib/models.rb'

def artify(it)
  out = {}
  it.each do |stanza|
    artifact = Migration::Artifact.new stanza
    artifact.parse
    out[ artifact.name ] = artifact
  end
  out
end

