# Elixir JSON Schema validator

[![Build Status](https://travis-ci.org/jonasschmidt/ex_json_schema.svg?branch=master)](https://travis-ci.org/jonasschmidt/ex_json_schema) [![Coverage Status](https://coveralls.io/repos/jonasschmidt/ex_json_schema/badge.svg?branch=travis-elixir-version&service=github)](https://coveralls.io/github/jonasschmidt/ex_json_schema?branch=travis-elixir-version) [![Hex.pm](http://img.shields.io/hexpm/v/ex_json_schema.svg)](https://hex.pm/packages/ex_json_schema) [![Hex.pm](http://img.shields.io/hexpm/l/ex_json_schema.svg)](LICENSE)

A JSON Schema validator with full support for the draft 4 specification and zero dependencies. Passes the official [JSON Schema Test Suite](https://github.com/json-schema/JSON-Schema-Test-Suite).

## Installation

Add the project to your Mix dependencies in `mix.exs`:

```elixir
defp deps do
  [{:ex_json_schema, "~> 0.7.3"}]
end
```

Update your dependencies with:

```shell
$ mix deps.get
```

### Loading remote schemata

If you have remote schemata that need to be fetched at runtime, you have to register a function that takes a URL and returns a `Map` of the parsed JSON. So in your Mix configuration in `config/config.exs` you should have something like this:

```elixir
config :ex_json_schema,
  :remote_schema_resolver,
  fn url -> HTTPoison.get!(url).body |> Poison.decode! end
```

Alternatively, you can specify a module and function name for situations where using anonymous functions is not possible (i.e. working with Erlang releases):

```elixir
config :ex_json_schema,
  :remote_schema_resolver,
  {MyModule, :my_resolver}
```

You do not have to do that for the official draft 4 meta-schema found at http://json-schema.org/draft-04/schema# though. That schema is bundled with the project and will work out of the box without any network calls.

### Resolving a schema

In this step the schema is validated against its meta-schema (the draft 4 schema definition) and `$ref`s are being resolved (making sure that the reference points to an existing fragment). You should only resolve a schema once to avoid the overhead of resolving it in every validation call.

```elixir
schema = %{
  "type" => "object",
  "properties" => %{
    "foo" => %{
      "type" => "string"
    }
  }
} |> ExJsonSchema.Schema.resolve()
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

### Validation error formats

By default, errors are formatted using a string formatter that returns errors as tuples of error message and path. If you want to get raw validation error structs, you can pass the following option:

```elixir
iex> ExJsonSchema.Validator.validate(schema, %{"foo" => 1}, error_formatter: false)
{:error,
 [
   %ExJsonSchema.Validator.Error{
     error: %ExJsonSchema.Validator.Error.Type{
       actual: "integer",
       expected: ["string"]
     },
     path: "#/foo"
   }
 ]}
```

#### Custom error formatter

You can also pass your own custom error formatter as a module that implements a `format/1` function that takes a list of raw errors via the same option:

```elixir
defmodule MyFormatter do
  def format(errors) do
    Enum.map(errors, fn %ExJsonSchema.Validator.Error{error: error, path: path} ->
      {error.__struct__, path}
    end)
  end
end
```

```elixir
iex> ExJsonSchema.Validator.validate(schema, %{"foo" => 1}, error_formatter: MyFormatter)
{:error, [{ExJsonSchema.Validator.Error.Type, "#/foo"}]}
```

### Validating against a fragment

It is also possible to validate against a subset of the schema by providing either a fragment:

```elixir
iex> fragment = ExJsonSchema.Schema.get_fragment!(schema, "#/properties/foo")
%{"type" => "string"}

iex> ExJsonSchema.Validator.valid_fragment?(schema, fragment, "bar")
true

iex> ExJsonSchema.Validator.validate_fragment(schema, fragment, "bar")
:ok
```

or a path:

```elixir
iex> ExJsonSchema.Validator.valid_fragment?(schema, "#/foo", "bar")
true
```

## Format support

The validator supports all the formats specified by draft 4 (`date-time`, `email`, `hostname`, `ipv4`, `ipv6`), with the exception of the `uri` format which has confusing/broken requirements in the official test suite (see https://github.com/json-schema/JSON-Schema-Test-Suite/issues/77).

### Custom formats

The [JSON schema spec][format-spec] states that the `format` property "allows values to be constrained beyond what the other tools in JSON Schema can do". To support this, you can configure a callback validator function which gets called when a `format` property is encountered that is not one of the builtin formats.

As a global configuration option:

```elixir
config :ex_json_schema,
  :custom_format_validator,
  {MyModule, :validate}
```

Or by passing an option when resolving the schema:

```elixir
ExJsonSchema.Schema.resolve(%{"format" => "custom"}, custom_format_validator: {MyModule, :validate})
```

The configured function is called with the arguments `(format, data)` and is expected to return either `true` or `false`, depending whether the data is valid for the given format. For compatibility with JSON schema, it is expected to return `true` when the format is unknown by your callback function.

[format-spec]: https://json-schema.org/understanding-json-schema/reference/string.html#format


## License

Released under the [MIT license](LICENSE).

## TODO

* Add some source code documentation
* Enable providing JSON for known schemata at resolve time
