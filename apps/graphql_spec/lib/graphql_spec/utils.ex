defmodule GraphqlSpec.Utils do
  @moduledoc """
  """

  import NimbleParsec, only: [empty: 0]

  @typedoc """
  """
  @type rest :: binary

  @typedoc """
  """
  @type args :: [...]

  @typedoc """
  """
  @type context :: map

  @typedoc """
  """
  @type line :: pos_integer

  @typedoc """
  """
  @type byte_offset :: pos_integer

  @typedoc """
  """
  @type repeat_while_result :: {:cont, context} | {:halt, context}

  @typedoc """
  """
  @type post_traverse_result(acc) :: {[acc], context} | {:error, reason :: term}

  @typedoc """
  """
  @type post_traverse_result :: post_traverse_result(term)

  @doc """
  """
  defmacro __ascii_char__(combinator \\ empty(), ranges) do
    quote do
      unquote(combinator)
      |> parsec(:__skip_ignored__)
      |> ascii_char(unquote(ranges))
      |> parsec(:__skip_ignored__)
    end
  end

  @doc """
  """
  defmacro __string__(combinator \\ empty(), binary) do
    quote do
      unquote(combinator)
      |> parsec(:__skip_ignored__)
      |> string(unquote(binary))
      |> parsec(:__skip_ignored__)
    end
  end

  @doc """
  """
  @spec not_line_terminator(rest, context, line, byte_offset) :: repeat_while_result
  def not_line_terminator(<<?\n, _::binary>>, context, _, _), do: {:halt, context}
  def not_line_terminator(<<?\r, _::binary>>, context, _, _), do: {:halt, context}
  def not_line_terminator(_, context, _, _), do: {:cont, context}

  @doc """
  """
  @spec build_struct(rest, args, context, line, byte_offset, module) :: post_traverse_result(struct)
  def build_struct(_rest, args, context, _line, _byte_offset, module) do
    {[module.fromTaggedList(args)], context}
  end

  @doc """
  """
  @spec build_map(rest, args, context, line, byte_offset, atom) :: post_traverse_result(map)
  def build_map(_rest, tagged_args, context, _line, _byte_offset, type) do
    mapped =
      tagged_args
      |> Enum.map(fn
        {tag, value} -> {tag, value}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})
      |> Map.put(:__struct__, type)
    {[mapped], context}
  end

  @doc """
  """
  @spec build_string(rest, args, context, line, byte_offset) :: post_traverse_result(String.t)
  def build_string(_rest, chars, context, _line, _byte_offset) do
    chars
    |> Enum.reverse()
    |> List.to_string()
    |> (&{[&1], Map.delete(context, :token_location)}).()
  end

  @doc """
  """
  @spec build_int(rest, args, context, line, byte_offset) :: post_traverse_result(integer)
  def build_int(_rest, digits, context, _line, _byte_offset) do
    case Enum.reverse(digits) do
      [?- | digits] ->
        {[List.to_integer(digits) * -1], context}
      digits ->
        {[List.to_integer(digits)], context}
    end
  end

  @doc """
  """
  @spec build_float(rest, args, context, line, byte_offset) :: post_traverse_result(float)
  def build_float(_rest, value, context, _line, _byte_offset) do
    value
    |> Enum.reverse()
    |> List.to_float()
    |> (&{[&1], context}).()
  end

  @doc """
  """
  @spec build_block_string(rest, args, context, line, byte_offset) :: post_traverse_result(String.t)
  def build_block_string(_rest, chars, context, _line, _byte_offset) do
    value = chars |> Enum.reverse() |> List.to_string()
    {[value], Map.delete(context, :token_location)}
  end

  @doc """
  """
  @spec fill_mantissa(rest, args, context, line, byte_offset) :: post_traverse_result(char)
  def fill_mantissa(_rest, raw, context, _line, _byte_offset) do
    {'0.' ++ raw, context}
  end

  @doc """
  """
  @spec not_end_of_quote(rest, context, line, byte_offset) :: repeat_while_result
  def not_end_of_quote(<<?", _::binary>>, context, _line, _byte_offset) do
    {:halt, context}
  end
  def not_end_of_quote(rest, context, current_line, current_offset) do
    not_line_terminator(rest, context, current_line, current_offset)
  end

  @doc """
  """
  @spec not_end_of_block_quote(rest, context, line, byte_offset) :: repeat_while_result
  def not_end_of_block_quote(<<?", ?", ?", _::binary>>, context, _, _) do
    {:halt, context}
  end
  def not_end_of_block_quote(_, context, _, _) do
    {:cont, context}
  end

  @doc """
  """
  @spec mark_string_start(rest, args, context, line, byte_offset) :: post_traverse_result(char)
  def mark_string_start(_rest, chars, context, loc, byte_offset) do
    {[chars], Map.put(context, :token_location, {loc, byte_offset})}
  end

  @doc """
  """
  @spec mark_block_string_start(rest, args, context, line, byte_offset) :: post_traverse_result
  def mark_block_string_start(_rest, _chars, context, loc, byte_offset) do
    {[], Map.put(context, :token_location, {loc, byte_offset})}
  end

  @doc """
  """
  @spec unescape_unicode(rest, args, context, line, byte_offset) :: post_traverse_result
  def unescape_unicode(_rest, content, context, _line, _byte_offset) do
    code = content |> Enum.reverse()
    value = :httpd_util.hexlist_to_integer(code)
    binary = :unicode.characters_to_binary([value])
    {[binary], context}
  end

  @doc """
  """
  @spec check_name(rest, args, context, line, byte_offset, [String.t]) :: post_traverse_result
  def check_name(_rest, [name], context, _line, _byte_offset, names) do
    if name in names do
      {:error, {:invalid_name, name}}
    else
      {[name], context}
    end
  end

  @doc """
  """
  @spec into(rest, args, context, line, byte_offset, Collectable.t) :: post_traverse_result(Collectable.t)
  def into(_rest, value, context, _line, _byte_offset, collectable) do
    value
    |> Enum.reverse()
    |> Enum.into(collectable)
    |> (&{[&1], context}).()
  end
end
