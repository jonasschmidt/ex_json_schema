defmodule ExJsonSchema.Validator do
  alias ExJsonSchema.Schema
  alias ExJsonSchema.Schema.Root

  @type errors :: [{String.t(), String.t()}] | []
  @type errors_with_list_paths :: [{String.t(), [String.t() | integer]}] | []

  @callback validate(
              Root.t(),
              ExJsonSchema.data(),
              {String.t(), ExJsonSchema.data()},
              ExJsonSchema.data()
            ) :: errors_with_list_paths

  @validators [
    ExJsonSchema.Validator.AllOf,
    ExJsonSchema.Validator.AnyOf,
    ExJsonSchema.Validator.Const,
    ExJsonSchema.Validator.Contains,
    ExJsonSchema.Validator.ContentEncoding,
    ExJsonSchema.Validator.ContentMediaType,
    ExJsonSchema.Validator.Dependencies,
    ExJsonSchema.Validator.Enum,
    ExJsonSchema.Validator.ExclusiveMaximum,
    ExJsonSchema.Validator.ExclusiveMinimum,
    ExJsonSchema.Validator.Format,
    ExJsonSchema.Validator.Items,
    ExJsonSchema.Validator.MaxItems,
    ExJsonSchema.Validator.MaxLength,
    ExJsonSchema.Validator.MaxProperties,
    ExJsonSchema.Validator.Maximum,
    ExJsonSchema.Validator.MinItems,
    ExJsonSchema.Validator.MinLength,
    ExJsonSchema.Validator.MinProperties,
    ExJsonSchema.Validator.Minimum,
    ExJsonSchema.Validator.MultipleOf,
    ExJsonSchema.Validator.Not,
    ExJsonSchema.Validator.OneOf,
    ExJsonSchema.Validator.Pattern,
    ExJsonSchema.Validator.Properties,
    ExJsonSchema.Validator.PropertyNames,
    ExJsonSchema.Validator.Ref,
    ExJsonSchema.Validator.Required,
    ExJsonSchema.Validator.Type,
    ExJsonSchema.Validator.UniqueItems
  ]

  @spec validate(Root.t() | ExJsonSchema.data(), ExJsonSchema.data()) :: :ok | {:error, errors}
  def validate(root = %Root{}, data) do
    errors =
      root
      |> validate(root.schema, data, ["#"])
      |> errors_with_string_paths()

    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end

  def validate(schema = %{}, data) do
    schema
    |> Schema.resolve()
    |> validate(data)
  end

  @spec validate(Root.t(), Schema.resolved(), ExJsonSchema.data(), [String.t() | integer]) ::
          errors_with_list_paths
  def validate(root, schema, data, path \\ []) do
    schema
    |> Enum.flat_map(fn property ->
      Enum.flat_map(@validators, fn validator ->
        validator.validate(root, schema, property, data)
      end)
    end)
    |> Enum.map(fn {msg, p} -> {msg, path ++ p} end)
  end

  @spec valid?(Root.t() | ExJsonSchema.data(), ExJsonSchema.data()) :: boolean
  def valid?(root = %Root{}, data) do
    valid?(root, root.schema, data)
  end

  def valid?(schema = %{}, data) do
    schema
    |> Schema.resolve()
    |> valid?(data)
  end

  @spec valid?(Root.t(), Schema.resolved(), ExJsonSchema.data()) :: boolean
  def valid?(root, schema, data) do
    root
    |> validate(schema, data)
    |> Enum.empty?()
  end

  defp errors_with_string_paths(errors) do
    Enum.map(errors, fn {msg, path} ->
      {msg, Enum.join(path, "/")}
    end)
  end
end
