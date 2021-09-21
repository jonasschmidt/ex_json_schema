use Mix.Config

defmodule CustomFormatValidator do
  def validate(_format, _data), do: true
end

config :ex_component_schema,
  decode_json: fn json -> Poison.decode(json) end,
  remote_schema_resolver: fn url ->
    case SimpleHttp.get(url) do
      {:ok, res} -> res.body
      _ -> File.read!(Path.join("test/API-Component-Test-Suite/remotes/", url))
    end
    |> Poison.decode!()
  end,
  custom_format_validator: {CustomFormatValidator, :validate},
  on_comp_succeed: fn data -> IO.puts(inspect(data)) end
