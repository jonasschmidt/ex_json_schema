defmodule ExJsonSchema.Schema.Root do
  defstruct schema: %{}, refs: %{}
  @type t :: %ExJsonSchema.Schema.Root{schema: ExJsonSchema.Schema.resolved, refs: %{String.t => ExJsonSchema.Schema.resolved}}
end
