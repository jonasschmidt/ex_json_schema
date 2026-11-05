defmodule ExJsonSchema.Compiler.Callbacks do
  @moduledoc false

  # Invokes user-provided resolvers, format validators, and content decoders
  # while normalizing failures into library errors.

  alias ExJsonSchema.CompileError

  @type callback :: (term() -> term()) | {module(), atom()}

  @spec resolve(callback() | nil, String.t()) ::
          {:ok, ExJsonSchema.data()} | {:error, CompileError.t()}
  def resolve(nil, uri) do
    resolver_error(uri, :not_configured, "no resolver was configured")
  end

  def resolve(resolver, uri) do
    case safely_invoke(resolver, uri) do
      {:returned, {:ok, schema}} when is_map(schema) or is_boolean(schema) ->
        {:ok, schema}

      {:returned, {:ok, value}} ->
        resolver_error(uri, {:invalid_schema, value}, "resolver returned a non-schema value")

      {:returned, {:error, reason}} ->
        resolver_error(uri, reason, "resolver could not load the resource")

      {:returned, value} ->
        resolver_error(
          uri,
          {:invalid_return, value},
          "resolver must return {:ok, schema} or {:error, reason}"
        )

      {:raised, kind, reason} ->
        resolver_error(uri, {:callback_raised, kind, reason}, "resolver callback raised")
    end
  end

  @spec validate_format(callback(), String.t(), term()) ::
          :ok | {:error, map()}
  def validate_format(validator, name, value) do
    case safely_invoke(validator, value) do
      {:returned, :ok} ->
        :ok

      {:returned, {:error, reason}} ->
        {:error, %{format: name, reason: reason}}

      {:returned, result} ->
        {:error, %{format: name, reason: {:invalid_return, result}}}

      {:raised, kind, reason} ->
        {:error, %{format: name, reason: {:callback_raised, kind, reason}}}
    end
  end

  @spec decode_content(callback() | nil, String.t()) ::
          {:ok, ExJsonSchema.data()} | {:error, map()}
  def decode_content(nil, _encoded), do: {:error, %{reason: :not_configured}}

  def decode_content(decoder, encoded) do
    case safely_invoke(decoder, encoded) do
      {:returned, {:ok, decoded}} ->
        {:ok, decoded}

      {:returned, {:error, reason}} ->
        {:error, %{reason: reason}}

      {:returned, result} ->
        {:error, %{reason: {:invalid_return, result}}}

      {:raised, kind, reason} ->
        {:error, %{reason: {:callback_raised, kind, reason}}}
    end
  end

  defp safely_invoke(callback, argument) do
    {:returned, invoke(callback, argument)}
  rescue
    error -> {:raised, :error, error}
  catch
    kind, reason -> {:raised, kind, reason}
  end

  defp invoke(callback, argument) when is_function(callback, 1), do: callback.(argument)
  defp invoke({module, function}, argument), do: apply(module, function, [argument])

  defp resolver_error(uri, details, message) do
    {:error,
     %CompileError{
       reason: :resolver,
       uri: uri,
       details: details,
       message: "#{message}: #{uri}"
     }}
  end
end
