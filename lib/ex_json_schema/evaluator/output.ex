defmodule ExJsonSchema.Evaluator.Output do
  @moduledoc false

  # Projects the internal result tree into the standardized flag, basic,
  # detailed, and verbose output shapes.

  alias ExJsonSchema.Evaluator.Result

  @type format :: :flag | :basic | :detailed | :verbose

  @spec project(Result.t(), format()) :: map()
  def project(%Result{valid: valid}, :flag), do: %{"valid" => valid}

  def project(%Result{} = result, :basic) do
    result
    |> base_unit()
    |> put_flat_results(result)
  end

  def project(%Result{} = result, :detailed) do
    detailed_unit(result, true)
  end

  def project(%Result{children: children} = result, :verbose) do
    result
    |> base_unit()
    |> put_hierarchy(children, :verbose)
  end

  defp put_flat_results(unit, %Result{valid: false, error: error} = result) do
    errors =
      result
      |> flatten()
      |> Enum.filter(&reportable_error?/1)
      |> Enum.map(&result_unit(&1, :basic))

    if errors == [],
      do: Map.put(unit, "error", error || "validation failed"),
      else: Map.put(unit, "errors", errors)
  end

  defp put_flat_results(unit, %Result{valid: true} = result) do
    annotations =
      result
      |> flatten_annotations()
      |> Enum.filter(&reportable_annotation?/1)
      |> Enum.map(&result_unit(&1, :basic))

    if annotations == [], do: unit, else: Map.put(unit, "annotations", annotations)
  end

  defp put_hierarchy(unit, [], _mode), do: put_terminal_payload(unit)

  defp put_hierarchy(unit, children, mode) do
    {errors, valid_children} =
      Enum.split_with(children, fn %Result{valid: valid} -> not valid end)

    unit
    |> maybe_put(
      "errors",
      Enum.map(errors, &result_unit(&1, mode)),
      errors != []
    )
    |> maybe_put(
      "annotations",
      Enum.map(valid_children, &result_unit(&1, mode)),
      valid_children != []
    )
    |> put_terminal_payload()
  end

  defp result_unit(
         %Result{
           error: error,
           annotation: annotation,
           annotation?: annotation?,
           children: children
         } = result,
         mode
       ) do
    result
    |> base_unit()
    |> maybe_put("error", error, is_binary(error))
    |> maybe_put("annotation", annotation, annotation?)
    |> then(fn unit ->
      case {mode, children} do
        {:basic, _children} -> unit
        {_mode, []} -> unit
        {_mode, children} -> put_hierarchy(unit, children, mode)
      end
    end)
  end

  defp detailed_unit(
         %Result{
           valid: valid,
           error: error,
           annotation: annotation,
           annotation?: annotation?,
           children: children
         } = result,
         root?
       ) do
    projected_children =
      children
      |> Enum.filter(fn %Result{valid: child_valid} -> child_valid == valid end)
      |> Enum.map(&detailed_unit(&1, false))
      |> Enum.reject(&is_nil/1)

    unit =
      result
      |> base_unit()
      |> maybe_put("error", error, is_binary(error))
      |> maybe_put("annotation", annotation, annotation?)
      |> put_projected_hierarchy(projected_children)
      |> put_terminal_payload()

    case {root?, projected_children} do
      {true, _children} ->
        unit

      {false, [child]} ->
        child

      {false, children} when not valid or annotation? or children != [] ->
        unit

      {false, []} ->
        nil
    end
  end

  defp put_projected_hierarchy(unit, children) do
    {errors, annotations} =
      Enum.split_with(children, fn %{"valid" => valid} -> not valid end)

    unit
    |> maybe_put("errors", errors, errors != [])
    |> maybe_put("annotations", annotations, annotations != [])
  end

  defp base_unit(%Result{
         valid: valid,
         keyword_location: keyword_location,
         instance_location: instance_location,
         absolute_keyword_location: absolute_keyword_location
       }) do
    %{
      "valid" => valid,
      "keywordLocation" => keyword_location,
      "instanceLocation" => instance_location
    }
    |> maybe_put(
      "absoluteKeywordLocation",
      absolute_keyword_location,
      is_binary(absolute_keyword_location)
    )
  end

  defp put_terminal_payload(unit) do
    cond do
      unit["valid"] == false and not Map.has_key?(unit, "errors") and
          not Map.has_key?(unit, "error") ->
        Map.put(unit, "error", "validation failed")

      true ->
        unit
    end
  end

  defp flatten(%Result{children: children}), do: Enum.flat_map(children, &flatten_error/1)

  # A failed contains candidate is a non-match, not an independently
  # reportable validation error. The contains result reports the aggregate
  # match-count failure.
  defp flatten_error(%Result{keyword: "contains"} = result), do: [result]
  defp flatten_error(%Result{} = result), do: [result | flatten(result)]

  defp flatten_annotations(%Result{children: children}) do
    Enum.flat_map(children, fn %Result{valid: valid} = child ->
      if valid, do: [child | flatten_annotations(child)], else: []
    end)
  end

  defp reportable_error?(%Result{valid: valid, error: error, children: children}) do
    not valid and
      (is_binary(error) or Enum.all?(children, fn %Result{valid: child_valid} -> child_valid end))
  end

  defp reportable_annotation?(%Result{valid: valid, annotation?: annotation?}),
    do: valid and annotation?

  defp maybe_put(map, _key, _value, false), do: map
  defp maybe_put(map, key, value, true), do: Map.put(map, key, value)
end
