defprotocol GraphqlSpec.Encoder do
  @moduledoc """
  """
  @fallback_to_any true

  @doc """
  """
  @spec encode(t, Keyword.t) :: String.t
  def encode(document, opts \\ [])
end

defimpl GraphqlSpec.Encoder, for: Any do
  def encode(document, _opts) do
    try do
      to_string(document)
    rescue
      _ -> ""
    end
  end
end

# TODO: implement Inspect protocol, remove GraphqlSpec.Encoder

defimpl GraphqlSpec.Encoder, for: Integer do
  def encode(integer, _opts \\ []) do
    to_string(integer)
  end
end

defimpl GraphqlSpec.Encoder, for: Float do
  def encode(float, _opts \\ []) do
    to_string(float)
  end
end

defimpl GraphqlSpec.Encoder, for: String do
  def encode(string, _opts \\ []) do
    if String.contains?(string, "\n") do
      "\"\"\"#{string}\"\"\""
    else
      "\"#{string}\""
    end
  end
end

defimpl GraphqlSpec.Encoder, for: Boolean do
  def encode(boolean, _opts \\ []) do
    to_string(boolean)
  end
end

defimpl GraphqlSpec.Encoder, for: Atom do
  def encode(atom, opts \\ [])
  def encode(nil, _opts) do
    "null"
  end
  def encode(atom, _opts) do
    to_string(atom)
  end
end

defimpl GraphqlSpec.Encoder, for: List do
  def encode(list, opts \\ []) do
    joiner = Keyword.get(opts, :joiner, "\n")

    list
    |> Enum.map(&GraphqlSpec.Encoder.encode/1)
    |> Enum.join(joiner)
  end
end
