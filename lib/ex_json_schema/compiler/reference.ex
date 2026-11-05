defmodule ExJsonSchema.Compiler.Reference do
  @moduledoc false

  # Records a discovered static or dynamic reference together with its source
  # and resolved target locations.

  alias ExJsonSchema.Compiler.Location

  @type kind :: :ref | :dynamic_ref
  @type t :: %__MODULE__{
          kind: kind(),
          value: String.t(),
          base_uri: String.t(),
          source: Location.t(),
          target: Location.t() | nil,
          dynamic_anchor: String.t() | nil
        }

  defstruct kind: :ref,
            value: "",
            base_uri: "",
            source: nil,
            target: nil,
            dynamic_anchor: nil
end
