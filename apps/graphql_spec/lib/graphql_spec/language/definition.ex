defmodule GraphqlSpec.Language.Definition do
  alias GraphqlSpec.Language

  @type t ::
    executable_definition |
    type_system_definition |
    type_system_extension

  @type executable_definition ::
    Language.OperationDefinition.t |
    Language.FragmentDefinition.t

  @type type_system_definition ::
    Language.SchemaDefinition.t |
    type_definition |
    Language.DirectiveDefinition.t

  @type type_system_extension ::
    Language.SchemaExtension.t |
    type_extension

  @type type_definition ::
    Language.ScalarTypeDefinition.t |
    Language.ObjectTypeDefinition.t |
    Language.InterfaceTypeDefinition.t |
    Language.UnionTypeDefinition.t |
    Language.EnumTypeDefinition.t |
    Language.InputObjectTypeDefinition.t

  @type type_extension ::
    Language.ScalarTypeExtension.t |
    Language.ObjectTypeExtension.t |
    Language.InterfaceTypeExtension.t |
    Language.UnionTypeExtension.t |
    Language.EnumTypeExtension.t |
    Language.InputObjectTypeExtension.t
end
