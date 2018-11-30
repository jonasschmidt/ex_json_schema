defmodule ExJsonSchema.Validator.Error.StringFormatter do
  alias ExJsonSchema.Validator.Error.StringFormatter
  alias ExJsonSchema.Validator.Error

  @spec format(
          ExJsonSchema.Validator.errors()
          | {:error, ExJsonSchema.Validator.errors()}
          | :ok
        ) :: [{String.t(), String.t()}] | :ok
  def format(:ok), do: :ok
  def format({:error, errors}), do: format(errors)

  def format(errors) do
    Enum.map(errors, fn %Error{error: error, path: path} ->
      {to_string(error), path}
    end)
  end

  defimpl String.Chars, for: Error.Type do
    def to_string(%Error.Type{expected: expected, actual: actual}) do
      "Type mismatch. Expected #{Enum.join(expected, ", ")} but got #{actual}."
    end
  end

  defimpl String.Chars, for: Error.AllOf do
    def to_string(%Error.AllOf{invalid: invalid}) do
      "Expected all of the schemata to match, but the schemata at the following indexes did not: " <>
        Enum.map_join(invalid, ", ", &Kernel.to_string/1)
    end
  end

  defimpl String.Chars, for: Error.AnyOf do
    def to_string(%Error.AnyOf{invalid: invalid}) do
      "Expected any of the schemata to match but none did: " <>
        Enum.map_join(invalid, ", ", &Kernel.to_string/1)
    end
  end

  defimpl String.Chars, for: Error.OneOf do
    def to_string(%Error.OneOf{invalid: invalid, valid_indices: valid_indices}) do
      if length(valid_indices) > 1 do
        "Expected exactly one of the schemata to match, but the schemata at the following indexes did: " <>
          Enum.join(valid_indices, ", ") <> "."
      else
        "Expected exactly one of the schemata to match, but none did: " <>
          Enum.map_join(invalid, ", ", &Kernel.to_string/1)
      end
    end
  end

  defimpl String.Chars, for: Error.InvalidAtIndex do
    def to_string(%Error.InvalidAtIndex{index: index, errors: errors}) do
      "Index #{index}: (#{
        Enum.map_join(StringFormatter.format(errors), ", ", fn {error, path} ->
          "{#{error}, #{path}}"
        end)
      })"
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
    def to_string(%Error.Required{missing: missing}) do
      "Required property #{Enum.join(missing, ", ")} was not present."
    end
  end

  defimpl String.Chars, for: Error.Dependencies do
    def to_string(%Error.Dependencies{property: property, missing: missing}) do
      "Property #{property} depends on #{Enum.join(missing, ", ")} to be present but it was not."
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
      "Not a allowed value in enum."
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
      "Doesn't match pattern #{inspect(expected)}."
    end
  end

  defimpl String.Chars, for: Error.Format do
    def to_string(%Error.Format{expected: expected}) do
      "Expected to be a valid #{expected}."
    end
  end
end
