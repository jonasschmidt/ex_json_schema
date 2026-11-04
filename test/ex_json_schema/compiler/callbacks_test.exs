defmodule ExJsonSchema.Compiler.CallbacksTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.CompileError
  alias ExJsonSchema.Compiler.Callbacks

  defmodule TupleCallbacks do
    def resolve("https://example.com/schema"), do: {:ok, %{"type" => "string"}}
    def validate("valid"), do: :ok
    def validate(_value), do: {:error, :invalid}
    def decode("{}"), do: {:ok, %{}}
    def decode(_encoded), do: {:error, :invalid_json}
  end

  test "resolver contract accepts decoded schemas" do
    resolver = fn "https://example.com/schema" -> {:ok, %{"type" => "string"}} end

    assert {:ok, %{"type" => "string"}} =
             Callbacks.resolve(resolver, "https://example.com/schema")
  end

  test "callback contracts accept module and function tuples" do
    callback = {TupleCallbacks, :resolve}

    assert {:ok, %{"type" => "string"}} =
             Callbacks.resolve(callback, "https://example.com/schema")

    assert :ok = Callbacks.validate_format({TupleCallbacks, :validate}, "custom", "valid")

    assert {:error, %{format: "custom", reason: :invalid}} =
             Callbacks.validate_format({TupleCallbacks, :validate}, "custom", "invalid")

    assert {:ok, %{}} = Callbacks.decode_content({TupleCallbacks, :decode}, "{}")
  end

  test "resolver errors and exceptions become structured compile errors" do
    uri = "https://example.com/missing"

    assert {:error, %CompileError{reason: :resolver, uri: ^uri, details: :not_found}} =
             Callbacks.resolve(fn _ -> {:error, :not_found} end, uri)

    assert {:error,
            %CompileError{
              reason: :resolver,
              details: {:callback_raised, :error, %RuntimeError{message: "boom"}}
            }} = Callbacks.resolve(fn _ -> raise "boom" end, uri)
  end

  test "resolver rejects undocumented return values" do
    assert {:error,
            %CompileError{
              reason: :resolver,
              details: {:invalid_return, %{"type" => "string"}}
            }} =
             Callbacks.resolve(fn _ -> %{"type" => "string"} end, "https://example.com")
  end

  test "format callback contract accepts :ok and explicit errors" do
    assert :ok = Callbacks.validate_format(fn _ -> :ok end, "custom", "value")

    assert {:error, %{format: "custom", reason: :invalid}} =
             Callbacks.validate_format(fn _ -> {:error, :invalid} end, "custom", "value")
  end

  test "format callback exceptions and invalid returns are data" do
    assert {:error, %{reason: {:callback_raised, :error, %ArgumentError{}}}} =
             Callbacks.validate_format(fn _ -> raise ArgumentError end, "custom", "value")

    assert {:error, %{reason: {:invalid_return, true}}} =
             Callbacks.validate_format(fn _ -> true end, "custom", "value")
  end

  test "legacy decoder follows an explicit success and error contract" do
    assert {:ok, %{}} = Callbacks.decode_content(fn "{}" -> {:ok, %{}} end, "{}")

    assert {:error, %{reason: :invalid_json}} =
             Callbacks.decode_content(fn _ -> {:error, :invalid_json} end, "!")

    assert {:error, %{reason: :not_configured}} = Callbacks.decode_content(nil, "{}")
  end
end
