use Mix.Config

defmodule CustomFormatValidator do
  def validate(_format, _data), do: true
end

config :ex_json_schema,
  decode_json: fn json -> Poison.decode(json) end,
  remote_schema_resolver: fn url -> HTTPoison.get!(url).body |> Poison.decode!() end,
  custom_format_validator: {CustomFormatValidator, :validate}
