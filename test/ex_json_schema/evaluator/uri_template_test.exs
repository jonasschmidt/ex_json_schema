defmodule ExJsonSchema.Evaluator.URITemplateTest do
  use ExUnit.Case, async: true

  alias ExJsonSchema.Evaluator.Format.URITemplate

  test "accepts every RFC 6570 expression operator" do
    for operator <- ["+", "#", ".", "/", ";", "?", "&", "=", ",", "!", "@", "|"] do
      assert URITemplate.valid?("{#{operator}variable}")
    end
  end

  test "accepts valid variable names and modifiers" do
    for template <- [
          "{variable}",
          "{first.second}",
          "{%41}",
          "{variable*}",
          "{variable:1}",
          "{variable:9999}",
          "{first,second}"
        ] do
      assert URITemplate.valid?(template)
    end
  end

  test "rejects malformed variable names and modifiers" do
    for template <- [
          "{}",
          "{first,}",
          "{first..second}",
          "{variable:0}",
          "{variable:0001}",
          "{variable:10000}",
          "{variable:1*}",
          "{variable**}",
          "{%GG}"
        ] do
      refute URITemplate.valid?(template)
    end
  end

  test "validates literal and percent-encoded characters" do
    assert URITemplate.valid?("a%20b")
    assert URITemplate.valid?("a'b")
    assert URITemplate.valid?(<<0xA0::utf8, 0xE000::utf8, 0x10FFFD::utf8>>)

    for template <- ["a b", "a%", "\"", "<", ">", "\\", "^", "`", "{", "|", "}"] do
      refute URITemplate.valid?(template)
    end

    refute URITemplate.valid?(<<0xFDD0::utf8>>)
    refute URITemplate.valid?(<<0xFF>>)
  end
end
