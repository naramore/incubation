defmodule GraphqlSpec do
  @moduledoc """
  """

  alias GraphqlSpec.{Interpreter, Language, Response, Request, Validation}
  alias GraphqlSpec.Language.{Document, OperationDefinition, SchemaDefinition}

  @doc """
  """
  @spec parse(binary) :: {:ok, Document.t} | {:error, reason :: term}
  def parse(data) do
    # TODO: improve error handling (e.g. make parse error structs + add line byte_offset -> char_offset conversion)
    try do
      case Interpreter.__document__(data) do
        {:ok, parsed, "", _context, _line, _byte_offset} ->
          {:ok, parsed}
        {:ok, parsed, rest, context, line, byte_offset} ->
          {:error, {:invalid_format, parsed, rest, context, line, byte_offset}}
        {:error, parsed, rest, context, line, byte_offset}
          {:error, {:parsing_error, parsed, rest, context, line, byte_offset}}
      end
    rescue
      reason -> {:error, reason}
    end
  end

  @doc """
  """
  defmacro sigil_g(binary, [?c]) do
    result = parse(binary)
    quote do
      unquote(result)
    end
  end
  defmacro sigil_gql(binary, _modifiers) do
    quote do
      parse(unquote(binary))
    end
  end

  @doc """
  """
  @spec validate(Document.t, SchemaDefinition.t) :: :ok | {:error, reason :: term}
  def validate(document, schema) do
    Validation.validate(document, schema)
  end

  @doc """
  """
  @spec valid?(Document.t, SchemaDefinition.t) :: boolean
  def valid?(document, schema) do
    case validate(document, schema) do
      {:error, _} -> false
      :ok -> true
    end
  end

  @doc """
  """
  @spec execute_request(SchemaDefinition.t, Document.t, Language.name | nil, Request.values, Request.values) :: {:ok, Response.t} | {:error, reason :: term}
  def execute_request(schema, document, operation_name, variable_values, initial_values) do
    with {:ok, operation} <- Request.get_operation(document, operation_name),
         {:ok, coerced_variable_values} <- Request.coerce_variable_values(schema, operation, variable_values) do
      case operation do
        %OperationDefinition{operation: :query} ->
          Request.execute_query(operation, schema, coerced_variable_values, initial_values)
        %OperationDefinition{operation: :mutation} ->
          Request.execute_mutation(operation, schema, coerced_variable_values, initial_values)
        %OperationDefinition{operation: :subscription} ->
          Request.execute_subscription(operation, schema, coerced_variable_values, initial_values)
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec introspection_query_string() :: String.t
  def introspection_query_string() do
    """
    query IntrospectionQuery {
      __schema {
        queryType { name }
        mutationType { name }
        subscriptionType { name }
        types {
          ...FullType
        }
        directives {
          name
          description
          locations
          args {
            ...InputValue
          }
        }
      }
    }
    fragment FullType on __Type {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args {
          ...InputValue
        }
        type {
          ...TypeRef
        }
        isDeprecated
        deprecationReason
      }
      inputFields {
        ...InputValue
      }
      interfaces {
        ...TypeRef
      }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
        deprecationReason
      }
      possibleTypes {
        ...TypeRef
      }
    }
    fragment InputValue on __InputValue {
      name
      description
      type { ...TypeRef }
      defaultValue
    }
    fragment TypeRef on __Type {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                  ofType {
                    kind
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
    """
  end
end
