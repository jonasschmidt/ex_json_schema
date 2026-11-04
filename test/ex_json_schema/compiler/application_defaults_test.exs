defmodule ExJsonSchema.Compiler.ApplicationDefaultsTest do
  use ExUnit.Case, async: false

  alias ExJsonSchema.CompileError

  @option_keys [
    :retrieval_uri,
    :resources,
    :resolver,
    :formats,
    :content_decoder,
    :validate_schema
  ]

  defmodule DefaultCallbacks do
    def resolve("https://example.com/integer"), do: {:ok, %{"type" => "integer"}}

    def validate_even(value) when is_binary(value) do
      if rem(String.length(value), 2) == 0, do: :ok, else: {:error, :odd_length}
    end

    def validate_even(_value), do: {:error, :not_a_string}
    def decode_json(encoded), do: Jason.decode(encoded)
  end

  defmodule ExplicitCallbacks do
    def resolve("https://example.com/integer"), do: {:ok, %{"type" => "string"}}
  end

  setup do
    previous =
      Map.new(@option_keys, fn key ->
        {key, Application.fetch_env(:ex_json_schema, key)}
      end)

    Enum.each(@option_keys, &Application.delete_env(:ex_json_schema, &1))

    on_exit(fn ->
      Enum.each(previous, fn
        {key, {:ok, value}} -> Application.put_env(:ex_json_schema, key, value)
        {key, :error} -> Application.delete_env(:ex_json_schema, key)
      end)
    end)
  end

  test "uses application compile options as global defaults" do
    Application.put_env(
      :ex_json_schema,
      :resolver,
      {DefaultCallbacks, :resolve}
    )

    Application.put_env(
      :ex_json_schema,
      :formats,
      %{"even-string" => {DefaultCallbacks, :validate_even}}
    )

    Application.put_env(
      :ex_json_schema,
      :content_decoder,
      {DefaultCallbacks, :decode_json}
    )

    Application.put_env(:ex_json_schema, :validate_schema, false)

    referenced = ExJsonSchema.compile!(%{"$ref" => "https://example.com/integer"})
    assert ExJsonSchema.valid?(1, referenced)
    refute ExJsonSchema.valid?("1", referenced)

    formatted = ExJsonSchema.compile!(%{"format" => "even-string"})
    assert ExJsonSchema.valid?("12", formatted)
    refute ExJsonSchema.valid?("1", formatted)

    content = ExJsonSchema.compile!(%{"contentMediaType" => "application/json"})
    assert ExJsonSchema.valid?("{}", content)
    refute ExJsonSchema.valid?("not-json", content)
  end

  test "explicit compile options override application defaults" do
    Application.put_env(:ex_json_schema, :resolver, {DefaultCallbacks, :resolve})
    Application.put_env(:ex_json_schema, :validate_schema, false)

    compiled =
      ExJsonSchema.compile!(
        %{"$ref" => "https://example.com/integer"},
        resolver: {ExplicitCallbacks, :resolve}
      )

    assert ExJsonSchema.valid?("value", compiled)
    refute ExJsonSchema.valid?(1, compiled)
  end

  test "reports malformed application compile options as structured errors" do
    Application.put_env(:ex_json_schema, :validate_schema, :sometimes)

    assert {:error,
            %CompileError{
              reason: :invalid_option,
              details: %{option: :validate_schema}
            }} = ExJsonSchema.compile(true)
  end
end
