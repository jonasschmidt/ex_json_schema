use Mix.Config

defmodule SchemaResolver do
  def resolve(_root, url) do
    schema = HTTPoison.get!(url).body |> Poison.decode!
    {url, schema}
  end
end

config :ex_json_schema, :remote_schema_resolver, &SchemaResolver.resolve/2
