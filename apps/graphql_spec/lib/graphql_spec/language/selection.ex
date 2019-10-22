defmodule GraphqlSpec.Language.Selection do
  @moduledoc ~S"""
  SelectionSet : { Selection+ }

  Selection :
    - Field
    - FragmentSpread
    - InlineFragment

  An operation selects the set of information it needs, and will receive exactly
  that information and nothing more, avoiding over-fetching and
  under-fetching data.

  ```graphql example
  {
    id
    firstName
    lastName
  }
  ```

  In this query, the `id`, `firstName`, and `lastName` fields form a selection
  set. Selection sets may also contain fragment references.

  ## Note

  Taken from the [GraphQL specification](https://github.com/graphql/graphql-spec/blob/master/spec/Section%202%20--%20Language.md#selection-sets)
  """
  alias GraphqlSpec.Language.{Field, FragmentSpread, InlineFragment}

  @type t :: Field.t | FragmentSpread.t | InlineFragment.t
end
