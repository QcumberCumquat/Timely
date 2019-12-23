defmodule Mobilizon.Vocabulary do
  use RDF.Vocabulary.Namespace

  defvocab ActivityStreams,
           base_iri: "http://www.w3.org/ns/activitystreams#",
           file: "activitystreams.jsonld",
           strict: false

  defvocab Schema,
           base_iri: "http://schema.org/",
           file: "schema.org.jsonld"

end