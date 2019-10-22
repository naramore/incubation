defprotocol GraphqlSpec.Validation do
  @moduledoc """
  """
  @fallback_to_any true

  @doc """
  """
  @spec validate(t, term) :: :ok | {:error, reason :: term}
  def validate(document, schema)
end

defimpl GraphqlSpec.Validation, for: Any do
  def validate(document, _schema) do
    {:error, {:not_implemented, document}}
  end
end
