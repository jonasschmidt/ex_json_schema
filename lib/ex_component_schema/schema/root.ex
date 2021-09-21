defmodule ExComponentSchema.Schema.Root do
  defstruct schema: %{},
            refs: %{},
            definitions: %{},
            location: :root,
            version: nil,
            custom_format_validator: nil

  @type t :: %ExComponentSchema.Schema.Root{
          schema: ExComponentSchema.Schema.resolved(),
          refs: %{String.t() => ExComponentSchema.Schema.resolved()},
          location: :root | String.t(),
          definitions: %{String.t() => ExComponentSchema.Schema.resolved()},
          version: non_neg_integer | nil,
          custom_format_validator: {module(), atom()} | nil
        }
end
