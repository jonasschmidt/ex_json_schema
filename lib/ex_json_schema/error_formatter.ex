defmodule ExJsonSchema.ErrorFormatter do
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

  defp format_error(full_path, %Error.OneOf{invalid: [], valid_indices: valid_indices}) do
    {
      full_path,
      "Expected exactly one of the schemata to match, " <>
      "but the schemata at the following indexes did: " <>
      "#{Enum.join(valid_indices, ", ")}."
    }
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

  defp format_error(full_path, %Error.Type{expected: expected, actual: actual}) do
    {full_path, "Type mismatch. Expected #{expected} but got #{actual}"}
  end

  defp format_error(full_path, %Error.MinProperties{expected: expected, actual: actual}) do
    {full_path, "Expected a minimum of #{expected} properties but got #{actual}"}
  end

  defp format_error(full_path, %Error.MaxProperties{expected: expected, actual: actual}) do
    {full_path, "Expected a maximum of #{expected} properties but got #{actual}"}
  end

  defp format_error(full_path, %Error.Required{missing: [missing]}) do
    {full_path, "Required property #{missing} was not present"}
  end

  defp format_error(full_path, %Error.Required{missing: missing}) do
    {full_path, "Required properties #{Enum.join(missing, ",")} were not present"}
  end

  defp format_error(full_path, %Error.Minimum{expected: expected, exclusive?: exclusive?}) do
    {full_path, "Expected value to be #{if exclusive?, do: ">", else: ">="} #{expected}"}
  end

  defp format_error(full_path, %Error.Maximum{expected: expected, exclusive?: exclusive?}) do
    {full_path, "Expected value to be #{if exclusive?, do: "<", else: "<="} #{expected}"}
  end

  defp format_error(full_path, %Error.Pattern{expected: expected}) do
    {full_path, "String does not match pattern #{inspect(expected)}"}
  end

  defp format_error(full_path, %Error.MinLength{expected: expected, actual: actual}) do
    {full_path, "Expected value to have a minimum length of #{expected} but was #{actual}"}
  end

  defp format_error(full_path, %Error.MaxLength{expected: expected, actual: actual}) do
    {full_path, "Expected value to have a maximum length of #{expected} but was #{actual}"}
  end

  defp format_error(full_path, %Error.MultipleOf{expected: expected}) do
    {full_path, "Expected value to be a multiple of #{expected}"}
  end

  defp format_error(full_path, %Error.Enum{}) do
    {full_path, "Value is not allowed in enum"}
  end

  defp format_error(full_path, %Error.MinItems{expected: expected, actual: actual}) do
    {full_path, "Expected a minimum of #{expected} items but got #{actual}"}
  end

  defp format_error(full_path, %Error.MaxItems{expected: expected, actual: actual}) do
    {full_path, "Expected a maximum of #{expected} items but got #{actual}"}
  end

  defp format_error(full_path, %Error.UniqueItems{}) do
    {full_path, "Expected items to be unique but they were not"}
  end

  defp format_error(full_path, %Error.Format{expected: "date-time"}) do
    {full_path, "Expected value to be a valid ISO 8601 date-time"}
  end

  defp format_error(full_path, %Error.Format{expected: "email"}) do
    {full_path, "Expected value to be an email address"}
  end

  defp format_error(full_path, %Error.Format{expected: "hostname"}) do
    {full_path, "Expected value to be a hostname"}
  end

  defp format_error(full_path, %Error.Format{expected: "ipv4"}) do
    {full_path, "Expected value to be an IPv4 address"}
  end

  defp format_error(full_path, %Error.Format{expected: "ipv6"}) do
    {full_path, "Expected value to be an IPv6 address"}
  end

  defp format_error(full_path, %Error.AdditionalItems{additional_indices: additional_indices}) do
    {full_path, "Schema does not allow additional items, check indices #{Enum.join(additional_indices, ", ")}"}
  end

  defp format_error(full_path, %Error.Dependencies{property: property, missing: missing}) do
    {full_path, "Property #{property} depends on #{missing} to be present but it was not"}
  end

  defp format_error(full_path, %Error.AdditionalProperties{}) do
    {full_path, "Schema does not allow additional properties"}
  end

  defp format_error(full_path, %Error.Not{}) do
    {full_path, "Expected schema not to match but it did"}
  end
end
