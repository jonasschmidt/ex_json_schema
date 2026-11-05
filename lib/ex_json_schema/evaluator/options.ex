defmodule ExJsonSchema.Evaluator.Options do
  @moduledoc false

  # Validates the public validation keyword list and gives evaluator internals
  # a stable, typed representation of output and assertion behavior.

  @type t :: %__MODULE__{
          output: ExJsonSchema.output_format(),
          assert_formats?: boolean() | :default
        }

  @outputs [:flag, :basic, :detailed, :verbose]
  @keys [:output, :assert_formats?]

  defstruct output: :basic,
            assert_formats?: :default

  @spec parse!(keyword()) :: t()
  def parse!(options) do
    unless Keyword.keyword?(options) do
      raise ArgumentError, "validation options must be a keyword list"
    end

    case Keyword.keys(options) -- @keys do
      [] -> :ok
      unknown -> raise ArgumentError, "unknown validation options: #{inspect(unknown)}"
    end

    output = Keyword.get(options, :output, :basic)

    unless output in @outputs do
      raise ArgumentError, "output must be :flag, :basic, :detailed, or :verbose"
    end

    assert_formats? =
      case Keyword.fetch(options, :assert_formats?) do
        :error -> :default
        {:ok, assert_formats?} when is_boolean(assert_formats?) -> assert_formats?
        {:ok, _assert_formats?} -> raise ArgumentError, "assert_formats? must be a boolean"
      end

    %__MODULE__{
      output: output,
      assert_formats?: assert_formats?
    }
  end
end
