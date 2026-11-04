defmodule ExJsonSchema.Compiler.OptionsTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Options

  test "parses all explicit compilation capabilities" do
    resolver = fn _uri -> {:ok, true} end
    format = fn _value -> :ok end
    decoder = fn _encoded -> {:ok, %{}} end

    assert {:ok,
            %Options{
              retrieval_uri: "https://example.com/root",
              resources: %{
                "https://example.com/other" => %{"type" => "integer"}
              },
              resolver: ^resolver,
              formats: %{"custom" => ^format},
              content_decoder: ^decoder,
              validate_schema: false
            }} =
             Options.parse(
               retrieval_uri: "https://example.com/root",
               resources: %{"https://example.com/other" => %{"type" => "integer"}},
               resolver: resolver,
               formats: %{"custom" => format},
               content_decoder: decoder,
               validate_schema: false
             )
  end

  test "uses explicit, inert defaults" do
    assert {:ok,
            %Options{
              retrieval_uri: nil,
              resources: %{},
              resolver: nil,
              formats: %{},
              content_decoder: nil,
              validate_schema: true
            }} = Options.parse([])
  end

  test "accepts module and function callback tuples" do
    assert {:ok,
            %Options{
              resolver: {Resolver, :resolve},
              formats: %{"custom" => {Formats, :validate}},
              content_decoder: {Decoder, :decode}
            }} =
             Options.parse(
               resolver: {Resolver, :resolve},
               formats: %{"custom" => {Formats, :validate}},
               content_decoder: {Decoder, :decode}
             )
  end

  test "merges application defaults with explicit options taking precedence" do
    assert {:ok,
            %Options{
              resolver: {Explicit, :resolve},
              validate_schema: false
            }} =
             Options.parse(
               [resolver: {Explicit, :resolve}],
               resolver: {Default, :resolve},
               validate_schema: false
             )
  end

  test "rejects unknown options" do
    assert {:error,
            %CompileError{
              reason: :invalid_option,
              details: %{option: :options}
            }} = Options.parse(network: true)
  end

  test "rejects malformed option values with the option name" do
    invalid_options = [
      retrieval_uri: 123,
      resources: [{"https://example.com", true}],
      resolver: fn _, _ -> :ok end,
      formats: %{"date" => :not_a_function},
      content_decoder: {Jason, "decode"},
      validate_schema: :yes
    ]

    for {name, value} <- invalid_options do
      assert {:error,
              %CompileError{
                reason: :invalid_option,
                details: %{option: ^name}
              }} = Options.parse([{name, value}])
    end
  end

  test "rejects resource values that are not decoded schemas" do
    assert {:error, %CompileError{details: %{option: :resources}}} =
             Options.parse(resources: %{"https://example.com/schema" => "raw JSON"})
  end

  test "rejects retrieval URI fragments" do
    assert {:error, %CompileError{details: %{option: :retrieval_uri}}} =
             Options.parse(retrieval_uri: "https://example.com/schema#fragment")
  end

  test "accepts an opaque URN retrieval URI" do
    assert {:ok,
            %Options{
              retrieval_uri: "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed"
            }} =
             Options.parse(retrieval_uri: "urn:uuid:deadbeef-1234-ffff-ffff-4321feebdaed")
  end
end
