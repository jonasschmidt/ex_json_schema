schema =
  ExJsonSchema.compile!(
    %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "type" => "object",
      "properties" => %{
        "users" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "required" => ["id", "name"],
            "properties" => %{
              "id" => %{"type" => "integer"},
              "name" => %{"type" => "string", "minLength" => 2}
            },
            "unevaluatedProperties" => false
          }
        }
      },
      "unevaluatedProperties" => false
    },
    validate_schema: false
  )

instance = %{
  "users" =>
    for index <- 1..20 do
      %{"id" => index, "name" => if(rem(index, 5) == 0, do: "", else: "User #{index}")}
    end
}

iterations = 500

for mode <- [:flag, :basic, :detailed, :verbose] do
  {microseconds, output} =
    :timer.tc(fn ->
      Enum.reduce(1..iterations, nil, fn _, _ ->
        ExJsonSchema.validate(instance, schema, output: mode)
      end)
    end)

  bytes = output |> :erlang.term_to_binary() |> byte_size()
  average = Float.round(microseconds / iterations, 1)
  IO.puts("#{mode}: #{average} µs/validation, #{bytes} encoded bytes")
end
