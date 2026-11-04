defmodule ExJsonSchema.Compiler.Dialect do
  @moduledoc false

  # Describes the keywords, vocabularies, and assertion behavior of a
  # supported JSON Schema dialect.

  @type version :: 4 | 6 | 7 | :"2020-12"
  @type t :: %__MODULE__{
          id: String.t(),
          aliases: MapSet.t(String.t()),
          version: version(),
          metaschema: ExJsonSchema.data(),
          vocabularies: MapSet.t(String.t()),
          keyword_order: [String.t()],
          assert_formats?: boolean(),
          content_assertion?: boolean()
        }

  defstruct id: "",
            aliases: MapSet.new(),
            version: nil,
            metaschema: %{},
            vocabularies: MapSet.new(),
            keyword_order: [],
            assert_formats?: false,
            content_assertion?: false
end
