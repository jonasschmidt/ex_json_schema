use Mix.Config

defmodule CustomFormatValidator do
  def validate(_format, _data), do: true
end

config :ex_json_schema,
  decode_json: fn json -> Poison.decode(json) end,
  remote_schema_resolver: fn url ->
    case HTTPoison.get!(url) do
      %{status_code: 200, body: body} -> body |> Poison.decode!()
      %{status_code: 404} -> raise "Remote schema not found at #{url}"
    end
  end,
  custom_format_validator: {CustomFormatValidator, :validate}
