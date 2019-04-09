defmodule ExJsonSchema.Validator.Error.StringFormatter do
  alias ExJsonSchema.Validator.Error

  @spec format(ExJsonSchema.Validator.errors()) :: [{String.t(), String.t()}]
  def format(errors) do
    Enum.map(errors, fn %Error{error: error, path: path} ->
      {to_string(error), path}
    end)
  end

  defimpl String.Chars, for: Error.Type do
    def to_string(%Error.Type{expected: expected, actual: actual}) do
      "Type mismatch. Expected #{type_names(expected)} but got #{type_names(actual)}."
    end

    defp type_names(types) do
      types
      |> List.wrap()
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(", ")
    end
  end

  defimpl String.Chars, for: Error.AllOf do
    def to_string(%Error.AllOf{invalid: invalid}) do
      "Expected all of the schemata to match, but the schemata at the following indexes did not: #{
        Enum.map_join(invalid, ", ", & &1.index)
      }."
    end
  end

  defimpl String.Chars, for: Error.AnyOf do
    def to_string(%Error.AnyOf{}) do
      "Expected any of the schemata to match but none did."
    end
  end

  defimpl String.Chars, for: Error.OneOf do
    def to_string(%Error.OneOf{valid_indices: valid_indices}) do
      if length(valid_indices) > 1 do
        "Expected exactly one of the schemata to match, but the schemata at the following indexes did: " <>
          Enum.join(valid_indices, ", ") <> "."
      else
        "Expected exactly one of the schemata to match, but none of them did."
      end
    end
  end

  defimpl String.Chars, for: Error.Not do
    def to_string(%Error.Not{}) do
      "Expected schema not to match but it did."
    end
  end

  defimpl String.Chars, for: Error.AdditionalProperties do
    def to_string(%Error.AdditionalProperties{}) do
      "Schema does not allow additional properties."
    end
  end

  defimpl String.Chars, for: Error.MinProperties do
    def to_string(%Error.MinProperties{expected: expected, actual: actual}) do
      "Expected a minimum of #{expected} properties but got #{actual}"
    end
  end

  defimpl String.Chars, for: Error.MaxProperties do
    def to_string(%Error.MaxProperties{expected: expected, actual: actual}) do
      "Expected a maximum of #{expected} properties but got #{actual}"
    end
  end

  defimpl String.Chars, for: Error.Required do
    def to_string(%Error.Required{missing: [missing]}) do
      "Required property #{missing} was not present."
    end

    def to_string(%Error.Required{missing: missing}) do
      "Required properties #{Enum.join(missing, ", ")} were not present."
    end
  end

  defimpl String.Chars, for: Error.Dependencies do
    def to_string(%Error.Dependencies{property: property, missing: [missing]}) do
      "Property #{property} depends on property #{missing} to be present but it was not."
    end

    def to_string(%Error.Dependencies{property: property, missing: missing}) do
      "Property #{property} depends on properties #{Enum.join(missing, ", ")} to be present but they were not."
    end
  end

  defimpl String.Chars, for: Error.AdditionalItems do
    def to_string(%Error.AdditionalItems{}) do
      "Schema does not allow additional items."
    end
  end

  defimpl String.Chars, for: Error.MinItems do
    def to_string(%Error.MinItems{expected: expected, actual: actual}) do
      "Expected a minimum of #{expected} items but got #{actual}."
    end
  end

  defimpl String.Chars, for: Error.MaxItems do
    def to_string(%Error.MaxItems{expected: expected, actual: actual}) do
      "Expected a maximum of #{expected} items but got #{actual}."
    end
  end

  defimpl String.Chars, for: Error.UniqueItems do
    def to_string(%Error.UniqueItems{}) do
      "Expected items to be unique but they were not."
    end
  end

  defimpl String.Chars, for: Error.Enum do
    def to_string(%Error.Enum{}) do
      "Value is not allowed in enum."
    end
  end

  defimpl String.Chars, for: Error.Minimum do
    def to_string(%Error.Minimum{expected: expected, exclusive?: exclusive?}) do
      "Expected the value to be #{if exclusive?, do: ">", else: ">="} #{expected}"
    end
  end

  defimpl String.Chars, for: Error.Maximum do
    def to_string(%Error.Maximum{expected: expected, exclusive?: exclusive?}) do
      "Expected the value to be #{if exclusive?, do: "<", else: "<="} #{expected}"
    end
  end

  defimpl String.Chars, for: Error.MultipleOf do
    def to_string(%Error.MultipleOf{expected: expected}) do
      "Expected value to be a multiple of #{expected}."
    end
  end

  defimpl String.Chars, for: Error.MinLength do
    def to_string(%Error.MinLength{expected: expected, actual: actual}) do
      "Expected value to have a minimum length of #{expected} but was #{actual}."
    end
  end

  defimpl String.Chars, for: Error.MaxLength do
    def to_string(%Error.MaxLength{expected: expected, actual: actual}) do
      "Expected value to have a maximum length of #{expected} but was #{actual}."
    end
  end

  defimpl String.Chars, for: Error.Pattern do
    def to_string(%Error.Pattern{expected: expected}) do
      "Does not match pattern #{inspect(expected)}."
    end
  end

  defimpl String.Chars, for: Error.Format do
    def to_string(%Error.Format{expected: expected}) do
      "Expected to be a valid #{format_name(expected)}."
    end

    defp format_name("date-time"), do: "ISO 8601 date-time"
    defp format_name("ipv4"), do: "IPv4 address"
    defp format_name("ipv6"), do: "IPv6 address"
    defp format_name(expected), do: expected
  end
end
