defmodule ExJsonSchema do
  @moduledoc """
  Compiles and validates decoded JSON Schemas for drafts 4, 6, 7, and 2020-12.

  Compilation eagerly loads every statically reachable schema resource.
  Compiled schemas are immutable and validation performs no resource-loading I/O.

  Compile once, then validate payloads with the reusable opaque handle:

      compiled =
        ExJsonSchema.compile!(%{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "type" => "integer"
        })

      ExJsonSchema.valid?(42, compiled)
      #=> true

      ExJsonSchema.validate("42", compiled, output: :flag)
      #=> %{"valid" => false}

  Compiled schemas and their validation plans are immutable data, so they can
  be built into a module and shipped in an Elixir release:

      defmodule MyApp.Schemas do
        @user ExJsonSchema.compile!(%{
          "$schema" => "https://json-schema.org/draft/2020-12/schema",
          "type" => "object",
          "properties" => %{"name" => %{"type" => "string"}}
        })

        def user, do: @user
      end
  """

  alias ExJsonSchema.CompiledSchema
  alias ExJsonSchema.Compiler
  alias ExJsonSchema.Compiler.Dialect
  alias ExJsonSchema.Compiler.Location
  alias ExJsonSchema.Compiler.Resource

  @type data :: nil | boolean | number | String.t() | [data] | object
  @type object :: %{String.t() => data}
  @type schema :: object() | boolean()
  @type callback :: function() | {module(), atom()}

  @type output_format :: :flag | :basic | :detailed | :verbose
  @type compile_option ::
          {:retrieval_uri, String.t()}
          | {:resources, %{String.t() => schema()}}
          | {:resolver, (String.t() -> {:ok, schema()} | {:error, term()}) | {module(), atom()}}
          | {:formats,
             %{
               String.t() => (term() -> :ok | {:error, term()}) | {module(), atom()}
             }}
          | {:content_decoder, (String.t() -> {:ok, data()} | {:error, term()}) | {module(), atom()}}
          | {:validate_schema, boolean()}
  @type validation_option ::
          {:output, output_format()}
          | {:assert_formats?, boolean()}

  @doc """
  Compiles a decoded object or boolean schema into an immutable resource graph.

  Options override matching application defaults configured directly under
  `:ex_json_schema`. Callback options accept unary functions or
  `{module, function}` tuples.
  """
  @spec compile(schema(), [compile_option()]) ::
          {:ok, CompiledSchema.t()} | {:error, ExJsonSchema.CompileError.t()}
  defdelegate compile(schema, options \\ []), to: Compiler

  @doc """
  Compiles a schema or raises `ExJsonSchema.CompileError`.
  """
  @spec compile!(schema(), [compile_option()]) :: CompiledSchema.t()
  defdelegate compile!(schema, options \\ []), to: Compiler

  @doc """
  Validates `instance` and returns standardized JSON Schema output.

  The default output format is `:basic`.
  """
  @spec validate(data(), CompiledSchema.t(), [validation_option()]) :: map()
  def validate(instance, compiled, options \\ []) do
    validate_options!(options)
    ExJsonSchema.Evaluator.validate(instance, compiled, options)
  end

  @doc """
  Returns only whether `instance` is valid.
  """
  @spec valid?(data(), CompiledSchema.t(), [validation_option()]) :: boolean()
  def valid?(instance, compiled, options \\ []) do
    validate_options!(options)
    ExJsonSchema.Evaluator.valid?(instance, compiled, options)
  end

  @doc """
  Looks up a pointer, anchor, or resource URI in the compiled graph.

  Returns a compiled schema handle scoped to that location without performing
  I/O or recompiling the schema.
  """
  @spec fetch_schema(CompiledSchema.t(), String.t()) ::
          {:ok, CompiledSchema.t()} | {:error, ExJsonSchema.ReferenceError.t()}
  defdelegate fetch_schema(compiled, reference), to: Compiler

  @doc """
  Looks up a schema in the compiled graph or raises `ExJsonSchema.ReferenceError`.
  """
  @spec fetch_schema!(CompiledSchema.t(), String.t()) :: CompiledSchema.t()
  defdelegate fetch_schema!(compiled, reference), to: Compiler

  @doc """
  Returns the canonical dialect identifier at the handle's entry point.
  """
  @spec dialect(CompiledSchema.t()) :: String.t()
  def dialect(compiled) do
    %Location{resource: resource_uri} = CompiledSchema.entrypoint(compiled)

    %Resource{dialect: %Dialect{id: dialect_id}} =
      Map.fetch!(CompiledSchema.resources(compiled), resource_uri)

    dialect_id
  end

  @doc """
  Returns the entry point's canonical schema location when one is available.
  """
  @spec schema_location(CompiledSchema.t()) :: String.t()
  def schema_location(compiled) do
    entrypoint = CompiledSchema.entrypoint(compiled)
    Location.absolute_uri(entrypoint) || Location.pointer(entrypoint)
  end

  @doc """
  Returns sorted canonical resource identifiers in the compiled graph.
  """
  @spec resource_uris(CompiledSchema.t()) :: [String.t()]
  def resource_uris(compiled) do
    compiled
    |> CompiledSchema.resources()
    |> Map.keys()
    |> Enum.reject(&(&1 == ""))
    |> Enum.sort()
  end

  defp validate_options!(options) when is_list(options) do
    unless Keyword.keyword?(options) do
      raise ArgumentError, "validation options must be a keyword list"
    end

    unknown = Keyword.keys(options) -- [:output, :assert_formats?]

    if unknown != [] do
      raise ArgumentError, "unknown validation options: #{inspect(unknown)}"
    end

    unless Keyword.get(options, :output, :basic) in [:flag, :basic, :detailed, :verbose] do
      raise ArgumentError, "output must be :flag, :basic, :detailed, or :verbose"
    end

    unless Keyword.get(options, :assert_formats?, false) in [true, false] do
      raise ArgumentError, "assert_formats? must be a boolean"
    end

    :ok
  end

  defp validate_options!(_options) do
    raise ArgumentError, "validation options must be a keyword list"
  end
end
