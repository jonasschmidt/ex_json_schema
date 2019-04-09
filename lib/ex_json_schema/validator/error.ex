defmodule ExJsonSchema.Validator.Error do
  defstruct [:error, :path]

  defmodule Type do
    defstruct([:expected, :actual])
  end

  defmodule AllOf do
    defstruct([:invalid])
  end

  defmodule AnyOf do
    defstruct([:invalid])
  end

  defmodule OneOf do
    defstruct([:valid_indices, :invalid])
  end

  defmodule InvalidAtIndex do
    defstruct([:index, :errors])
  end

  defmodule Not do
    defstruct([])
  end

  defmodule AdditionalProperties do
    defstruct([])
  end

  defmodule MinProperties do
    defstruct([:expected, :actual])
  end

  defmodule MaxProperties do
    defstruct([:expected, :actual])
  end

  defmodule Required do
    defstruct([:missing])
  end

  defmodule Dependencies do
    defstruct([:property, :missing])
  end

  defmodule AdditionalItems do
    defstruct([:additional_indices])
  end

  defmodule MinItems do
    defstruct([:expected, :actual])
  end

  defmodule MaxItems do
    defstruct([:expected, :actual])
  end

  defmodule UniqueItems do
    defstruct([])
  end

  defmodule Enum do
    defstruct([])
  end

  defmodule Minimum do
    defstruct([:expected, :exclusive?])
  end

  defmodule Maximum do
    defstruct([:expected, :exclusive?])
  end

  defmodule MultipleOf do
    defstruct([:expected])
  end

  defmodule MinLength do
    defstruct([:expected, :actual])
  end

  defmodule MaxLength do
    defstruct([:expected, :actual])
  end

  defmodule Pattern do
    defstruct([:expected])
  end

  defmodule Format do
    defstruct([:expected])
  end
end
