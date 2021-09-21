defmodule ExComponentSchema.Schema.DraftLenra do
  @spec schema() :: ExComponentSchema.object()
  def schema,
    do:
      Poison.decode!(
        File.read!(Path.join(:code.priv_dir(:ex_component_schema), "static/draft-lenra.json"))
      )

  @spec version() :: integer()
  def version, do: 4
end
