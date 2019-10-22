defmodule GraphqlSpec.Request do
  @moduledoc """
  """
  alias GraphqlSpec.{Language, Response}
  alias GraphqlSpec.Language.{Document, OperationDefinition, SchemaDefinition}

  @typedoc """
  """
  @type values :: %{optional(Language.name) => Language.value}

  @doc """
  """
  @spec get_operation(Document.t, Language.name) :: {:ok, OperationDefinition.t} | {:error, reason :: term}
  def get_operation(document, operation_name) do
    op_defs =
      Enum.filter(document.definitions, fn
        %OperationDefinition{} -> true
        _ -> false
      end)
    case {op_defs, operation_name} do
      {[op], nil} -> {:ok, op}
      {_, nil} -> query_error(:operation_name_required)
      {ops, op_name} ->
        Enum.find(ops, query_error(:operation_not_found), fn
          %{name: ^op_name} -> true
          _ -> false
        end)
    end
  end

  @spec query_error(reason) :: {:error, reason} when reason: term
  def query_error(reason) do
    {:error, {:query_error, reason}}
  end

  @doc """
  """
  @spec coerce_variable_values(SchemaDefinition.t, OperationDefinition.t, values) :: {:ok, values} | {:error, reason :: term}
  def coerce_variable_values(_schema, _operation, _variable_values) do
    {:ok, %{}}
  end

  @doc """
  """
  @spec execute_query(OperationDefinition.t, SchemaDefinition.t, values, values) :: {:ok, Response.t} | {:error, reason :: term}
  def execute_query(_query, _schema, _variable_values, _initial_value) do
    {:error, :not_implemented}
  end

  @doc """
  """
  @spec execute_mutation(OperationDefinition.t, SchemaDefinition.t, values, values) :: {:ok, Response.t} | {:error, reason :: term}
  def execute_mutation(_mutation, _schema, _variable_values, _initial_value) do
    {:error, :not_implemented}
  end

  @doc """
  """
  @spec execute_subscription(OperationDefinition.t, SchemaDefinition.t, values, values) :: {:ok, Response.t} | {:error, reason :: term}
  def execute_subscription(_subscription, _schema, _variable_values, _initial_value) do
    {:error, :not_implemented}
  end
end
