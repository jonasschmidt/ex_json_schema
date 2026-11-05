defmodule ExJsonSchema.Compiler.LocationTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Pointer
  alias ExJsonSchema.Compiler.URI, as: SchemaURI

  test "JSON Pointer round-trips escaped and empty tokens" do
    segments = ["properties", "a/b", "~key", "", "snowman ☃"]
    pointer = "/properties/a~1b/~0key//snowman ☃"

    assert Pointer.encode(segments) == pointer
    assert Pointer.decode(pointer) == {:ok, segments}
    assert Pointer.decode("/~2") == :error
    assert Pointer.decode("not-a-pointer") == :error
  end

  test "schema and instance locations append without losing token identity" do
    location =
      "https://example.com/schema"
      |> Location.root()
      |> Location.child("properties")
      |> Location.child("a/b")
      |> Location.child(0)

    assert Location.pointer(location) == "/properties/a~1b/0"
    assert Location.fragment(location) == "#/properties/a~1b/0"
    assert Location.absolute_uri(location) == "https://example.com/schema#/properties/a~1b/0"
  end

  test "absolute locations encode URI fragment characters separately from pointer escaping" do
    location =
      Location.root("https://example.com/schema#old")
      |> Location.child("space and #")

    assert Location.absolute_uri(location) ==
             "https://example.com/schema#/space%20and%20%23"
  end

  test "relative URI resolution follows RFC 3986 examples" do
    base = "http://a/b/c/d;p?q"

    assert SchemaURI.resolve(base, "g") == {:ok, "http://a/b/c/g"}
    assert SchemaURI.resolve(base, "./g") == {:ok, "http://a/b/c/g"}
    assert SchemaURI.resolve(base, "../g") == {:ok, "http://a/b/g"}
    assert SchemaURI.resolve(base, "/g") == {:ok, "http://a/g"}
    assert SchemaURI.resolve(base, "?y") == {:ok, "http://a/b/c/d;p?y"}
    assert SchemaURI.resolve(base, "#s") == {:ok, "http://a/b/c/d;p?q#s"}
  end

  test "URI helpers normalize empty fragments and split encoded fragments" do
    assert SchemaURI.normalize("https://example.com/schema#") == "https://example.com/schema"

    assert SchemaURI.split_fragment("https://example.com/schema#/a%20b") ==
             {:ok, "https://example.com/schema", "/a b"}
  end

  test "URI helpers support opaque URNs consistently across Elixir versions" do
    urn = "urn:example:foo-bar-baz-qux?+CCResolve:cc=uk"

    assert SchemaURI.resolve("", urn) == {:ok, urn}
    assert SchemaURI.resolve(urn, "#/$defs/value") == {:ok, urn <> "#/$defs/value"}

    assert SchemaURI.split_fragment(urn <> "#named") ==
             {:ok, urn, "named"}
  end
end
