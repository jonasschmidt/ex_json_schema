defmodule ExJsonSchema.Compiler.Vocabulary do
  @moduledoc false

  # Associates a vocabulary identifier with the keyword set it activates.

  @type t :: %__MODULE__{
          id: String.t(),
          keywords: MapSet.t(String.t())
        }

  defstruct id: "", keywords: MapSet.new()
end
