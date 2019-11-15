defmodule ExJsonSchema.Schema.Root do
  defstruct schema: %{}, refs: %{}, location: :root, custom_format_validator: nil

  @type t :: %ExJsonSchema.Schema.Root{
          schema: ExJsonSchema.Schema.resolved(),
          refs: %{String.t() => ExJsonSchema.Schema.resolved()},
          location: :root | String.t(),
          custom_format_validator: {module(), atom()} | nil
        }
end
