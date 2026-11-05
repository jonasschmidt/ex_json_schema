defmodule ExJsonSchema.CompileError do
  @moduledoc """
  Describes a failure to compile a JSON Schema resource graph.

  The same struct is returned by non-bang compilation and raised by bang
  compilation.
  """

  @type reason ::
          :unsupported_dialect
          | :unsupported_vocabulary
          | :invalid_schema
          | :resolver
          | :invalid_reference
          | :invalid_option

  @type t :: %__MODULE__{
          reason: reason(),
          message: String.t(),
          uri: String.t() | nil,
          details: term(),
          output: map() | nil
        }

  defexception [:reason, :uri, :details, :output, message: "schema compilation failed"]

  @impl Exception
  def exception(options) do
    reason = Keyword.fetch!(options, :reason)
    uri = Keyword.get(options, :uri)

    %__MODULE__{
      reason: reason,
      uri: uri,
      details: Keyword.get(options, :details),
      output: Keyword.get(options, :output),
      message: Keyword.get(options, :message, default_message(reason, uri))
    }
  end

  defp default_message(reason, nil), do: "schema compilation failed: #{reason}"
  defp default_message(reason, uri), do: "schema compilation failed at #{uri}: #{reason}"
end
