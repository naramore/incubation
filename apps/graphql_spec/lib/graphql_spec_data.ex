defmodule GraphqlSpecData do
  import StreamData
  import ExUnitProperties
  alias GraphqlSpec.Language

  @size_div 2
  @inspect_opts [limit: :infinity, printable_limit: :infinity, pretty: true, structs: false]

  @spec print_doc(Inspect.t, keyword) :: :ok
  def print_doc(doc, opts \\ []) do
    IO.inspect(doc, Keyword.merge(@inspect_opts, opts))
  end

  @spec lazy((() -> StreamData.t(term)), non_neg_integer()) :: StreamData.t(term)
  def lazy(data, divisor \\ @size_div) do
    sized(fn size ->
      resize(data.(), div(size, divisor))
    end)
  end

  @spec executable_document(keyword) :: StreamData.t(Language.Document.t)
  def executable_document(opts \\ []) do
    lazy(fn -> list_of(executable_definition(opts), opts) end)
    |> map(fn defs ->
      %Language.Document{definitions: defs}
    end)
  end

  @spec non_executable_document(keyword) :: StreamData.t(Language.Document.t)
  def non_executable_document(opts \\ []) do
    lazy(fn ->
      list_of(one_of([
        type_system_definition(opts),
        type_system_extension(opts)
      ]), opts)
    end)
    |> map(fn defs ->
      %Language.Document{definitions: defs}
    end)
  end

  @spec document(keyword) :: StreamData.t(Language.Document.t)
  def document(opts \\ []) do
    lazy(fn -> list_of(definition(opts), opts) end)
    |> map(fn defs ->
      %Language.Document{definitions: defs}
    end)
  end

  @spec directive(keyword) :: StreamData.t(Language.Directive.t)
  def directive(opts \\ []) do
    gen all name <- name(opts),
            arguments <- lazy(fn -> list_of(argument(opts), opts) end) do
      %Language.Directive{
        name: name,
        arguments: arguments
      }
    end
  end

  @spec argument(keyword) :: StreamData.t(Language.Argument.t)
  def argument(opts \\ []) do
    gen all name <- name(opts),
            value <- lazy(fn -> value(opts) end) do
      %Language.Argument{
        name: name,
        value: value
      }
    end
  end

  # Types
  ##########

  @spec named_type(keyword) :: StreamData.t(Language.NamedType.t)
  def named_type(opts \\ []) do
    map(name(opts), fn name ->
      %Language.NamedType{name: name}
    end)
  end

  @spec type(keyword) :: StreamData.t(Language.type)
  def type(opts \\ []) do
    one_of([
      named_type(opts),
      list_type(opts),
      non_null_type(opts)
    ])
  end

  @spec list_type(keyword) :: StreamData.t(Language.ListType.t)
  def list_type(opts \\ []) do
    lazy(fn -> type(opts) end)
    |> map(fn t ->
      %Language.ListType{type: t}
    end)
  end

  @spec non_null_type(keyword) :: StreamData.t(Language.NonNullType.t)
  def non_null_type(opts \\ []) do
    lazy(fn -> one_of([named_type(opts), list_type(opts)]) end)
    |> map(fn t ->
      %Language.NonNullType{type: t}
    end)
  end

  # Values
  ###########

  @spec default_value(keyword) :: StreamData.t(Language.DefaultValue.t)
  def default_value(opts \\ []) do
    lazy(fn -> value(opts) end)
    |> map(fn default ->
      %Language.DefaultValue{default: default}
    end)
  end

  @spec value(keyword) :: StreamData.t(Language.value)
  def value(opts \\ []) do
    one_of([
      variable(opts),
      integer(),
      float(),
      string_value(opts),
      boolean(),
      constant(nil),
      enum_value(opts),
      lazy(fn -> list_value(opts) end),
      lazy(fn -> object_value(opts) end)
    ])
  end

  @spec variable(keyword) :: StreamData.t(Language.Variable.t)
  def variable(opts \\ []) do
    map(name(opts), fn name ->
      %Language.Variable{name: name}
    end)
  end

  @spec enum_value(keyword) :: StreamData.t(Language.EnumValue.t)
  def enum_value(opts \\ []) do
    map(name(opts), fn value ->
      %Language.EnumValue{value: value}
    end)
  end

  @spec list_value(keyword) :: StreamData.t(Language.ListValue.t)
  def list_value(opts \\ []) do
    lazy(fn -> list_of(value(opts), opts) end)
    |> map(fn values ->
      %Language.ListValue{values: values}
    end)
  end

  @spec object_value(keyword) :: StreamData.t(Language.ObjectValue.t)
  def object_value(opts \\ []) do
    lazy(fn -> list_of(object_field(opts), opts) end)
    |> map(fn fields ->
      %Language.ObjectValue{fields: fields}
    end)
  end

  @spec object_field(keyword) :: StreamData.t(Language.ObjectField.t)
  def object_field(opts \\ []) do
    lazy(fn -> value(opts) end)
    |> (&{name(opts), &1}).()
    |> map(fn {name, value} ->
      %Language.ObjectField{
        name: name,
        value: value
      }
    end)
  end

  # Selection Set
  ##################

  @spec selection(keyword) :: StreamData.t(Language.Selection.t)
  def selection(opts \\ []) do
    one_of([
      field(opts),
      fragment_spread(opts),
      inline_fragment(opts)
    ])
  end

  @spec field(keyword) :: StreamData.t(Language.Field.t)
  def field(opts \\ []) do
    gen all alias <- one_of([name(opts), constant(nil)]),
            name <- name(opts),
            arguments <- lazy(fn -> list_of(argument(opts), opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            selections <- lazy(fn -> list_of(selection(opts), opts) end) do
      %Language.Field{
        alias: alias,
        name: name,
        arguments: arguments,
        directives: directives,
        selections: selections
      }
    end
  end

  @spec fragment_spread(keyword) :: StreamData.t(Language.FragmentSpread.t)
  def fragment_spread(opts \\ []) do
    gen all name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end) do
      %Language.FragmentSpread{
        name: name,
        directives: directives
      }
    end
  end

  @spec inline_fragment(keyword) :: StreamData.t(Language.InlineFragment.t)
  def inline_fragment(opts \\ []) do
    gen all type_condition <- one_of([named_type(opts), constant(nil)]),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            selections <- lazy(fn -> list_of(selection(opts), opts) end) do
      %Language.InlineFragment{
        type_condition: type_condition,
        directives: directives,
        selections: selections
      }
    end
  end

  # Definitions
  ################

  @spec definition(keyword) :: StreamData.t(Language.Definition.t)
  def definition(opts \\ []) do
    one_of([
      executable_definition(opts),
      type_system_definition(opts),
      type_system_extension(opts)
    ])
  end

  @spec executable_definition(keyword) :: StreamData.t(Language.Definition.executable_definition)
  def executable_definition(opts \\ []) do
    one_of([
      operation_definition(opts),
      fragment_definition(opts)
    ])
  end

  @spec type_system_definition(keyword) :: StreamData.t(Language.Definition.type_system_definition)
  def type_system_definition(opts \\ []) do
    one_of([
      schema_definition(opts),
      type_definition(opts),
      directive_definition(opts)
    ])
  end

  @spec type_definition(keyword) :: StreamData.t(Language.Definition.type_definition)
  def type_definition(opts \\ []) do
    one_of([
      scalar_type_definition(opts),
      object_type_definition(opts),
      interface_type_definition(opts),
      union_type_definition(opts),
      enum_type_definition(opts),
      input_object_type_definition(opts)
    ])
  end

  @spec operation_definition(keyword) :: StreamData.t(Language.OperationDefinition.t)
  def operation_definition(opts \\ []) do
    gen all operation <- one_of([operation_type(), constant(nil)]),
            name <- name(opts),
            variables <- lazy(fn -> list_of(variable_definition(opts), opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            selections <- lazy(fn -> list_of(selection(opts), opts) end) do
      %Language.OperationDefinition{
        operation: operation,
        name: name,
        variables: variables,
        directives: directives,
        selections: selections
      }
    end
  end

  @spec fragment_definition(keyword) :: StreamData.t(Language.FragmentDefinition.t)
  def fragment_definition(opts \\ []) do
    gen all name <- name(opts),
            type_condition <- named_type(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            selections <- lazy(fn -> list_of(selection(opts), opts) end) do
      %Language.FragmentDefinition{
        name: name,
        type_condition: type_condition,
        directives: directives,
        selections: selections
      }
    end
  end

  @spec schema_definition(keyword) :: StreamData.t(Language.SchemaDefinition.t)
  def schema_definition(opts \\ []) do
    gen all directives <- lazy(fn -> list_of(directive(opts), opts) end),
            operations <- lazy(fn -> list_of(operation_type_definition(opts), opts) end) do
      %Language.SchemaDefinition{
        directives: directives,
        operations: operations
      }
    end
  end

  @spec directive_definition(keyword) :: StreamData.t(Language.DirectiveDefinition.t)
  def directive_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            arguments <- lazy(fn -> list_of(argument(opts), opts) end),
            locations <- list_of(directive_location(), opts) do
      %Language.DirectiveDefinition{
        description: description,
        name: name,
        arguments: arguments,
        locations: locations
      }
    end
  end

  @spec scalar_type_definition(keyword) :: StreamData.t(Language.ScalarTypeDefinition.t)
  def scalar_type_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end) do
      %Language.ScalarTypeDefinition{
        description: description,
        name: name,
        directives: directives
      }
    end
  end

  @spec object_type_definition(keyword) :: StreamData.t(Language.ObjectTypeDefinition.t)
  def object_type_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            interfaces <- lazy(fn -> list_of(name(opts), opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            fields <- lazy(fn -> list_of(field_definition(opts), opts) end) do
      %Language.ObjectTypeDefinition{
        description: description,
        name: name,
        interfaces: interfaces,
        directives: directives,
        fields: fields
      }
    end
  end

  @spec interface_type_definition(keyword) :: StreamData.t(Language.InterfaceTypeDefinition.t)
  def interface_type_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            fields <- lazy(fn -> list_of(field_definition(opts), opts) end) do
      %Language.InterfaceTypeDefinition{
        description: description,
        name: name,
        directives: directives,
        fields: fields
      }
    end
  end

  @spec union_type_definition(keyword) :: StreamData.t(Language.UnionTypeDefinition.t)
  def union_type_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            types <- lazy(fn -> list_of(name(opts), opts) end) do
      %Language.UnionTypeDefinition{
        description: description,
        name: name,
        directives: directives,
        types: types
      }
    end
  end

  @spec enum_type_definition(keyword) :: StreamData.t(Language.EnumTypeDefinition.t)
  def enum_type_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            values <- lazy(fn -> list_of(enum_value_definition(opts), opts) end) do
      %Language.EnumTypeDefinition{
        description: description,
        name: name,
        directives: directives,
        values: values
      }
    end
  end

  @spec input_object_type_definition(keyword) :: StreamData.t(Language.InputObjectTypeDefinition.t)
  def input_object_type_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            input_fields <- lazy(fn -> list_of(input_value_definition(opts), opts) end) do
      %Language.InputObjectTypeDefinition{
        description: description,
        name: name,
        directives: directives,
        input_fields: input_fields
      }
    end
  end

  @spec variable_definition(keyword) :: StreamData.t(Language.VariableDefinition.t)
  def variable_definition(opts \\ []) do
    gen all variable <- name(opts),
            type <- type(opts),
            default_value <- lazy(fn -> one_of([default_value(opts), constant(nil)]) end) do
      %Language.VariableDefinition{
        variable: variable,
        type: type,
        default_value: default_value
      }
    end
  end

  @spec operation_type_definition(keyword) :: StreamData.t(Language.OperationTypeDefinition.t)
  def operation_type_definition(opts \\ []) do
    gen all operation <- operation_type(),
            name <- name(opts) do
      %Language.OperationTypeDefinition{
        operation: operation,
        name: name
      }
    end
  end

  @spec field_definition(keyword) :: StreamData.t(Language.FieldDefinition.t)
  def field_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            arguments <- lazy(fn -> list_of(argument(opts), opts) end),
            type <- lazy(fn -> type(opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end) do
      %Language.FieldDefinition{
        description: description,
        name: name,
        arguments: arguments,
        type: type,
        directives: directives
      }
    end
  end

  @spec enum_value_definition(keyword) :: StreamData.t(Language.EnumValueDefinition.t)
  def enum_value_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            value <- lazy(fn -> value(opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end) do
      %Language.EnumValueDefinition{
        description: description,
        value: value,
        directives: directives
      }
    end
  end

  @spec input_value_definition(keyword) :: StreamData.t(Language.InputValueDefinition.t)
  def input_value_definition(opts \\ []) do
    gen all description <- one_of([description(opts), constant(nil)]),
            name <- name(opts),
            type <- lazy(fn -> type(opts) end),
            default_value <- lazy(fn -> default_value(opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end) do
      %Language.InputValueDefinition{
        description: description,
        name: name,
        type: type,
        default_value: default_value,
        directives: directives
      }
    end
  end

  # Extensions
  ###############

  @spec type_system_extension(keyword) :: StreamData.t(Language.Definition.type_system_extension)
  def type_system_extension(opts \\ []) do
    one_of([
      schema_extension(opts),
      type_extension(opts)
    ])
  end

  @spec schema_extension(keyword) :: StreamData.t(Language.SchemaExtension.t)
  def schema_extension(opts \\ []) do
    gen all directives <- lazy(fn -> list_of(directive(opts), opts) end),
            operations <- lazy(fn -> list_of(operation_type_definition(opts), opts) end) do
      %Language.SchemaDefinition{
        directives: directives,
        operations: operations
      }
    end
  end

  @spec type_extension(keyword) :: StreamData.t(Language.Definition.type_extension)
  def type_extension(opts \\ []) do
    one_of([
      scalar_type_extension(opts),
      object_type_extension(opts),
      interface_type_extension(opts),
      union_type_extension(opts),
      enum_type_extension(opts),
      input_object_type_extension(opts)
    ])
  end

  @spec scalar_type_extension(keyword) :: StreamData.t(Language.ScalarTypeExtension.t)
  def scalar_type_extension(opts \\ []) do
    gen all name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end) do
      %Language.ScalarTypeExtension{
        name: name,
        directives: directives
      }
    end
  end

  @spec object_type_extension(keyword) :: StreamData.t(Language.ObjectTypeExtension.t)
  def object_type_extension(opts \\ []) do
    gen all name <- name(opts),
            interfaces <- lazy(fn -> list_of(name(opts), opts) end),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            fields <- lazy(fn -> list_of(field_definition(opts), opts) end) do
      %Language.ObjectTypeExtension{
        name: name,
        interfaces: interfaces,
        directives: directives,
        fields: fields
      }
    end
  end

  @spec interface_type_extension(keyword) :: StreamData.t(Language.InterfaceTypeExtension.t)
  def interface_type_extension(opts \\ []) do
    gen all name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            fields <- lazy(fn -> list_of(field_definition(opts), opts) end) do
      %Language.InterfaceTypeExtension{
        name: name,
        directives: directives,
        fields: fields
      }
    end
  end

  @spec enum_type_extension(keyword) :: StreamData.t(Language.EnumTypeExtension.t)
  def enum_type_extension(opts \\ []) do
    gen all name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            values <- lazy(fn -> list_of(enum_type_definition(opts), opts) end) do
      %Language.EnumTypeExtension{
        name: name,
        directives: directives,
        values: values
      }
    end
  end

  @spec input_object_type_extension(keyword) :: StreamData.t(Language.InputObjectTypeExtension.t)
  def input_object_type_extension(opts \\ []) do
    gen all name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            input_fields <- lazy(fn -> list_of(input_value_definition(opts), opts) end) do
      %Language.InputObjectTypeExtension{
        name: name,
        directives: directives,
        input_fields: input_fields
      }
    end
  end

  @spec union_type_extension(keyword) :: StreamData.t(Language.UnionTypeExtension.t)
  def union_type_extension(opts \\ []) do
    gen all name <- name(opts),
            directives <- lazy(fn -> list_of(directive(opts), opts) end),
            types <- lazy(fn -> list_of(name(opts), opts) end) do
      %Language.UnionTypeExtension{
        name: name,
        directives: directives,
        types: types
      }
    end
  end

  # Language
  #############

  @spec operation_type() :: StreamData.t(Language.OperationTypeDefinition.operation_type)
  def operation_type() do
    member_of([:query, :mutation, :subscription])
  end

  @spec string_value(keyword) :: StreamData.t(String.t)
  def string_value(opts \\ []) do
    # NOTE: 0xD800..0xFFFF results in UnicodeConversionError
    string([0x0009, 0x000A, 0x000D, 0x0020..0xD7FF], opts)
  end

  @spec description(keyword) :: StreamData.t(String.t)
  def description(opts \\ []) do
    string_value(opts)
  end

  @spec name(keyword) :: StreamData.t(Language.name)
  def name(opts \\ []) do
    gen all prefix <- string([?a..?z, ?A..?Z, ?_], min_length: 1, max_length: 1),
            body <- string([?0..?9, ?a..?z, ?A..?Z, ?_], opts) do
      prefix <> body
    end
  end

  @spec directive_location() :: StreamData.t(Language.DirectiveDefinition.directive_location)
  def directive_location() do
    one_of([
      executable_directive_location(),
      type_system_directive_location()
    ])
  end

  @spec executable_directive_location() :: StreamData.t(Language.DirectiveDefinition.executable_directive_location)
  def executable_directive_location() do
    member_of([
      :query,
      :mutation,
      :subscription,
      :field,
      :fragment_definition,
      :fragment_spread,
      :inline_fragment
    ])
  end

  @spec type_system_directive_location() :: StreamData.t(Language.DirectiveDefinition.type_system_directive_location)
  def type_system_directive_location() do
    member_of([
      :schema,
      :scalar,
      :object,
      :field_definition,
      :argument_definition,
      :interface,
      :union,
      :enum,
      :enum_value,
      :input_object,
      :input_field_definition
    ])
  end
end
