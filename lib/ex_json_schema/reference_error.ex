defmodule ExJsonSchema.ReferenceError do
  @moduledoc """
  Describes a reference that is absent from a compiled schema graph.
  """

  @type t :: %__MODULE__{
          reference: String.t(),
          base_uri: String.t() | nil,
          message: String.t()
        }

  defexception [:reference, :base_uri, message: "schema reference not found"]

  @impl Exception
  def exception(options) do
    reference = Keyword.fetch!(options, :reference)
    base_uri = Keyword.get(options, :base_uri)

    message =
      Keyword.get_lazy(options, :message, fn ->
        if base_uri do
          "schema reference #{reference} was not found from #{base_uri}"
        else
          "schema reference #{reference} was not found"
        end
      end)

    %__MODULE__{reference: reference, base_uri: base_uri, message: message}
  end
end
