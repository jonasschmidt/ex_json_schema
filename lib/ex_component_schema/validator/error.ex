defmodule ExComponentSchema.Validator.Error do
  # credo:disable-for-this-file Credo.Check.Readability.ModuleDoc

  defstruct [:error, :path]

  defmodule AdditionalItems do
    defstruct([:additional_indices])
  end

  defmodule AdditionalProperties do
    defstruct([])
  end

  defmodule AllOf do
    defstruct([:invalid])
  end

  defmodule AnyOf do
    defstruct([:invalid])
  end

  defmodule Const do
    defstruct([:expected])
  end

  defmodule Contains do
    defstruct([:empty?, :invalid])
  end

  defmodule ContentEncoding do
    defstruct([:expected])
  end

  defmodule ContentMediaType do
    defstruct([:expected])
  end

  defmodule Dependencies do
    defstruct([:property, :missing])
  end

  defmodule Enum do
    defstruct([:enum, :actual])
  end

  defmodule False do
    defstruct([])
  end

  defmodule Format do
    defstruct([:expected])
  end

  defmodule IfThenElse do
    defstruct([:branch, :errors])
  end

  defmodule InvalidAtIndex do
    defstruct([:index, :errors])
  end

  defmodule ItemsNotAllowed do
    defstruct([])
  end

  defmodule MaxItems do
    defstruct([:expected, :actual])
  end

  defmodule MaxLength do
    defstruct([:expected, :actual])
  end

  defmodule MaxProperties do
    defstruct([:expected, :actual])
  end

  defmodule Maximum do
    defstruct([:expected, :exclusive?])
  end

  defmodule MinItems do
    defstruct([:expected, :actual])
  end

  defmodule MinLength do
    defstruct([:expected, :actual])
  end

  defmodule MinProperties do
    defstruct([:expected, :actual])
  end

  defmodule Minimum do
    defstruct([:expected, :exclusive?])
  end

  defmodule MultipleOf do
    defstruct([:expected])
  end

  defmodule Not do
    defstruct([])
  end

  defmodule OneOf do
    defstruct([:valid_indices, :invalid])
  end

  defmodule Pattern do
    defstruct([:expected])
  end

  defmodule PropertyNames do
    defstruct([:invalid])
  end

  defmodule Required do
    defstruct([:missing])
  end

  defmodule Type do
    defstruct([:expected, :actual])
  end

  defmodule Component do
    defstruct([:expected, :actual, :no_comp_property])
  end

  defmodule UniqueItems do
    defstruct([])
  end
end
