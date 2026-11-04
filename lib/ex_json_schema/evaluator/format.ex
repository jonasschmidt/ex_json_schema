defmodule ExJsonSchema.Evaluator.Format do
  @moduledoc false

  # Implements built-in JSON Schema format checks without performing external
  # I/O.

  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Evaluator.Format.URITemplate

  @hostname ~r/\A(?=.{1,253}\z)(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(?:\.(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?))*\z/
  @date ~r/\A(?<year>[0-9]{4})-(?<month>[0-9]{2})-(?<day>[0-9]{2})\z/
  @time ~r/\A(?<hour>[0-9]{2}):(?<minute>[0-9]{2}):(?<second>[0-9]{2})(?:\.[0-9]+)?(?<zone>[Zz]|[+-][0-9]{2}:[0-9]{2})\z/
  @uri_chars ~r/\A[A-Za-z0-9\-._~:\/?#\[\]@!$&'()*+,;=%]*\z/
  @atom ~S<[A-Za-z0-9!#$%&'*+\-/=?^_`{|}~]+>
  @email Regex.compile!(
           "\\A(?<local>\"(?:[\\x20-\\x21\\x23-\\x5B\\x5D-\\x7E]|\\\\[\\x20-\\x7E])*\"|#{@atom}(?:\\.#{@atom})*)@(?<domain>[^@]+)\\z"
         )
  @duration ~r/\AP(?:[0-9]+W|[0-9]+Y(?:[0-9]+M(?:[0-9]+D)?)?(?:T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S))?|[0-9]+M(?:[0-9]+D)?(?:T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S))?|[0-9]+D(?:T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S))?|T(?:[0-9]+H(?:[0-9]+M(?:[0-9]+S)?)?|[0-9]+M(?:[0-9]+S)?|[0-9]+S))\z/
  @uuid ~r/\A[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\z/

  @spec validate(String.t(), term()) :: :ok | :unknown | {:error, term()}
  def validate(_format, value) when not is_binary(value), do: :ok

  def validate("date", value), do: validity_result(valid_date?(value), :invalid_date)
  def validate("time", value), do: validity_result(valid_time?(value), :invalid_time)

  def validate("date-time", value) do
    case Regex.run(~r/\A(.{10})[Tt](.+)\z/, value, capture: :all_but_first) do
      [date, time] ->
        validity_result(valid_date?(date) and valid_time?(time), :invalid_date_time)

      _other ->
        {:error, :invalid_date_time}
    end
  end

  def validate("email", value), do: validity_result(valid_email?(value), :invalid_email)
  def validate("idn-email", _value), do: :unknown
  def validate("hostname", value), do: regex_result(@hostname, value)
  def validate("idn-hostname", _value), do: :unknown
  def validate("duration", value), do: regex_result(@duration, value)
  def validate("uuid", value), do: regex_result(@uuid, value)

  def validate("ipv4", value) do
    if Regex.match?(~r/\A(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}\z/, value) do
      inet_result(:inet.parse_ipv4strict_address(String.to_charlist(value)))
    else
      {:error, :einval}
    end
  end

  def validate("ipv6", value) do
    if String.contains?(value, ":") and not String.contains?(value, "%") do
      inet_result(:inet.parse_ipv6strict_address(String.to_charlist(value)))
    else
      {:error, :einval}
    end
  end

  def validate("regex", value) do
    case Regex.compile(value) do
      {:ok, _regex} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def validate("json-pointer", value) do
    case Pointer.decode(value) do
      {:ok, _segments} -> :ok
      :error -> {:error, :invalid_json_pointer}
    end
  end

  def validate("relative-json-pointer", value) do
    if Regex.match?(~r<\A(?:0|[1-9][0-9]*)(?:#|(?:/(?:[^~/]|~0|~1)*)*)\z>, value),
      do: :ok,
      else: {:error, :invalid_relative_json_pointer}
  end

  def validate("uri", value),
    do: validity_result(valid_uri_reference?(value, true), :invalid_uri)

  def validate("uri-reference", value),
    do: validity_result(valid_uri_reference?(value, false), :invalid_uri_reference)

  def validate("uri-template", value),
    do: validity_result(URITemplate.valid?(value), :invalid_uri_template)

  def validate(_format, _value), do: :unknown

  defp regex_result(regex, value) do
    if Regex.match?(regex, value), do: :ok, else: {:error, :invalid_format}
  end

  defp inet_result({:ok, _address}), do: :ok
  defp inet_result({:error, reason}), do: {:error, reason}

  defp valid_date?(value) do
    with %{"year" => year, "month" => month, "day" => day} <- Regex.named_captures(@date, value),
         {:ok, _date} <-
           Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day)) do
      true
    else
      _error -> false
    end
  end

  defp valid_email?(value) do
    with true <- String.printable?(value),
         %{"local" => local, "domain" => domain} <- Regex.named_captures(@email, value),
         true <- byte_size(local) <= 64,
         true <- valid_email_domain?(domain) do
      true
    else
      _error -> false
    end
  end

  defp valid_email_domain?("[" <> rest) do
    case String.split(rest, "]", parts: 2) do
      [address, ""] ->
        case address do
          <<"IPv6:", ipv6::binary>> ->
            match?({:ok, _}, :inet.parse_ipv6strict_address(String.to_charlist(ipv6)))

          <<"ipv6:", ipv6::binary>> ->
            match?({:ok, _}, :inet.parse_ipv6strict_address(String.to_charlist(ipv6)))

          ipv4 ->
            Regex.match?(~r/\A(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}\z/, ipv4) and
              match?({:ok, _}, :inet.parse_ipv4strict_address(String.to_charlist(ipv4)))
        end

      _other ->
        false
    end
  end

  defp valid_email_domain?(domain) do
    byte_size(domain) <= 253 and
      Enum.all?(
        String.split(domain, ".", trim: false),
        &Regex.match?(~r/\A[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\z/, &1)
      )
  end

  defp valid_time?(value) do
    with %{
           "hour" => hour,
           "minute" => minute,
           "second" => second,
           "zone" => zone
         } <- Regex.named_captures(@time, value),
         {hour, ""} <- Integer.parse(hour),
         {minute, ""} <- Integer.parse(minute),
         {second, ""} <- Integer.parse(second),
         true <- hour <= 23 and minute <= 59 and second <= 60,
         {:ok, offset} <- zone_offset(zone),
         true <- second < 60 or Integer.mod(hour * 60 + minute - offset, 1440) == 1439 do
      true
    else
      _error -> false
    end
  end

  defp zone_offset(zone) when zone in ["Z", "z"], do: {:ok, 0}

  defp zone_offset(<<sign, hour::binary-size(2), ":", minute::binary-size(2)>>) do
    hour = String.to_integer(hour)
    minute = String.to_integer(minute)

    if hour <= 23 and minute <= 59 do
      direction = if sign == ?+, do: 1, else: -1
      {:ok, direction * (hour * 60 + minute)}
    else
      :error
    end
  end

  defp valid_uri_reference?(value, absolute?) do
    with true <- String.valid?(value),
         true <- Regex.match?(@uri_chars, value),
         true <- valid_percent_encoding?(value),
         {:ok, %URI{scheme: scheme} = uri} <- URI.new(value),
         true <- not absolute? or valid_scheme?(scheme),
         true <- absolute? or valid_relative_first_segment?(value, scheme),
         true <- valid_authority_and_brackets?(value, uri) do
      true
    else
      _error -> false
    end
  end

  defp valid_percent_encoding?(value) do
    value
    |> String.replace(~r/%[0-9A-Fa-f]{2}/, "")
    |> Kernel.=~(~r/^[^%]*$/)
  end

  defp valid_scheme?(scheme) when is_binary(scheme),
    do: Regex.match?(~r/\A[A-Za-z][A-Za-z0-9+.-]*\z/, scheme)

  defp valid_scheme?(_scheme), do: false

  defp valid_relative_first_segment?(_value, scheme) when is_binary(scheme), do: true

  defp valid_relative_first_segment?(value, nil) do
    first_segment =
      value
      |> String.split(["/", "?", "#"], parts: 2)
      |> hd()

    not String.contains?(first_segment, ":")
  end

  defp valid_authority_and_brackets?(value, %URI{scheme: scheme}) do
    prefix = if scheme, do: scheme <> ":", else: ""
    remainder = String.replace_prefix(value, prefix, "")

    if String.starts_with?(remainder, "//") do
      authority =
        remainder
        |> String.replace_prefix("//", "")
        |> String.split(["/", "?", "#"], parts: 2)
        |> hd()

      valid_authority?(authority)
    else
      not String.contains?(remainder, ["[", "]"])
    end
  end

  defp valid_authority?(authority) do
    case String.split(authority, "@") do
      [host_port] -> valid_host_port?(host_port)
      [userinfo, host_port] -> valid_userinfo?(userinfo) and valid_host_port?(host_port)
      _too_many_parts -> false
    end
  end

  defp valid_userinfo?(userinfo),
    do: Regex.match?(~r/\A(?:[A-Za-z0-9\-._~!$&'()*+,;=:]|%[0-9A-Fa-f]{2})*\z/, userinfo)

  defp valid_host_port?("[" <> rest) do
    case String.split(rest, "]", parts: 2) do
      [address, suffix] ->
        valid_ipv6_literal?(address) and
          (suffix == "" or Regex.match?(~r/\A:[0-9]*\z/, suffix))

      _other ->
        false
    end
  end

  defp valid_host_port?(host_port) do
    case String.split(host_port, ":") do
      [host] -> valid_reg_name?(host)
      [host, port] -> valid_reg_name?(host) and Regex.match?(~r/\A[0-9]*\z/, port)
      _ipv6_without_brackets -> false
    end
  end

  defp valid_reg_name?(host),
    do: Regex.match?(~r/\A(?:[A-Za-z0-9\-._~!$&'()*+,;=]|%[0-9A-Fa-f]{2})*\z/, host)

  defp valid_ipv6_literal?(address),
    do: match?({:ok, _address}, :inet.parse_ipv6strict_address(String.to_charlist(address)))

  defp validity_result(true, _reason), do: :ok
  defp validity_result(false, reason), do: {:error, reason}
end
