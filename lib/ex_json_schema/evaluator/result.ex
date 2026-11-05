defmodule ExJsonSchema.Evaluator.Result do
  @moduledoc false

  # Represents one evaluation node together with its children, annotations,
  # errors, and evaluated instance locations.

  alias ExJsonSchema.Compiler.Location

  @type kind :: :schema | :assertion | :applicator | :annotation
  @type t :: %__MODULE__{
          valid: boolean(),
          kind: kind(),
          keyword: String.t() | nil,
          keyword_location: String.t(),
          schema_keyword_location: String.t(),
          absolute_keyword_location: String.t() | nil,
          instance_location: String.t(),
          error: String.t() | nil,
          annotation: ExJsonSchema.data() | nil,
          annotation?: boolean(),
          children: [t()],
          instance_path: [Location.pointer_segment()],
          evaluated_properties: MapSet.t(String.t()),
          evaluated_items: MapSet.t(non_neg_integer())
        }

  defstruct valid: true,
            kind: :schema,
            keyword: nil,
            keyword_location: "",
            schema_keyword_location: "",
            absolute_keyword_location: nil,
            instance_location: "",
            error: nil,
            annotation: nil,
            annotation?: false,
            children: [],
            instance_path: [],
            evaluated_properties: MapSet.new(),
            evaluated_items: MapSet.new()

  @spec new(boolean(), keyword()) :: t()
  def new(valid, options \\ []) when is_boolean(valid) do
    schema_location = Keyword.get(options, :schema_location, Location.root())
    keyword_location = Keyword.get(options, :keyword_location, schema_location)
    schema_keyword_location = Keyword.get(options, :schema_keyword_location)

    %Location{pointer: instance_path} =
      instance_location = Keyword.get(options, :instance_location, Location.root())

    report_locations? = Keyword.get(options, :report_locations, true)

    %__MODULE__{
      valid: valid,
      kind: Keyword.get(options, :kind, :schema),
      keyword: Keyword.get(options, :keyword),
      keyword_location: if(report_locations?, do: Location.pointer(keyword_location), else: ""),
      schema_keyword_location:
        if(report_locations? and schema_keyword_location,
          do: Location.pointer(schema_keyword_location),
          else: ""
        ),
      absolute_keyword_location: if(report_locations?, do: Location.absolute_uri(schema_location), else: nil),
      instance_location: if(report_locations?, do: Location.pointer(instance_location), else: ""),
      instance_path: instance_path,
      error: Keyword.get(options, :error),
      annotation: Keyword.get(options, :annotation),
      annotation?: Keyword.has_key?(options, :annotation),
      children: Keyword.get(options, :children, []),
      evaluated_properties: Keyword.get(options, :evaluated_properties, MapSet.new()),
      evaluated_items: Keyword.get(options, :evaluated_items, MapSet.new())
    }
  end

  @spec parent([t()], keyword()) :: t()
  def parent(children, options \\ []) when is_list(children) do
    valid =
      Keyword.get(
        options,
        :valid,
        Enum.all?(children, fn %__MODULE__{valid: child_valid} -> child_valid end)
      )

    %Location{pointer: instance_path} =
      Keyword.get(options, :instance_location, Location.root())

    {evaluated_properties, evaluated_items} =
      Enum.reduce(children, {MapSet.new(), MapSet.new()}, fn
        %__MODULE__{
          valid: child_valid,
          instance_path: child_instance_path,
          evaluated_properties: child_properties,
          evaluated_items: child_items
        },
        {properties, items} ->
          if child_valid and child_instance_path == instance_path do
            {
              MapSet.union(properties, child_properties),
              MapSet.union(items, child_items)
            }
          else
            {properties, items}
          end
      end)

    evaluated_properties =
      MapSet.union(
        evaluated_properties,
        Keyword.get(options, :evaluated_properties, MapSet.new())
      )

    evaluated_items =
      MapSet.union(evaluated_items, Keyword.get(options, :evaluated_items, MapSet.new()))

    new(
      valid,
      Keyword.merge(options,
        children: children,
        evaluated_properties: evaluated_properties,
        evaluated_items: evaluated_items
      )
    )
  end

  @spec append(t(), t()) :: t()
  def append(
        %__MODULE__{
          children: children,
          valid: parent_valid,
          kind: kind,
          keyword: keyword,
          error: error,
          annotation: annotation
        } = parent_result,
        %__MODULE__{valid: child_valid} = child
      ) do
    parent([parent_result | children] ++ [child],
      valid: parent_valid and child_valid,
      kind: kind,
      keyword: keyword,
      error: error,
      annotation: annotation
    )
  end
end
