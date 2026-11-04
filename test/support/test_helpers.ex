defmodule ExJsonSchema.Test.Support.TestHelpers do
  @suite_remotes_root Path.expand("../JSON-Schema-Test-Suite/remotes", __DIR__)
  @project_schemata_root Path.expand("schemata", __DIR__)
  @remote_base_uri "http://localhost:1234/"

  @spec load_schema_test(name :: String.t(), schema_tests_path :: String.t()) :: map | no_return
  def load_schema_test(name, schema_tests_path) do
    schema_tests_path
    |> Path.join(name <> ".json")
    |> File.read!()
    |> Jason.decode!()
  end

  @spec remote_schemas() :: %{String.t() => ExJsonSchema.data()}
  def remote_schemas do
    @suite_remotes_root
    |> Path.join("**/*.json")
    |> Path.wildcard()
    |> Map.new(fn path ->
      relative_path = Path.relative_to(path, @suite_remotes_root)
      {@remote_base_uri <> relative_path, decode_schema!(path)}
    end)
  end

  @spec remote_schema!(String.t()) :: ExJsonSchema.data() | no_return
  def remote_schema!(url) do
    %URI{host: "localhost", port: 1234, path: "/" <> relative_path} = URI.parse(url)

    case local_schema_path(relative_path) do
      {:ok, path} -> decode_schema!(path)
      :error -> raise "Remote schema not found at #{url}"
    end
  end

  defp local_schema_path(relative_path) do
    [
      Path.join(@project_schemata_root, relative_path),
      Path.join(@suite_remotes_root, relative_path)
    ]
    |> Enum.find_value(:error, fn path ->
      if File.regular?(path), do: {:ok, path}, else: false
    end)
  end

  defp decode_schema!(path) do
    path
    |> File.read!()
    |> Jason.decode!()
  end
end
