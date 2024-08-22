defmodule ExJsonSchema.Schema.Root do
  defstruct schema: %{},
            refs: %{},
            definitions: %{},
            location: :root,
            version: nil,
            custom_format_validator: nil,
            custom_keyword_validator: nil

  @type t :: %ExJsonSchema.Schema.Root{
          schema: ExJsonSchema.Schema.resolved(),
          refs: %{String.t() => ExJsonSchema.Schema.resolved()},
          location: :root | String.t(),
          definitions: %{String.t() => ExJsonSchema.Schema.resolved()},
          version: non_neg_integer | nil,
          custom_format_validator: {module(), atom()} | (String.t(), any() -> boolean | {:error, any()}) | nil,
          custom_keyword_validator:
            {module(), atom()}
            | (ExJsonSchema.Schema.Root.t(), any(), any() -> list(ExJsonSchema.Validator.Error.t()))
            | nil
        }
end
