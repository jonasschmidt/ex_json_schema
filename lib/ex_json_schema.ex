defmodule ExJsonSchema do
  @type json_path :: String.t()
  @type data :: nil | true | false | list | float | integer | String.t() | [data] | object
  @type object :: %{String.t() => data}
end
