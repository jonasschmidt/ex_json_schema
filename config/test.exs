use Mix.Config

config :ex_json_schema, :decode_json, fn json -> Poison.decode(json) end
config :ex_json_schema, :remote_schema_resolver, fn url -> HTTPoison.get!(url).body |> Poison.decode! end
