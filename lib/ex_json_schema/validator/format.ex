defmodule ExJsonSchema.Validator.Format do
  alias ExJsonSchema.Validator
  alias ExJsonSchema.Validator.Error
  alias ExJsonSchema.Schema.Root

  @formats %{
    "email" =>
      ~r<^[\w!#$%&'*+/=?`{|}~^-]+(?:\.[\w!#$%&'*+/=?`{|}~^-]+)*@(?:[A-Z0-9-]+\.)+[A-Z]{2,}$>i,
    "hostname" => ~r/^((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}$/i,
    "ipv4" =>
      ~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/,
    "ipv6" =>
      ~r/^(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$/i
  }

  @spec validate(Root.t(), String.t(), ExJsonSchema.data()) :: Validator.errors()
  def validate(root = %Root{}, format, data) when is_binary(data) do
    do_validate(root, format, data)
  end

  def validate(%Root{}, _, _), do: []

  defp do_validate(%Root{}, format = "date-time", data) do
    case DateTime.from_iso8601(data) do
      {:ok, _, _} -> []
      {:error, _} -> [%Error{error: %Error.Format{expected: format}, path: ""}]
    end
  end

  defp do_validate(%Root{}, format, data)
       when format in ["email", "hostname", "ipv4", "ipv6"] do
    case Regex.match?(@formats[format], data) do
      true -> []
      false -> [%Error{error: %Error.Format{expected: format}, path: ""}]
    end
  end

  defp do_validate(%Root{custom_format_validator: nil}, format, data) do
    case Application.fetch_env(:ex_json_schema, :custom_format_validator) do
      :error -> []
      {:ok, validator = {_mod, _fun}} -> validate_with_custom_validator(validator, format, data)
    end
  end

  defp do_validate(%Root{custom_format_validator: validator = {_mod, _fun}}, format, data) do
    validate_with_custom_validator(validator, format, data)
  end

  defp validate_with_custom_validator({mod, fun}, format, data) do
    case apply(mod, fun, [format, data]) do
      true -> []
      false -> [%Error{error: %Error.Format{expected: format}, path: ""}]
    end
  end
end
