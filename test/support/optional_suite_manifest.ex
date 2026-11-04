defmodule ExJsonSchema.Test.Support.OptionalSuiteManifest do
  @moduledoc false

  @enabled_formats ~w[
    date
    date-time
    duration
    email
    ipv4
    ipv6
    json-pointer
    regex
    relative-json-pointer
    time
    uri
    uri-reference
    uri-template
    uuid
    unknown
  ]

  @enabled_validation ~w[
    anchor
    bignum
    dynamicRef
    float-overflow
    format-assertion
    id
    non-bmp-regex
    no-schema
    refOfUnknownKeyword
    unknownKeyword
  ]

  @skipped %{
    "cross-draft" =>
      {:unsupported_dialect,
       "contains a draft 2019-09 resource, which is intentionally outside the supported dialect set"},
    "dependencies-compatibility" =>
      {:unsupported_compatibility, "the removed dependencies keyword is intentionally not re-enabled in draft 2020-12"},
    "ecmascript-regex" =>
      {:regex_engine, "Elixir uses PCRE2; its anchors, character classes, and control escapes differ from ECMA-262"},
    "format/ecmascript-regex" =>
      {:regex_engine, "Elixir's regex compiler accepts a different language than the ECMA-262 grammar required here"},
    "format/hostname" =>
      {:idna, "the suite requires IDNA validation for A-labels; the evaluated :idna dependency is not conformant"},
    "format/idn-email" =>
      {:idna, "requires UTS 46 and IDNA validation not provided by a conformant runtime dependency"},
    "format/idn-hostname" =>
      {:idna, "requires UTS 46 and IDNA validation not provided by a conformant runtime dependency"},
    "format/iri" =>
      {:iri, "requires an RFC 3987 parser; :gluri cannot be consumed by Mix without a Gleam build integration"},
    "format/iri-reference" =>
      {:iri, "requires an RFC 3987 parser; :gluri cannot be consumed by Mix without a Gleam build integration"}
  }

  def enabled_formats, do: @enabled_formats
  def enabled_validation, do: @enabled_validation
  def skipped, do: @skipped

  def enabled_paths do
    Enum.map(@enabled_formats, &"format/#{&1}") ++ @enabled_validation
  end
end
