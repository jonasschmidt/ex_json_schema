defmodule ExJsonSchema.Validator.Format do
  alias ExJsonSchema.Validator

  @date_time_regex ~r/^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/
  @email_regex ~r<^[\w!#$%&'*+/=?`{|}~^-]+(?:\.[\w!#$%&'*+/=?`{|}~^-]+)*@(?:[A-Z0-9-]+\.)+[A-Z]{2,}$>i
  @hostname_regex ~r/^((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}$/i
  @ipv4_regex ~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
  @ipv6_regex ~r/^(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$/i

  @spec validate(String.t, ExJsonSchema.data) :: Validator.errors_with_list_paths
  def validate(format, data) when is_binary(data) do
    do_validate(format, data)
  end

  def validate(_, _), do: []

  defp do_validate("date-time", data) do
    validate_with_regex(data, @date_time_regex, fn data -> "Expected #{inspect(data)} to be a valid ISO 8601 date-time." end)
  end

  defp do_validate("email", data) do
    validate_with_regex(data, @email_regex, fn data -> "Expected #{inspect(data)} to be an email address." end)
  end

  defp do_validate("hostname", data) do
    validate_with_regex(data, @hostname_regex, fn data -> "Expected #{inspect(data)} to be a host name." end)
  end

  defp do_validate("ipv4", data) do
    validate_with_regex(data, @ipv4_regex, fn data -> "Expected #{inspect(data)} to be an IPv4 address." end)
  end

  defp do_validate("ipv6", data) do
    validate_with_regex(data, @ipv6_regex, fn data -> "Expected #{inspect(data)} to be an IPv6 address." end)
  end

  defp do_validate(_, _) do
    []
  end

  defp validate_with_regex(data, regex, failure_message_fun) do
    case Regex.match?(regex, data) do
      true -> []
      false -> [{failure_message_fun.(data), []}]
    end
  end
end
