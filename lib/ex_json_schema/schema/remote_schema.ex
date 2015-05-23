defmodule ExJsonSchema.Schema.RemoteSchema do
  use HTTPoison.Base

  def process_response_body(body) do
    body |> Poison.Parser.parse!
  end
end
