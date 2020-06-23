defmodule EQL do
  alias EQL.{AST, Error, Utils}
  require EQL.Utils

  @type result(x, reason) :: {:ok, x} | {:error, reason}
  @type result(x) :: result(x, Error.t)

  @type query :: [expr]
  @type expr ::
    property |
    join |
    ident |
    mutation |
    param_expr
  @type mutation :: mutation_expr | mutation_join
  @type mutation_join :: %{required(mutation_expr) => query}
  @type mutation_expr :: {module, atom, [any]}
  @type join_key_param_expr :: {join_key_param_key, params}
  @type join_key_param_key :: property | ident
  @type param_expr :: {param_expr_key, params}
  @type param_expr_key :: property | join | ident
  @type params :: map
  @type join_query :: query | union | recursion
  @type recursion :: non_neg_integer | :infinity
  @type union :: %{required(property) => query}
  @type join :: %{required(join_key) => join_query}
  @type join_key :: property | ident | join_key_param_expr
  @type ident_or_property :: property | ident
  @type ident :: [property | ident_value]
  @type ident_value :: any
  @type property :: atom | {module, atom}

  @spec query_to_ast(query) :: result(AST.t)
  def query_to_ast(query) do
    AST.Root.from_query(query)
  end

  @spec expr_to_ast(query | expr) :: result(AST.t | [AST.t])
  def expr_to_ast(prop) when Utils.is_property(prop) do
    AST.Property.from_query(prop)
  end
  def expr_to_ast(ident) when Utils.is_ident(ident) do
    AST.Property.from_query(ident)
  end
  def expr_to_ast({_, %{}} = expr) do
    AST.Params.from_query(expr)
  end
  def expr_to_ast(join) when Utils.is_join(join) do
    AST.Join.from_query(join)
  end
  def expr_to_ast(union) when Utils.is_union(union) do
    AST.Union.from_query(union)
  end
  def expr_to_ast(query) when is_list(query) do
    Enum.reduce_while(query, {:ok, []}, fn
      _, {:error, reason} -> {:halt, {:error, reason}}
      expr, {:ok, acc} ->
        case expr_to_ast(expr) do
          {:error, reason} -> {:halt, {:error, reason}}
          {:ok, ast} -> {:cont, {:ok, [ast | acc]}}
        end
    end)
  end
  def expr_to_ast({_, _, _} = mutation) do
    AST.Call.from_query(mutation)
  end
  def expr_to_ast(expr) do
    {:error, Error.new(:invalid_expression, expr)}
  end

  # @spec ast->expr(AST.t) :: result(expr)
  # @spec ast->query(AST.t) :: result(query)
  # @spec ident?(any) :: boolean
  # @spec focus_subquery(query, query) :: result(expr)
  # @spec union_children?(AST.t) :: boolean
  # @spec merge_asts(AST.t, AST.t) :: result(AST.t)
  # @spec merge_queries(query, query) :: result(query)
  # @spec mask_query(query, query) :: result(query)
  # @spec normalize_query_variables(query) :: result(query)
  # @spec query_id(query, hash_fun) :: hash
end
