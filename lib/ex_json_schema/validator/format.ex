defmodule NExJsonSchema.Validator.Format do
  alias NExJsonSchema.Validator

  @date_regex ~r/^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))?)?$/
  @date_time_regex ~r/^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/
  @email_regex ~r<^[\w!#$%&'*+/=?`{|}~^-]+(?:\.[\w!#$%&'*+/=?`{|}~^-]+)*@(?:[A-Z0-9-]+\.)+[A-Z]{2,6}$>i
  @hostname_regex ~r/^((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}$/i
  @ipv4_regex ~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
  @ipv6_regex ~r/^(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$/i

  @spec validate(String.t(), String.t()) :: Validator.errors_with_list_paths()
  def validate(format, data) when is_binary(data) do
    do_validate(format, data)
  end

  @spec validate(String.t(), NExJsonSchema.data()) :: []
  def validate(_, _), do: []

  defp do_validate("date-time", data) do
    validate_with_regex_result =
      validate_with_regex(data, @date_time_regex, fn data ->
        Validator.format_error(
          :datetime,
          "expected %{actual} to be a valid ISO 8601 date-time",
          pattern: Regex.source(@date_time_regex),
          actual: inspect(data)
        )
      end)

    case validate_with_regex_result do
      [] ->
        validate_date_existence("date-time", data, fn data ->
          Validator.format_error(
            :datetime,
            "expected %{actual} to be an existing date-time",
            actual: inspect(data)
          )
        end)

      error ->
        error
    end
  end

  defp do_validate("date", data) do
    validate_with_regex_result =
      validate_with_regex(data, @date_regex, fn data ->
        Validator.format_error(
          :date,
          "expected %{actual} to be a valid ISO 8601 date",
          pattern: Regex.source(@date_regex),
          actual: inspect(data)
        )
      end)

    case validate_with_regex_result do
      [] ->
        validate_date_existence("date", data, fn data ->
          Validator.format_error(
            :date,
            "expected %{actual} to be an existing date",
            actual: inspect(data)
          )
        end)

      error ->
        error
    end
  end

  defp do_validate("email", data) do
    validate_with_regex(data, @email_regex, fn data ->
      Validator.format_error(
        :email,
        "expected %{actual} to be an email address",
        pattern: Regex.source(@email_regex),
        actual: inspect(data)
      )
    end)
  end

  defp do_validate("hostname", data) do
    validate_with_regex(data, @hostname_regex, fn data ->
      Validator.format_error(
        :format,
        "expected %{actual} to be a host name",
        pattern: Regex.source(@hostname_regex),
        actual: inspect(data)
      )
    end)
  end

  defp do_validate("ipv4", data) do
    validate_with_regex(data, @ipv4_regex, fn data ->
      Validator.format_error(
        :format,
        "expected %{actual} to be an IPv4 address",
        pattern: Regex.source(@ipv4_regex),
        actual: inspect(data)
      )
    end)
  end

  defp do_validate("ipv6", data) do
    validate_with_regex(data, @ipv6_regex, fn data ->
      Validator.format_error(
        :format,
        "expected %{actual} to be an IPv6 address",
        pattern: Regex.source(@ipv6_regex),
        actual: inspect(data)
      )
    end)
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

  defp validate_date_existence("date-time", data, failure_message_fun) do
    case DateTime.from_iso8601(data) do
      {:ok, _, _} -> []
      {:error, _} -> [{failure_message_fun.(data), []}]
    end
  end

  defp validate_date_existence("date", data, failure_message_fun) do
    case Date.from_iso8601(data) do
      {:ok, _} -> []
      {:error, _} -> [{failure_message_fun.(data), []}]
    end
  end
end
