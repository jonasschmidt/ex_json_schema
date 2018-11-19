defmodule ExJsonSchema.Validator.Error.Formatter do
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error

  @spec format(:ok | {:error, Validator.errors()}, keyword()) :: nil | [{String.t(), String.t()}] | map()
  def format(validation_result, options \\ [])

  def format(:ok, _options), do: nil

  def format({:error, errors}, options) do
    errors =
      errors
      |> Enum.map(&format_error(["#"], &1))
      |> List.flatten()
      |> Enum.map(fn {path, msg} ->{path |> Enum.reverse() |> Enum.filter(&(String.length(&1) > 0)), msg} end)

    case Keyword.get(options, :output, :legacy) do
      :legacy -> format_legacy(errors)
      :json -> format_json(errors)
      _ -> raise ArgumentError, message: "output type not supported"
    end
  end

  defp format_legacy(errors) do
    Enum.map(errors, fn {path, msg} ->
      {
        msg,
        path
        |> Enum.filter(fn p -> p not in ["oneOf", "anyOf"] end)
        |> Enum.join("/")
      }
    end)
  end

  defp format_json(errors) do
    Enum.reduce(errors, %{}, fn {path, msg}, acc ->
      path
      |> Enum.drop_while(&(&1 == "#"))
      |> Enum.map(&Access.key(&1, %{}))
      |> Kernel.++([Access.key("errors", [])])
      |> (fn access -> update_in(acc, access, &List.insert_at(&1, -1, msg)) end).()
    end)
  end

  defp normalize_path("#/" <> path), do: path
  defp normalize_path("#" <> path), do: path
  defp normalize_path(path), do: path

  defp format_error(full_path, %Error{error: error, path: path}) do
    format_error([normalize_path(path) | full_path], error)
  end

  defp format_error(full_path, %Error.OneOf{invalid: invalid, valid_indices: []}) do
    Enum.map(invalid, &format_error(["oneOf" | full_path], &1))
  end

  defp format_error(full_path, %Error.AllOf{invalid: invalid}) do
    Enum.map(invalid, &format_error(["allOf" | full_path], &1))
  end

  defp format_error(full_path, %Error.AnyOf{invalid: invalid}) do
    Enum.map(invalid, &format_error(["anyOf" | full_path], &1))
  end

  defp format_error(full_path, %Error.InvalidAtIndex{index: index, errors: errors}) do
    Enum.map(errors, &format_error(["#{index}" | full_path], &1))
  end

  defp format_error(full_path, error), do: {full_path, to_string(error)}
end
