defmodule ExJsonSchema.Schema.Root do
  defstruct schema: %{}, refs: %{}, location: :root

  @type t :: %ExJsonSchema.Schema.Root{
          schema: ExJsonSchema.Schema.resolved(),
          refs: %{String.t() => ExJsonSchema.Schema.resolved()},
          location: :root | String.t()
        }
end
