defmodule ExComponentSchema.Validator.Contains do
  @moduledoc """
  `ExComponentSchema.Validator` implementation for `"contains"` attributes.

  See:
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-6.14
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-6.4.6
  """

  alias ExComponentSchema.Validator
  alias ExComponentSchema.Validator.Error

  @behaviour ExComponentSchema.Validator

  @impl ExComponentSchema.Validator
  def validate(root = %{version: version}, _, {"contains", contains}, data, path)
      when version >= 6 do
    do_validate(root, contains, data, path)
  end

  def validate(_, _, _, _, _) do
    []
  end

  defp do_validate(_, _, [], _) do
    [%Error{error: %Error.Contains{empty?: true, invalid: []}}]
  end

  defp do_validate(root, contains, data, path) when is_list(data) do
    invalid =
      data
      |> Enum.with_index()
      |> Enum.reduce_while([], fn
        {data, index}, acc ->
          case Validator.validation_errors(root, contains, data, path <> "/#{index}") do
            [] -> {:halt, []}
            errors -> {:cont, [{errors, index} | acc]}
          end
      end)
      |> Enum.reverse()
      |> Validator.map_to_invalid_errors()

    case Enum.empty?(invalid) do
      true -> []
      false -> [%Error{error: %Error.Contains{empty?: false, invalid: invalid}}]
    end
  end

  defp do_validate(_, _, _, _) do
    []
  end
end
