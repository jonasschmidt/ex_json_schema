defmodule ExJsonSchema.Schema.Root do
  defstruct schema: %{},
            refs: %{},
            location: :root,
            version: nil,
            custom_format_validator: nil

  @type t :: %ExJsonSchema.Schema.Root{
          schema: ExJsonSchema.Schema.resolved(),
          refs: %{String.t() => ExJsonSchema.Schema.resolved()},
          location: :root | String.t(),
          version: non_neg_integer | nil,
          custom_format_validator: {module(), atom()} | nil
        }
end
