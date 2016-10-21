defmodule NExJsonSchema.Schema.Root do
  defstruct schema: %{}, refs: %{}, location: :root
  @type t :: %NExJsonSchema.Schema.Root{schema: NExJsonSchema.Schema.resolved, refs: %{String.t => NExJsonSchema.Schema.resolved}, location: :root | String.t}
end
