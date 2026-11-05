defmodule ExJsonSchema.Test.Support.OutputAssertions do
  @moduledoc false

  # Checks standardized output independently from the production projectors so
  # every official validation case also exercises all public output formats.

  import ExUnit.Assertions

  alias ExJsonSchema.Evaluator
  alias ExJsonSchema.Evaluator.Output

  @formats [:flag, :basic, :detailed, :verbose]

  @spec assert_all!(ExJsonSchema.data(), ExJsonSchema.CompiledSchema.t(), boolean()) :: :ok
  @spec assert_all!(
          ExJsonSchema.data(),
          ExJsonSchema.CompiledSchema.t(),
          boolean(),
          keyword()
        ) :: :ok
  def assert_all!(instance, compiled, expected_valid, options \\ []) do
    outputs =
      Map.new(@formats, fn format ->
        output = Evaluator.validate(instance, compiled, Keyword.put(options, :output, format))
        assert output["valid"] == expected_valid
        {format, output}
      end)

    %{
      flag: flag,
      basic: basic,
      detailed: detailed,
      verbose: verbose
    } = outputs

    assert flag == %{"valid" => expected_valid}
    full_result = Evaluator.evaluate(instance, compiled, options)
    reference_basic = Output.project(full_result, :basic)
    assert_basic_semantics!(basic, reference_basic)

    assert_output_unit!(basic, :basic)
    assert_output_unit!(detailed, :detailed)
    assert_output_unit!(verbose, :verbose)

    :ok
  end

  defp assert_output_unit!(
         %{
           "valid" => valid,
           "keywordLocation" => keyword_location,
           "instanceLocation" => instance_location
         } = unit,
         format
       )
       when is_boolean(valid) and format in [:basic, :detailed, :verbose] do
    assert_json_pointer!(keyword_location)
    assert_json_pointer!(instance_location)
    assert_optional_absolute_location!(unit)
    assert_optional_payload!("error", unit, &is_binary/1)
    assert_optional_payload!("errors", unit, &is_list/1)
    assert_optional_payload!("annotations", unit, &is_list/1)

    errors = Map.get(unit, "errors", [])
    annotations = Map.get(unit, "annotations", [])

    assert Enum.all?(errors, &match?(%{"valid" => false}, &1))
    assert Enum.all?(annotations, &match?(%{"valid" => true}, &1))

    if valid == false do
      assert is_binary(unit["error"]) or errors != []
    end

    for child <- errors ++ annotations do
      assert_output_unit!(child, format)

      if format == :basic do
        refute Map.has_key?(child, "errors")
        refute Map.has_key?(child, "annotations")
      end

      if format == :detailed do
        assert reportable_detailed_unit?(child)
      end
    end
  end

  defp assert_output_unit!(unit, format) do
    flunk("invalid #{format} output unit: #{inspect(unit)}")
  end

  defp assert_optional_absolute_location!(unit) do
    case Map.fetch(unit, "absoluteKeywordLocation") do
      {:ok, location} when is_binary(location) ->
        %URI{scheme: scheme} = URI.parse(location)
        assert is_binary(scheme) and scheme != ""

      {:ok, location} ->
        flunk("absoluteKeywordLocation must be a string, got: #{inspect(location)}")

      :error ->
        :ok
    end
  end

  defp assert_optional_payload!(key, unit, predicate) do
    case Map.fetch(unit, key) do
      {:ok, value} -> assert predicate.(value), "#{key} has an invalid value: #{inspect(value)}"
      :error -> :ok
    end
  end

  defp reportable_detailed_unit?(unit) do
    Map.has_key?(unit, "error") or
      Map.has_key?(unit, "annotation") or
      Map.get(unit, "errors", []) != [] or
      Map.get(unit, "annotations", []) != []
  end

  defp basic_semantics(%{"valid" => valid} = output) do
    errors =
      cond do
        Map.has_key?(output, "errors") -> output["errors"]
        Map.has_key?(output, "error") -> [output]
        true -> []
      end

    annotations =
      cond do
        Map.has_key?(output, "annotations") -> output["annotations"]
        Map.has_key?(output, "annotation") -> [output]
        true -> []
      end

    {
      valid,
      errors |> Enum.map(&unit_semantics/1) |> Enum.sort(),
      annotations |> Enum.map(&unit_semantics/1) |> Enum.sort()
    }
  end

  defp assert_basic_semantics!(basic, reference) do
    {valid, errors, annotations} = basic_semantics(basic)
    {reference_valid, reference_errors, reference_annotations} = basic_semantics(reference)

    assert valid == reference_valid
    assert annotations == reference_annotations

    if valid do
      assert errors == reference_errors
    else
      assert errors != []
      assert MapSet.subset?(MapSet.new(errors), MapSet.new(reference_errors))
    end
  end

  defp unit_semantics(unit) do
    Map.take(unit, [
      "valid",
      "keywordLocation",
      "absoluteKeywordLocation",
      "instanceLocation",
      "annotation"
    ])
  end

  defp assert_json_pointer!(""), do: :ok

  defp assert_json_pointer!("/" <> pointer) do
    pointer
    |> String.split("/")
    |> Enum.each(fn token ->
      assert Regex.match?(~r/^(?:[^~]|~[01])*$/u, token),
             "invalid JSON Pointer token: #{inspect(token)}"
    end)
  end

  defp assert_json_pointer!(pointer) do
    flunk("invalid JSON Pointer: #{inspect(pointer)}")
  end
end
