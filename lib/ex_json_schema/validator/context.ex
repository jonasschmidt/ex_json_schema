defmodule ExJsonSchema.Validator.Context do
  alias ExJsonSchema.Validator.Result

  defstruct path: "#", result: Result.new()

  def new do
    %__MODULE__{}
  end

  def append_path(%__MODULE__{path: p1} = context, p2) do
    %__MODULE__{context | path: p1 <> p2}
  end

  def path(%__MODULE__{path: path}), do: path
end
