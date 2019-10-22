defmodule GraphqlSpec.Interpreter do
  @moduledoc """
  """

  import NimbleParsec
  require GraphqlSpec.Utils
  alias GraphqlSpec.{Utils, Language}

  # Codepoints
  @horizontal_tab 0x0009
  @newline 0x000A
  @carriage_return 0x000D
  @space 0x0020
  @unicode_final 0xFFFF
  @unicode_bom 0xFEFF

  # SourceCharacter :: /[\u0009\u000A\u000D\u0020-\uFFFF]/
  source_character =
    utf8_char([
      @horizontal_tab,
      @newline,
      @carriage_return,
      @space..@unicode_final
    ])

  # UnicodeBOM :: "Byte Order Mark (U+FEFF)"
  unicode_bom = utf8_char([@unicode_bom])

  # WhiteSpace ::
  #   - "Horizontal Tab (U+0009)"
  #   - "Space (U+0020)"
  whitespace =
    ascii_char([
      @horizontal_tab,
      @space
    ])

  # LineTerminator ::
  #   - "New Line (U+000A)"
  #   - "Carriage Return (U+000D)" [ lookahead ! "New Line (U+000A)" ]
  #   - "Carriage Return (U+000D)" "New Line (U+000A)"
  line_terminator =
    choice([
      ascii_char([@newline]),
      ascii_char([@carriage_return])
      |> optional(ascii_char([@newline]))
    ])

  # Comment :: `#` CommentChar*
  # CommentChar :: SourceCharacter but not LineTerminator
  comment =
    ignore(string("#"))
    |> repeat_while(source_character, {Utils, :not_line_terminator, []})
    |> post_traverse({Utils, :build_string, []})

  defcombinatorp(:__comment__, comment)

  # Comma :: ,
  comma = string(",")

  # Punctuator :: one of ! $ ( ) ... : = @ [ ] { | }
  _punctuator =
    parsec(:__skip_ignored__)
    |> choice([
      ascii_char([?!, ?$, ?(, ?), ?:, ?=, ?@, ?[, ?], ?{, ?|, ?}]),
      times(ascii_char([?.]), 3)
    ])
    |> parsec(:__skip_ignored__)

  # Ignored ::
  #   - UnicodeBOM
  #   - WhiteSpace
  #   - LineTerminator
  #   - Comment
  #   - Comma
  ignored =
    choice([
      unicode_bom,
      whitespace,
      line_terminator,
      parsec(:__comment__),
      comma
    ])

  # Name :: /[_A-Za-z][_0-9A-Za-z]*/
  defcombinatorp(
    :__name__,
    parsec(:__skip_ignored__)
    |> ascii_char([?_, ?A..?Z, ?a..?z])
    |> repeat(ascii_char([?_, ?0..?9, ?A..?Z, ?a..?z]))
    |> parsec(:__skip_ignored__)
    |> post_traverse({Utils, :build_string, []})
  )

  defcombinatorp(
    :__skip_ignored__,
    repeat(ignore(ignored))
  )

  # NegativeSign :: -
  negative_sign =
    ascii_char([?-])

  # Digit :: one of 0 1 2 3 4 5 6 7 8 9
  digit =
    ascii_char([?0..?9])

  # NonZeroDigit :: Digit but not 0
  non_zero_digit =
    ascii_char([?1..?9])

  # Sign :: one of + -
  sign =
    ascii_char([?+, ?-])

  # ExponentIndicator :: one of e E
  exponent_indicator =
    ascii_char([?e, ?E])

  integer_part =
    optional(negative_sign)
    |> choice([
      ascii_char([?0]),
      non_zero_digit |> repeat(digit)
    ])

  # IntValue :: IntegerPart
  int_value =
    parsec(:__skip_ignored__)
    |> concat(integer_part)
    |> parsec(:__skip_ignored__)
    |> post_traverse({Utils, :build_int, []})

  defcombinatorp(:__int_value__, int_value)

  fractional_part =
    ascii_char([?.])
    |> times(digit, min: 1)

  exponent_part =
    exponent_indicator
    |> optional(sign)
    |> times(digit, min: 1)

  float_value =
    parsec(:__skip_ignored__)
    |> choice([
      integer_part
      |> concat(fractional_part)
      |> concat(exponent_part),
      integer_part
      |> post_traverse({Utils, :fill_mantissa, []})
      |> concat(exponent_part),
      integer_part
      |> concat(fractional_part)
    ])
    |> parsec(:__skip_ignored__)
    |> post_traverse({Utils, :build_float, []})

  defcombinatorp(:__float_value__, float_value)

  escaped_character =
    choice([
      ascii_char([?"]),
      ascii_char([?\\]),
      ascii_char([?/]),
      ascii_char([?b]) |> replace(?\b),
      ascii_char([?f]) |> replace(?\f),
      ascii_char([?n]) |> replace(?\n),
      ascii_char([?r]) |> replace(?\r),
      ascii_char([?t]) |> replace(?\t)
    ])

  boolean_value =
    choice([
      Utils.__string__("true") |> replace(true),
      Utils.__string__("false") |> replace(false)
    ])

  escaped_unicode =
    times(ascii_char([?0..?9, ?A..?F, ?a..?f]), 4)
    |> post_traverse({Utils, :unescape_unicode, []})

  string_character =
    choice([
      ignore(string(~S(\u))) |> concat(escaped_unicode),
      ignore(ascii_char([?\\])) |> concat(escaped_character),
      source_character
    ])

  block_string_character =
    choice([
      ignore(ascii_char([?\\])) |> times(ascii_char([?"]), 3),
      source_character
    ])

  string_value =
    parsec(:__skip_ignored__)
    |> choice([
      # `"` StringCharacter* `"`
      ignore(ascii_char([?"]))
      |> post_traverse({Utils, :mark_string_start, []})
      |> repeat_while(string_character, {Utils, :not_end_of_quote, []})
      |> ignore(ascii_char([?"]))
      |> post_traverse({Utils, :build_string, []}),
      # `"""` BlockStringCharacter* `"""`
      ignore(string(~S(""")))
      |> post_traverse({Utils, :mark_block_string_start, []})
      |> repeat_while(block_string_character, {Utils, :not_end_of_block_quote, []})
      |> ignore(string(~S(""")))
      |> post_traverse({Utils, :build_block_string, []})
    ])
    |> parsec(:__skip_ignored__)

  defcombinatorp(:__string_value__, string_value)

  null_value =
    Utils.__string__("null") |> replace(nil)

  enum_value =
    parsec(:__name__) |> tag(:value)
    |> post_traverse({Utils, :check_name, [~w(true false null)]})
    |> post_traverse({Utils, :build_struct, [Language.EnumValue]})

  variable =
    ignore(Utils.__ascii_char__([?$]))
    |> concat(parsec(:__name__) |> tag(:name))
    |> post_traverse({Utils, :build_struct, [Language.Variable]})

  description = parsec(:__string_value__)

  defcombinatorp(:__description__, description)

  named_type =
    parsec(:__name__) |> tag(:name)
    |> post_traverse({Utils, :build_struct, [Language.NamedType]})

  defcombinatorp(:__named_type__, named_type)

  operation_type =
    choice([
      Utils.__string__("query") |> replace(:query),
      Utils.__string__("mutation") |> replace(:mutation),
      Utils.__string__("subscription") |> replace(:subscription)
    ])

  list_type =
    ignore(Utils.__ascii_char__([?[]))
    |> concat(parsec(:__type__) |> tag(:type))
    |> ignore(Utils.__ascii_char__([?]]))
    |> post_traverse({Utils, :build_struct, [Language.ListType]})

  non_null_type =
    choice([
      parsec(:__named_type__),
      list_type
    ]) |> tag(:type)
    |> ignore(Utils.__ascii_char__([?!]))
    |> post_traverse({Utils, :build_struct, [Language.NonNullType]})

  defcombinatorp(
    :__type__,
    choice([
      parsec(:__named_type__),
      list_type,
      non_null_type
    ])
  )

  list_value =
    ignore(Utils.__ascii_char__([?[]))
    |> repeat(parsec(:__value__)) |> tag(:values)
    |> ignore(Utils.__ascii_char__([?]]))
    |> post_traverse({Utils, :build_struct, [Language.ListValue]})

  object_field =
    parsec(:__name__) |> tag(:name)
    |> ignore(Utils.__ascii_char__([?:]))
    |> concat(parsec(:__value__) |> tag(:value))
    |> post_traverse({Utils, :build_struct, [Language.ObjectField]})

  object_value =
    ignore(Utils.__ascii_char__([?{]))
    |> repeat(object_field) |> tag(:fields)
    |> ignore(Utils.__ascii_char__([?}]))
    |> post_traverse({Utils, :build_struct, [Language.ObjectValue]})

  defcombinatorp(
    :__value__,
    choice([
      variable,
      parsec(:__int_value__),
      parsec(:__float_value__),
      parsec(:__string_value__),
      boolean_value,
      null_value,
      enum_value,
      list_value,
      object_value
    ])
  )

  default_value =
    ignore(Utils.__ascii_char__([?=]))
    |> parsec(:__value__)
    |> post_traverse({Utils, :build_struct, [Language.DefaultValue]})

  defcombinatorp(:__default_value__, default_value)

  argument =
    parsec(:__name__) |> tag(:name)
    |> ignore(Utils.__ascii_char__([?:]))
    |> concat(parsec(:__value__) |> tag(:value))
    |> post_traverse({Utils, :build_struct, [Language.Argument]})

  arguments =
    ignore(Utils.__ascii_char__([?(]))
    |> times(argument, min: 1)
    |> ignore(Utils.__ascii_char__([?)]))

  defcombinatorp(:__arguments__, arguments)

  directive =
    ignore(Utils.__ascii_char__([?@]))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__arguments__) |> tag(:arguments))
    |> post_traverse({Utils, :build_struct, [Language.Directive]})

  defcombinatorp(
    :__directives__,
    times(directive, min: 1)
  )

  alias! =
    parsec(:__name__)
    |> ignore(Utils.__ascii_char__([?:]))

  field =
    optional(alias! |> tag(:alias))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__arguments__) |> tag(:arguments))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> optional(parsec(:__selection_set__) |> tag(:selections))
    |> post_traverse({Utils, :build_struct, [Language.Field]})

  fragment_name =
    parsec(:__name__)
    |> post_traverse({Utils, :check_name, [["on"]]})

  fragment_spread =
    ignore(Utils.__string__("..."))
    |> concat(fragment_name |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> post_traverse({Utils, :build_struct, [Language.FragmentSpread]})

  type_condition =
    ignore(Utils.__string__("on"))
    |> concat(parsec(:__named_type__))

  inline_fragment =
    ignore(Utils.__string__("..."))
    |> optional(type_condition |> tag(:type_condition))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> ignore(parsec(:__selection_set__) |> tag(:selections))
    |> post_traverse({Utils, :build_struct, [Language.InlineFragment]})

  selection =
    choice([
      field,
      fragment_spread,
      inline_fragment
    ])

  defcombinatorp(
    :__selection_set__,
    ignore(Utils.__ascii_char__([?{]))
    |> times(selection, min: 1)
    |> ignore(Utils.__ascii_char__([?}]))
  )

  defcombinatorp(
    :__implements_interfaces__,
    choice([
      ignore(Utils.__string__("implements"))
      |> ignore(optional(Utils.__ascii_char__([?&])))
      |> concat(parsec(:__named_type__)),
      parsec(:__implements_interfaces__)
      |> ignore(optional(Utils.__ascii_char__([?&])))
      |> concat(parsec(:__named_type__))
    ])
  )

  input_value_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> concat(parsec(:__name__) |> tag(:name))
    |> ignore(Utils.__ascii_char__([?:]))
    |> concat(parsec(:__type__) |> tag(:type))
    |> optional(parsec(:__default_value__) |> tag(:default_value))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> post_traverse({Utils, :build_struct, [Language.InputValueDefinition]})

  input_fields_definition =
    ignore(Utils.__ascii_char__([?{]))
    |> times(input_value_definition, min: 1)
    |> ignore(Utils.__ascii_char__([?}]))

  arguments_definition =
    ignore(Utils.__ascii_char__([?(]))
    |> times(input_value_definition, min: 1)
    |> ignore(Utils.__ascii_char__([?)]))

  defcombinatorp(:__arguments_definition__, arguments_definition)

  field_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__arguments_definition__) |> tag(:arguments))
    |> ignore(Utils.__ascii_char__([?:]))
    |> concat(parsec(:__type__) |> tag(:type))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> post_traverse({Utils, :build_struct, [Language.FieldDefinition]})

  fields_definition =
    ignore(Utils.__ascii_char__([?{]))
    |> times(field_definition, min: 1)
    |> ignore(Utils.__ascii_char__([?}]))

  object_type_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("type"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> choice([
      optional(parsec(:__implements_interfaces__) |> tag(:interfaces))
      |> optional(parsec(:__directives__) |> tag(:directives))
      |> concat(fields_definition) |> tag(:fields),
      optional(parsec(:__implements_interfaces__) |> tag(:interfaces))
      |> concat(parsec(:__directives__) |> tag(:directives)),
      parsec(:__implements_interfaces__) |> tag(:interfaces)
    ])
    |> post_traverse({Utils, :build_struct, [Language.ObjectTypeExtension]})

  enum_value_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> concat(enum_value |> tag(:value))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> post_traverse({Utils, :build_struct, [Language.EnumValueDefinition]})

  enum_values_definition =
    ignore(Utils.__ascii_char__([?{]))
    |> times(enum_value_definition, min: 1)
    |> ignore(Utils.__ascii_char__([?}]))

  enum_type_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> ignore(Utils.__string__("enum"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> optional(enum_values_definition |> tag(:values))
    |> post_traverse({Utils, :build_struct, [Language.EnumTypeDefinition]})

  defcombinatorp(
    :__union_member_types__,
    choice([
      ignore(Utils.__ascii_char__([?=]))
      |> ignore(optional(Utils.__ascii_char__([?|])))
      |> parsec(:__name__),
      parsec(:__union_member_types__)
      |> ignore(Utils.__ascii_char__([?|]))
      |> parsec(:__name__)
    ])
  )

  union_type_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> ignore(Utils.__string__("union"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> optional(parsec(:__union_member_types__) |> tag(:types))
    |> post_traverse({Utils, :build_struct, [Language.UnionTypeDefinition]})

  interface_type_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> ignore(Utils.__string__("interface"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> optional(fields_definition |> tag(:fields))
    |> post_traverse({Utils, :build_struct, [Language.InterfaceTypeDefinition]})

  object_type_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> ignore(Utils.__string__("type"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__implements_interfaces__) |> tag(:interfaces))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> optional(fields_definition |> tag(:fields))
    |> post_traverse({Utils, :build_struct, [Language.ObjectTypeDefinition]})

  scalar_type_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> ignore(Utils.__string__("scalar"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> post_traverse({Utils, :build_struct, [Language.ScalarTypeDefinition]})

  input_object_type_definition =
    optional(parsec(:__description__) |> tag(:description))
    |> ignore(Utils.__string__("input"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> optional(input_fields_definition |> tag(:input_fields))
    |> post_traverse({Utils, :build_struct, [Language.InputObjectTypeDefinition]})

  input_object_type_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("input"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> choice([
      optional(parsec(:__directives__) |> tag(:directives))
      |> concat(input_fields_definition |> tag(:input_fields)),
      parsec(:__directives__)
    ])
    |> post_traverse({Utils, :build_struct, [Language.InputObjectTypeExtension]})

  executable_directive_location =
    choice([
      Utils.__string__("QUERY") |> replace(:query),
      Utils.__string__("MUTATION") |> replace(:mutation),
      Utils.__string__("SUBSCRIPTION") |> replace(:subscription),
      Utils.__string__("FIELD") |> replace(:field),
      Utils.__string__("FRAGMENT_DEFINITION") |> replace(:fragment_definition),
      Utils.__string__("FRAGMENT_SPREAD") |> replace(:fragment_spread),
      Utils.__string__("INLINE_FRAGMENT") |> replace(:inline_fragment)
    ])

  type_system_directive_location =
    choice([
      Utils.__string__("SCHEMA") |> replace(:schema),
      Utils.__string__("SCALAR") |> replace(:scalar),
      Utils.__string__("OBJECT") |> replace(:object),
      Utils.__string__("FIELD_DEFINITION") |> replace(:field_definition),
      Utils.__string__("ARGUMENT_DEFINITION") |> replace(:argument_definition),
      Utils.__string__("INTERFACE") |> replace(:interface),
      Utils.__string__("UNION") |> replace(:union),
      Utils.__string__("ENUM") |> replace(:enum),
      Utils.__string__("ENUM_VALUE") |> replace(:enum_value),
      Utils.__string__("INPUT_OBJECT") |> replace(:input_object),
      Utils.__string__("INPUT_FIELD_DEFINITION") |> replace(:input_field_definition)
    ])

  directive_location =
    choice([
      executable_directive_location,
      type_system_directive_location
    ])

  defcombinatorp(
    :__directive_locations__,
    choice([
      ignore(optional(Utils.__ascii_char__([?|])))
      |> concat(directive_location),
      parsec(:__directive_locations__)
      |> ignore(Utils.__ascii_char__([?|]))
      |> concat(directive_location)
    ])
  )

  directive_definition =
    optional(parsec(:__description__))
    |> ignore(Utils.__string__("directive"))
    |> ignore(Utils.__ascii_char__([?@]))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__arguments_definition__) |> tag(:argument))
    |> ignore(Utils.__string__("on"))
    |> concat(parsec(:__directive_locations__) |> tag(:locations))
    |> post_traverse({Utils, :build_struct, [Language.DirectiveDefinition]})

  type_definition =
    choice([
      scalar_type_definition,
      object_type_definition,
      interface_type_definition,
      union_type_definition,
      enum_type_definition,
      input_object_type_definition
    ])

  scalar_type_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("scalar"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> post_traverse({Utils, :build_struct, [Language.ScalarTypeExtension]})

  interface_type_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("interface"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> choice([
      optional(parsec(:__directives__) |> tag(:directives))
      |> concat(fields_definition |> tag(:fields)),
      parsec(:__directives__) |> tag(:directives)
    ])
    |> post_traverse({Utils, :build_struct, [Language.InterfaceTypeExtension]})

  union_type_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("union"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> choice([
      optional(parsec(:__directives__) |> tag(:directives))
      |> concat(parsec(:__union_member_types__) |> tag(:types)),
      parsec(:__directives__) |> tag(:directives)
    ])
    |> post_traverse({Utils, :build_struct, [Language.UnionTypeExtension]})

  enum_type_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("enum"))
    |> concat(parsec(:__name__) |> tag(:name))
    |> choice([
      optional(parsec(:__directives__) |> tag(:directives))
      |> concat(enum_values_definition |> tag(:values)),
      parsec(:__directives__) |> tag(:directives)
    ])
    |> post_traverse({Utils, :build_struct, [Language.EnumTypeExtension]})

  type_extension =
    choice([
      scalar_type_extension,
      object_type_extension,
      interface_type_extension,
      union_type_extension,
      enum_type_extension,
      input_object_type_extension
    ])

  operation_type_definition =
    operation_type |> tag(:operation)
    |> ignore(Utils.__ascii_char__([?:]))
    |> concat(parsec(:__name__) |> tag(:name))
    |> post_traverse({Utils, :build_struct, [Language.OperationTypeDefinition]})

  schema_extension =
    ignore(Utils.__string__("extend"))
    |> ignore(Utils.__string__("schema"))
    |> choice([
      optional(parsec(:__directives__) |> tag(:directives))
      |> ignore(Utils.__ascii_char__([?{]))
      |> times(operation_type_definition |> tag(:operations), min: 1)
      |> ignore(Utils.__ascii_char__([?}])),
      parsec(:__directives__) |> tag(:directives)
    ])
    |> post_traverse({Utils, :build_struct, [Language.SchemaExtension]})

  type_system_extension =
    choice([
      schema_extension,
      type_extension
    ])

  schema_definition =
    ignore(Utils.__string__("schema"))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> ignore(Utils.__ascii_char__([?{]))
    |> concat(times(operation_type_definition, min: 1) |> tag(:operations))
    |> ignore(Utils.__ascii_char__([?}]))
    |> post_traverse({Utils, :build_struct, [Language.SchemaDefinition]})

  type_system_definition =
    choice([
      schema_definition,
      type_definition,
      directive_definition
    ])

  variable_definition =
    variable |> tag(:variable)
    |> ignore(Utils.__ascii_char__([?:]))
    |> concat(parsec(:__type__) |> tag(:type))
    |> optional(parsec(:__default_value__) |> tag(:default_value))
    |> post_traverse({Utils, :build_struct, [Language.VariableDefinition]})

  variable_definitions =
    ignore(Utils.__ascii_char__([?(]))
    |> times(variable_definition, min: 1)
    |> ignore(Utils.__ascii_char__([?)]))

  operation_definition =
    choice([
      operation_type |> tag(:operation)
      |> optional(parsec(:__name__) |> tag(:name))
      |> optional(variable_definitions |> tag(:variables))
      |> optional(parsec(:__directives__) |> tag(:directives))
      |> concat(parsec(:__selection_set__) |> tag(:selections)),
      parsec(:__selection_set__) |> tag(:selections)
    ])
    |> post_traverse({Utils, :build_struct, [Language.OperationDefinition]})

  fragment_definition =
    ignore(Utils.__string__("fragment"))
    |> concat(fragment_name |> tag(:name))
    |> concat(type_condition |> tag(:type_condition))
    |> optional(parsec(:__directives__) |> tag(:directives))
    |> concat(parsec(:__selection_set__) |> tag(:selections))
    |> post_traverse({Utils, :build_struct, [Language.FragmentDefinition]})

  executable_definition =
    choice([
      operation_definition,
      fragment_definition
    ])

  definition =
    choice([
      executable_definition,
      type_system_definition,
      type_system_extension
    ])

  defparsec(
    :__document__,
    times(definition, min: 1) |> tag(:definitions)
    |> post_traverse({Utils, :build_struct, [Language.Document]})
  )
end
