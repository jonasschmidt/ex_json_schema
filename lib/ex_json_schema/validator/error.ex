defmodule ExJsonSchema.Validator.Error do
  alias ExJsonSchema.Validator.Error

  defstruct [:error, :path]

  @type t :: %Error{}

  defmodule Type, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: Type do
    def to_string(%Type{expected: expected, actual: actual}) do
      "Type mismatch. Expected #{Enum.join(expected, ", ")} but got #{actual}"
    end
  end

  defmodule InvalidAtIndex, do: defstruct [:index, :errors]
  defimpl String.Chars, for: InvalidAtIndex do
    def to_string(%InvalidAtIndex{index: index, errors: _errors}) do
      "Schemata at index #{index} did not match"
    end
  end

  defmodule AllOf, do: defstruct [:invalid]
  defimpl String.Chars, for: AllOf do
    def to_string(%AllOf{invalid: invalid}) do
      indices = Enum.map_join(invalid, ", ", fn %InvalidAtIndex{index: index} -> "#{index}" end)
      "Expected all of the schemata to match, but the schemata at the following indexes did not: #{indices}"
    end
  end

  defmodule AnyOf, do: defstruct [:invalid]
  defimpl String.Chars, for: AnyOf do
    def to_string(%AnyOf{invalid: _invalid}) do
      "Expected any of the schemata to match, but none did"
    end
  end

  defmodule OneOf, do: defstruct [:valid_indices, :invalid]
  defimpl String.Chars, for: OneOf do
    def to_String(%OneOf{invalid: [], valid_indices: valid_indices}) do
      "Expected exactly one of the schemata to match, but the schemata at the following indexes did: #{Enum.join(valid_indices, ", ")}"
    end

    def to_string(%OneOf{invalid: _invalid, valid_indices: []}) do
      "Expected exactly one of the schemata to match, but none did."
    end
  end

  defmodule Not, do: defstruct []
  defimpl String.Chars, for: Not do
    def to_string(%Not{}) do
      "Expected schema not to match but it did"
    end
  end

  defmodule AdditionalProperties, do: defstruct []
  defimpl String.Chars, for: AdditionalProperties do
    def to_string(%AdditionalProperties{}) do
      "Schema does not allow additional properties"
    end
  end

  defmodule MinProperties, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: MinProperties do
    def to_string(%MinProperties{expected: expected, actual: actual}) do
      "Expected a minimum of #{expected} properties but got #{actual}"
    end
  end

  defmodule MaxProperties, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: MaxProperties do
    def to_string(%MaxProperties{expected: expected, actual: actual}) do
      "Expected a maximum of #{expected} properties but got #{actual}"
    end
  end

  defmodule Required, do: defstruct [:missing]
  defimpl String.Chars, for: Required do
    def to_string(%Required{missing: [missing]}) do
      "Required property #{missing} was not present"
    end

    def to_string(%Required{missing: missing}) do
      "Required properties #{Enum.join(missing, ", ")} were not present"
    end
  end

  defmodule Dependencies, do: defstruct [:property, :missing]
  defimpl String.Chars, for: Dependencies do
    def to_string(%Dependencies{property: property, missing: missing}) do
      "Property #{property} depends on #{missing} to be present but it was not"
    end
  end

  defmodule AdditionalItems, do: defstruct [:additional_indices]
  defimpl String.Chars, for: AdditionalItems do
    def to_string(%AdditionalItems{additional_indices: additional_indices}) do
      "Schema does not allow additional items, check indices #{Enum.join(additional_indices, ", ")}"
    end
  end

  defmodule MinItems, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: MinItems do
    def to_string(%MinItems{expected: expected, actual: actual}) do
      "Expected a minimum of #{expected} items but got #{actual}"
    end
  end

  defmodule MaxItems, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: MaxItems do
    def to_string(%MaxItems{expected: expected, actual: actual}) do
      "Expected a maximum of #{expected} items but got #{actual}"
    end
  end

  defmodule UniqueItems, do: defstruct []
  defimpl String.Chars, for: UniqueItems do
    def to_string(%UniqueItems{}) do
      "Expected items to be unique but they were not"
    end
  end

  defmodule Enum, do: defstruct []
  defimpl String.Chars, for: Enum do
    def to_string(%Enum{}) do
      "Value is not allowed in enum"
    end
  end

  defmodule Minimum, do: defstruct [:expected, :exclusive?]
  defimpl String.Chars, for: Minimum do
    def to_string(%Minimum{expected: expected, exclusive?: exclusive?}) do
      "Expected value to be #{if exclusive?, do: ">", else: ">="} #{expected}"
    end
  end

  defmodule Maximum, do: defstruct [:expected, :exclusive?]
  defimpl String.Chars, for: Maximum do
    def to_string(%Maximum{expected: expected, exclusive?: exclusive?}) do
      "Expected value to be #{if exclusive?, do: "<", else: "<="} #{expected}"
    end
  end

  defmodule MultipleOf, do: defstruct [:expected]
  defimpl String.Chars, for: MultipleOf do
    def to_string(%MultipleOf{expected: expected}) do
      "Expected value to be a multiple of #{expected}"
    end
  end

  defmodule MinLength, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: MinLength do
    def to_string(%MinLength{expected: expected, actual: actual}) do
      "Expected value to have a minimum length of #{expected} but was #{actual}"
    end
  end

  defmodule MaxLength, do: defstruct [:expected, :actual]
  defimpl String.Chars, for: MaxLength do
    def to_string(%MaxLength{expected: expected, actual: actual}) do
      "Expected value to have a maximum length of #{expected} but was #{actual}"
    end
  end

  defmodule Pattern, do: defstruct [:expected]
  defimpl String.Chars, for: Pattern do
    def to_string(%Pattern{expected: expected}) do
      "String does not match pattern #{inspect(expected)}"
    end
  end

  defmodule Format, do: defstruct [:expected]
  defimpl String.Chars, for: AdditionalFormatItems do
    def to_string(%Format{expected: "date-time"}) do
      "Expected value to be a valid ISO 8601 date-time"
    end

    def to_string(%Format{expected: "email"}) do
      "Expected value to be an email address"
    end

    def to_string(%Format{expected: "hostname"}) do
      "Expected value to be a hostname"
    end

    def to_string(%Format{expected: "ipv4"}) do
      "Expected value to be an IPv4 address"
    end

    def to_string(%Format{expected: "ipv6"}) do
      "Expected value to be an IPv6 address"
    end
  end
end
