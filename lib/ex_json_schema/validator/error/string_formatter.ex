defmodule ExJsonSchema.Validator.Error.StringFormatter do
  alias ExJsonSchema.Validator.Error

  @spec format(ExJsonSchema.Validator.errors()) :: [{String.t(), String.t()}]
  def format(errors) do
    Enum.map(errors, fn %Error{error: error, path: path} ->
      {to_string(error), path}
    end)
  end

  def message(error) do
    message(error, detailed?())
  end

  def message(%Error.AdditionalItems{}, _) do
    "Schema does not allow additional items."
  end

  def message(%Error.AdditionalProperties{}, _) do
    "Schema does not allow additional properties."
  end

  def message(%Error.AllOf{invalid: invalid}, false) do
    "Expected all of the schemata to match, but the schemata at the following indexes did not: #{Enum.map_join(invalid, ", ", & &1.index)}."
  end

  def message(%Error.AllOf{} = error, true) do
    """
    #{message(error, false)}

    #{nest_errors(error)}
    """
  end

  def message(%Error.AnyOf{}, false) do
    "Expected any of the schemata to match but none did."
  end

  def message(%Error.AnyOf{} = error, true) do
    """
    #{message(error, false)}

    #{nest_errors(error)}
    """
  end

  def message(%Error.Const{expected: expected}, _) do
    "Expected data to be #{inspect(expected)}."
  end

  def message(%Error.Contains{}, false) do
    "Expected any of the items to match the schema but none did."
  end

  def message(%Error.Contains{} = error, true) do
    """
    #{message(error, false)}

    #{nest_errors(error)}
    """
  end

  def message(%Error.ContentEncoding{expected: expected}, _) do
    "Expected the content to be #{expected}-encoded."
  end

  def message(%Error.ContentMediaType{expected: expected}, _) do
    "Expected the content to be of media type #{expected}."
  end

  def message(%Error.Dependencies{property: property, missing: [missing]}, _) do
    "Property #{property} depends on property #{missing} to be present but it was not."
  end

  def message(%Error.Dependencies{property: property, missing: missing}, _) do
    "Property #{property} depends on properties #{Enum.join(missing, ", ")} to be present but they were not."
  end

  def message(%Error.Enum{}, _) do
    "Value is not allowed in enum."
  end

  def message(%Error.False{}, _) do
    "False schema never matches."
  end

  def message(%Error.Format{expected: expected}, _) do
    "Expected to be a valid #{format_name(expected)}."
  end

  def message(%Error.IfThenElse{branch: branch}, _) do
    "Expected the schema in the #{branch} branch to match but it did not."
  end

  def message(%Error.ItemsNotAllowed{}, _) do
    "Items are not allowed."
  end

  def message(%Error.MaxItems{expected: expected, actual: actual}, _) do
    "Expected a maximum of #{expected} items but got #{actual}."
  end

  def message(%Error.MaxLength{expected: expected, actual: actual}, _) do
    "Expected value to have a maximum length of #{expected} but was #{actual}."
  end

  def message(%Error.MaxProperties{expected: expected, actual: actual}, _) do
    "Expected a maximum of #{expected} properties but got #{actual}"
  end

  def message(%Error.Maximum{expected: expected, exclusive?: exclusive?}, _) do
    "Expected the value to be #{if exclusive?, do: "<", else: "<="} #{expected}"
  end

  def message(%Error.MinItems{expected: expected, actual: actual}, _) do
    "Expected a minimum of #{expected} items but got #{actual}."
  end

  def message(%Error.MinLength{expected: expected, actual: actual}, _) do
    "Expected value to have a minimum length of #{expected} but was #{actual}."
  end

  def message(%Error.MinProperties{expected: expected, actual: actual}, _) do
    "Expected a minimum of #{expected} properties but got #{actual}"
  end

  def message(%Error.Minimum{expected: expected, exclusive?: exclusive?}, _) do
    "Expected the value to be #{if exclusive?, do: ">", else: ">="} #{expected}"
  end

  def message(%Error.MultipleOf{expected: expected}, _) do
    "Expected value to be a multiple of #{expected}."
  end

  def message(%Error.Not{}, _) do
    "Expected schema not to match but it did."
  end

  def message(%Error.OneOf{valid_indices: valid_indices}, false) do
    if length(valid_indices) > 1 do
      "Expected exactly one of the schemata to match, but the schemata at the following indexes did: " <>
        Enum.join(valid_indices, ", ") <> "."
    else
      "Expected exactly one of the schemata to match, but none of them did."
    end
  end

  def message(%Error.OneOf{valid_indices: valid_indices} = error, true) do
    message = message(error)

    if length(valid_indices) > 1 do
      message
    else
      """
      #{message}

      #{nest_errors(error)}
      """
    end
  end

  def message(%Error.Pattern{expected: expected}, _) do
    "Does not match pattern #{inspect(expected)}."
  end

  def message(%Error.PropertyNames{invalid: invalid}, _) do
    "Expected the property names to be valid but the following were not: #{invalid |> Map.keys() |> Enum.sort() |> Enum.join(", ")}."
  end

  def message(%Error.Required{missing: [missing]}, _) do
    "Required property #{missing} was not present."
  end

  def message(%Error.Required{missing: missing}, _) do
    "Required properties #{Enum.join(missing, ", ")} were not present."
  end

  def message(%Error.Type{expected: expected, actual: actual}, _) do
    "Type mismatch. Expected #{type_names(expected)} but got #{type_names(actual)}."
  end

  def message(%Error.UniqueItems{}, _) do
    "Expected items to be unique but they were not."
  end

  defp format_name("date-time"), do: "ISO 8601 date-time"
  defp format_name("ipv4"), do: "IPv4 address"
  defp format_name("ipv6"), do: "IPv6 address"
  defp format_name(expected), do: expected

  defp type_names(types) do
    types
    |> List.wrap()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(", ")
  end

  defp nest_errors(%{invalid: invalid}) do
    error_messages =
      Enum.map_join(invalid, "\n", fn invalid ->
        "#{invalid.index}: " <>
          Enum.map_join(invalid.errors, "\n", fn %Error{error: error} -> to_string(error) end)
      end)
      |> String.replace("\n", "\n  ")

    """
    The following errors were found:
      #{error_messages}
    """
    |> String.trim()
  end

  def detailed?() do
    Application.get_env(:ex_json_schema, :detailed_errors, false)
  end

  @error_types [
    Error.AdditionalItems,
    Error.AdditionalProperties,
    Error.AllOf,
    Error.AnyOf,
    Error.Const,
    Error.Contains,
    Error.ContentEncoding,
    Error.ContentMediaType,
    Error.Dependencies,
    Error.Enum,
    Error.False,
    Error.Format,
    Error.IfThenElse,
    Error.InvalidAtIndex,
    Error.ItemsNotAllowed,
    Error.MaxItems,
    Error.MaxLength,
    Error.MaxProperties,
    Error.Maximum,
    Error.MinItems,
    Error.MinLength,
    Error.MinProperties,
    Error.Minimum,
    Error.MultipleOf,
    Error.Not,
    Error.OneOf,
    Error.Pattern,
    Error.PropertyNames,
    Error.Required,
    Error.Type,
    Error.UniqueItems
  ]

  for error_type <- @error_types do
    defimpl String.Chars, for: error_type do
      def to_string(error),
        do: ExJsonSchema.Validator.Error.StringFormatter.message(error)
    end
  end
end
