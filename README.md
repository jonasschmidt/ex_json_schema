# Elixir JSON Schema validator

[![Build Status](https://travis-ci.org/jonasschmidt/ex_json_schema.svg?branch=master)](https://travis-ci.org/jonasschmidt/ex_json_schema) [![Coverage Status](https://coveralls.io/repos/jonasschmidt/ex_json_schema/badge.svg?branch=travis-elixir-version&service=github)](https://coveralls.io/github/jonasschmidt/ex_json_schema?branch=travis-elixir-version) [![Hex.pm](http://img.shields.io/hexpm/v/ex_json_schema.svg)](https://hex.pm/packages/ex_json_schema) [![Hex.pm](http://img.shields.io/hexpm/l/ex_json_schema.svg)](LICENSE)

A JSON Schema validator with full support for the draft 4 specification and zero dependencies. Passes the official [JSON Schema Test Suite](https://github.com/json-schema/JSON-Schema-Test-Suite).

## Installation

Add the project to your Mix dependencies in `mix.exs`:

```elixir
defp deps do
  [{:ex_json_schema, "~> 0.5.3"}]
end
```

Update your dependencies with:

```shell
$ mix deps.get
```

If you have remote schemata that need to be fetched at runtime, you have to register a function that takes a URL and returns a `Map` of the parsed JSON. So in your Mix configuration in `config/config.exs` you should have something like this:

```elixir
config :ex_json_schema,
  :remote_schema_resolver,
  fn url -> HTTPoison.get!(url).body |> Poison.decode! end
```

You do not have to do that for the official draft 4 meta-schema found at http://json-schema.org/draft-04/schema# though. That schema is bundled with the project and will work out of the box without any network calls.

### Resolving a schema

In this step the schema is validated against its meta-schema (the draft 4 schema definition) and `$ref`s are being resolved (making sure that the reference points to an existing fragment). You should only resolve a schema once to avoid the overhead of resolving it in every validation call.

```elixir
iex> schema = %{
  "type" => "object",
  "properties" => %{
    "foo" => %{
      "type" => "string"
    }
  }
} |> ExJsonSchema.Schema.resolve
```

Note that `Map` keys are expected to be strings, since in practice that data will always come from some JSON parser.

## Usage

If you're only interested in whether a piece of data is valid according to the schema:

```elixir
iex> ExJsonSchema.Validator.valid?(schema, %{"foo" => "bar"})
true

iex> ExJsonSchema.Validator.valid?(schema, %{"foo" => 1})
false
```

Or in case you want to have detailed validation errors:

```elixir
iex> ExJsonSchema.Validator.validate(schema, %{"foo" => "bar"})
:ok

iex> ExJsonSchema.Validator.validate(schema, %{"foo" => 1})
{:error, [{"Type mismatch. Expected String but got Integer.", "#/foo"}]}
```

Errors are tuples of a message and the path to the element not matching the schema. The path is following the same conventions used in JSON Schema for referencing JSON elements.

## Format support

The validator supports all the formats specified by draft 4 (`date-time`, `email`, `hostname`, `ipv4`, `ipv6`), with the exception of the `uri` format which has confusing/broken requirements in the official test suite (see https://github.com/json-schema/JSON-Schema-Test-Suite/issues/77).

## License

Released under the [MIT license](LICENSE).

## TODO

* Add some source code documentation
* Enable providing JSON for known schemata at resolve time
