defmodule ExJsonSchema.Validator.Format do
  @moduledoc """
  `ExJsonSchema.Validator` implementation for `"format"` attributes.

  See:
  https://tools.ietf.org/html/draft-fge-json-schema-validation-00#section-7
  https://tools.ietf.org/html/draft-wright-json-schema-validation-01#section-8
  https://tools.ietf.org/html/draft-handrews-json-schema-validation-01#section-7
  """

  alias ExJsonSchema.Schema.Root
  alias ExJsonSchema.Validator

  @behaviour ExJsonSchema.Validator

  @date_regex ~r/^(\d\d\d\d)-(\d\d)-(\d\d)$/
  @date_time_regex ~r/^(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9]):([0-5][0-9]):([0-5][0-9])(\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])?$/
  @email_regex ~r<^[\w!#$%&'*+/=?`{|}~^-]+(?:\.[\w!#$%&'*+/=?`{|}~^-]+)*@(?:[A-Z0-9-]+\.)+[A-Z]{2,6}$>i
  @hostname_regex ~r/^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[-0-9a-z]{0,61}[0-9a-z])?)*$/i
  @ipv4_regex ~r/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
  @ipv6_regex ~r/^(?:(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}|(?=(?:[A-F0-9]{0,4}:){0,7}[A-F0-9]{0,4}$)(([0-9A-F]{1,4}:){1,7}|:)((:[0-9A-F]{1,4}){1,7}|:)|(?:[A-F0-9]{1,4}:){7}:|:(:[A-F0-9]{1,4}){7})$/i
  @json_pointer_regex ~r<^(?:\/(?:[^~/]|~0|~1)*)*$>
  @time_regex ~r<^((?=[a-z0-9-]{1,63}\.)(xn--)?[a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,63}$>i
  @relative_json_pointer_regex ~r<^(?:0|[1-9][0-9]*)(?:#|(?:\/(?:[^~/]|~0|~1)*)*)$>;
  @uri_reference_regex ~r/^(?:(?:[a-z][a-z0-9+-.]*:)?\/?\/)?(?:[^\\\s#][^\s#]*)?(?:#[^\\\s]*)?$/i
  @uri_regex ~r/^(?:[a-z][a-z0-9+-.]*:)(?:\/?\/)?[^\s]*$/i
  @uri_template_regex ~r<^(?:(?:[^\x00-\x20"'\<\>%\\^`{|}]|%[0-9a-f]{2})|\{[+\#./;?&=,!@|]?(?:[a-z0-9_]|%[0-9a-f]{2})+(?::[1-9][0-9]{0,3}|\*)?(?:,(?:[a-z0-9_]|%[0-9a-f]{2})+(?::[1-9][0-9]{0,3}|\*)?)*\})*$>i
  @z_anchor ~r/[^\\]\\Z/

  @impl ExJsonSchema.Validator
  @spec validate(Root.t(), ExJsonSchema.data(), {String.t(), ExJsonSchema.data()}, ExJsonSchema.data()) :: Validator.errors_with_list_paths
  def validate(_, _, {"format", format}, data) do
    do_validate(format, data)
  end

  def validate(_, _, _, _) do
    []
  end

  defp do_validate("date", data) do
    validate_with_regex(data, @date_regex, fn data -> "Expected #{inspect(data)} to be a valid date." end)
  end

  defp do_validate("date-time", data) do
    validate_with_regex(data, @date_time_regex, fn data -> "Expected #{inspect(data)} to be a valid ISO 8601 date-time." end)
  end

  defp do_validate("time", data) do
    validate_with_regex(data, @time_regex, fn data -> "Expected #{inspect(data)} to be a valid time." end)
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

  defp do_validate("uri", data) do
    validate_with_regex(data, @uri_regex, fn data -> "Expected #{inspect(data)} to be a uri." end) ++
    validate_with_regex(data, @uri_reference_regex, fn data -> "Expected #{inspect(data)} to be a uri reference." end)
  end

  defp do_validate("uri-reference", data) do
    validate_with_regex(data, @uri_reference_regex, fn data -> "Expected #{inspect(data)} to be a uri reference." end)
  end

  defp do_validate("uri-template", data) do
    validate_with_regex(data, @uri_template_regex, fn data -> "Expected #{inspect(data)} to be a uri template." end)
  end

  defp do_validate("json-pointer", data) do
    validate_with_regex(data, @json_pointer_regex, fn data -> "Expected #{inspect(data)} to be a json pointer." end)
  end

  defp do_validate("relative-json-pointer", data) do
    validate_with_regex(data, @relative_json_pointer_regex, fn data -> "Expected #{inspect(data)} to be a json pointer." end)
  end

  defp do_validate("regex", data) do
    if Regex.match?(@z_anchor, data) do
      [{"Regex does not support Z anchor", []}]
    else
      []
    end
  end

  defp do_validate(_, _) do
    []
  end

  defp validate_with_regex(data, regex, failure_message_fun) do
    if Regex.match?(regex, data) do
      []
    else
      [{failure_message_fun.(data), []}]
    end
  end
end
