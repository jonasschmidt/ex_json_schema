defmodule ExJsonSchema.Schema do
  defmodule RemoteSchema do
    use HTTPoison.Base

    def process_url(url) do
      url
    end

    def process_response_body(body) do
      body |> Poison.Parser.parse!
    end
  end

  def resolve(schema = %{}) do
    schema
    |> Enum.map(&resolve_ref(&1))
    |> Enum.into(Map.new)
  end

  def resolve(non_schema), do: non_schema

  defp resolve_ref({key, value}) when is_map(value) do
    {key, resolve(value)}
  end

  defp resolve_ref({key, value}) when is_list(value) do
    {key, Enum.map(value, &resolve(&1))}
  end

  defp resolve_ref({"$ref", "#"}) do
    {"$ref", fn root -> {root, root} end}
  end

  defp resolve_ref({"$ref", url = "http" <> _}) do
    schema = RemoteSchema.get!(url).body |> resolve
    {"$ref", fn _ -> {schema, schema} end}
  end

  defp resolve_ref({"$ref", value}) do
    ["#" | keys] = String.split(value, "/")
    keys = Enum.map keys, fn key ->
      if Regex.match?(~r/^[0-9]$/, key) do
        fn :get, data, _ -> Enum.at(data, String.to_integer(key)) end
      else
        key
      end
    end
    {"$ref", fn root -> {root, get_in(root, keys)} end}
  end

  defp resolve_ref(tuple), do: tuple
end
