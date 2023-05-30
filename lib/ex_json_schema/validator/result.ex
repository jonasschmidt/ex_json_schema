defmodule ExJsonSchema.Validator.Result do
  alias ExJsonSchema.Validator.Error

  defstruct errors: [], annotations: %{}

  def new do
    %__MODULE__{}
  end

  def with_errors(errors) do
    %__MODULE__{errors: errors}
  end

  def merge(%__MODULE__{errors: e1, annotations: a1}, %__MODULE__{errors: e2, annotations: a2}) do
    %__MODULE__{errors: e1 ++ e2, annotations: Map.merge(a1, a2)}
  end

  def add_error(%__MODULE__{errors: errors} = result, error) do
    %__MODULE__{result | errors: [error | errors]}
  end

  def add_annotation(%__MODULE__{annotations: annotations} = result, name, annotation) do
    %__MODULE__{result | annotations: Map.put(annotations, name, annotation)}
  end

  def ensure_paths(%__MODULE__{errors: errors} = result, path) do
    errors =
      errors
      |> Enum.map(fn
        %Error{path: nil} = error -> %{error | path: path}
        error -> error
      end)

    %__MODULE__{result | errors: errors}
  end

  def valid?(%__MODULE__{errors: []}), do: true
  def valid?(%__MODULE__{}), do: false
end
