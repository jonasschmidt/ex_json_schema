# Elixir JSON Schema Validator

[![Build Status](https://github.com/jonasschmidt/ex_json_schema/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/jonasschmidt/ex_json_schema/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/jonasschmidt/ex_json_schema/badge.svg?branch=master)](https://coveralls.io/github/jonasschmidt/ex_json_schema?branch=master)
[![Module Version](https://img.shields.io/hexpm/v/ex_json_schema.svg)](https://hex.pm/packages/ex_json_schema)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_json_schema/)
[![Total Download](https://img.shields.io/hexpm/dt/ex_json_schema.svg)](https://hex.pm/packages/ex_json_schema)
[![License](https://img.shields.io/hexpm/l/ex_json_schema.svg)](https://github.com/jonasschmidt/ex_json_schema/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/jonasschmidt/ex_json_schema.svg)](https://github.com/jonasschmidt/ex_json_schema/commits/master)

A JSON Schema validator with support for the draft 4, draft 6 and draft 7 specifications. Passes the official [JSON Schema Test Suite](https://github.com/json-schema/JSON-Schema-Test-Suite).

## Installation

Add the project to your Mix dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:ex_json_schema, "~> 0.10.2"}
  ]
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
  fn url -> HTTPoison.get!(url).body |> Jason.decode! end
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

The configured function is called with the arguments `(format, data)` and is expected to return `true`, `false` or a `{:error, %Error.Format{expected: "something"}}` tuple, depending whether the data is valid for the given format. For compatibility with JSON schema, it is expected to return `true` when the format is unknown by your callback function.

The custom function can also be an anonymous function:

```elixir
ExJsonSchema.Schema.resolve(%{"format" => "custom"}, custom_format_validator: fn format, data -> true end)
```

> Note that the anonymous function version of the custom validator is only available in the option to Schema.resolve/2 and not as Application config, as using anonymous functions as configuration is not allowed.

[format-spec]: https://json-schema.org/understanding-json-schema/reference/string.html#format

## Custom keywords

Keywords which are not part of the JSON Schema spec are ignored and not subjected to any validation by default.
Should custom validation for extended keywords be required, you can provide a custom keyword validator which will be called with `(schema, property, data, path)` as parameters and is expected to return a list of `%Error{}` structs.

This validator can be configured globally:

```elixir
config :ex_json_schema,
  :custom_keyword_validator,
  {MyKeywordValidator, :validate}
```

Or by passing an option as either a `{module, function_name}` tuple or an anonymous function when resolving the schema:

```elixir
ExJsonSchema.Schema.resolve(%{"x-my-keyword" => "value"}, custom_keyword_validator: {MyKeywordValidator, :validate})
```

A partical example of how to use this functionality would be to extend a schema to support validating if strings contain a certain value via a custom keyword - `x-contains`. A simple implementation:

```elixir
defmodule CustomValidator do
  def validate(_schema, {"x-contains", contains}, data, _path) do
    if not String.contains?(data, contains) do
      [%Error{error: "#{data} does not contain #{contains}"}]
    else
      []
    end
  end

  def validate(_, _, _, _), do: []
end
```

## License

Copyright (c) 2015 Jonas Schmidt

Released under the [MIT license](https://github.com/jonasschmidt/ex_json_schema/blob/master/LICENSE).

## TODO

- Add some source code documentation
- Enable providing JSON for known schemata at resolve time
