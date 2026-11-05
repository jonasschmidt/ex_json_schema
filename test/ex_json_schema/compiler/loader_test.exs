defmodule ExJsonSchema.Compiler.LoaderTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler.Loader
  alias ExJsonSchema.Compiler.Options
  alias ExJsonSchema.Compiler.Resource

  test "loads every retrieval URI once while traversing cyclic graphs" do
    {:ok, calls} = Agent.start_link(fn -> %{} end)

    schemas = %{
      "https://example.com/b" => %{"$ref" => "c"},
      "https://example.com/c" => %{
        "allOf" => [
          %{"$ref" => "b"},
          %{"$ref" => "b#"}
        ]
      }
    }

    resolver = fn uri ->
      Agent.update(calls, &Map.update(&1, uri, 1, fn count -> count + 1 end))
      Map.fetch(schemas, uri)
    end

    options = %Options{
      retrieval_uri: "https://example.com/a",
      resolver: resolver,
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(%{"$ref" => "b"}, options)

    assert Agent.get(calls, & &1) == %{
             "https://example.com/b" => 1,
             "https://example.com/c" => 1
           }

    assert Map.keys(graph.resources) |> Enum.sort() ==
             [
               "https://example.com/a",
               "https://example.com/b",
               "https://example.com/c"
             ]
  end

  test "preloaded resources take precedence over the resolver" do
    resolver = fn _uri -> flunk("resolver must not be called") end

    options = %Options{
      retrieval_uri: "https://example.com/root",
      resources: %{"https://example.com/preloaded" => %{"type" => "integer"}},
      resolver: resolver,
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(%{"$ref" => "preloaded"}, options)

    assert %Resource{schema: %{"type" => "integer"}} =
             graph.resources["https://example.com/preloaded"]
  end

  test "a long acyclic resource chain terminates after each URI is loaded once" do
    {:ok, calls} = Agent.start_link(fn -> 0 end)

    resolver = fn uri ->
      Agent.update(calls, &(&1 + 1))
      index = uri |> String.split("/") |> List.last() |> String.to_integer()

      if index == 100 do
        {:ok, true}
      else
        {:ok, %{"$ref" => Integer.to_string(index + 1)}}
      end
    end

    options = %Options{
      retrieval_uri: "https://example.com/chain/0",
      resolver: resolver,
      validate_schema: false
    }

    assert {:ok, graph} = Loader.load(%{"$ref" => "1"}, options)
    assert Agent.get(calls, & &1) == 100
    assert map_size(graph.resources) == 101
  end

  test "loads bundled meta-schemas without a resolver" do
    options = %Options{
      retrieval_uri: "https://example.com/root",
      validate_schema: false
    }

    schema = %{"$ref" => "http://json-schema.org/draft-07/schema#"}

    assert {:ok, graph} = Loader.load(schema, options)

    assert %Resource{
             schema: %{
               "$id" => "http://json-schema.org/draft-07/schema#"
             }
           } = graph.resources["http://json-schema.org/draft-07/schema"]
  end
end
