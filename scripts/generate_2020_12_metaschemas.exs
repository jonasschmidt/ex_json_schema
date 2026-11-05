Mix.Task.run("app.start")

base_uri = "https://json-schema.org/draft/2020-12/"

paths = [
  "schema",
  "meta/core",
  "meta/applicator",
  "meta/unevaluated",
  "meta/validation",
  "meta/meta-data",
  "meta/format-annotation",
  "meta/format-assertion",
  "meta/content"
]

schemas =
  Map.new(paths, fn path ->
    uri = base_uri <> path
    {json, 0} = System.cmd("curl", ["--fail", "--silent", "--show-error", uri])
    {uri, Jason.decode!(json)}
  end)

contents = """
defmodule ExJsonSchema.Schema.Draft202012 do
  @moduledoc false

  @schemas #{inspect(schemas, pretty: true, limit: :infinity, printable_limit: :infinity)}

  @spec schema(String.t()) :: ExJsonSchema.data()
  def schema(uri \\\\ "#{base_uri}schema"), do: Map.fetch!(@schemas, uri)

  @spec all() :: %{String.t() => ExJsonSchema.data()}
  def all, do: @schemas

  @spec version() :: :"2020-12"
  def version, do: :"2020-12"
end
"""

formatted = contents |> Code.format_string!() |> then(&[&1, "\n"]) |> IO.iodata_to_binary()
File.write!("lib/ex_json_schema/schema/draft202012.ex", formatted)
