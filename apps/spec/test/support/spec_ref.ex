defmodule SpecRef do
  use Spec.Func
  alias StreamData, as: SD

  def one_arity(_), do: nil
  def two_arity(_, _), do: nil
  def three_arity(_, _, _), do: nil
  def four_arity(_, _, _, _), do: nil

  def raise!(), do: raise %RuntimeError{}
  def throw!(), do: throw :throw
  def exit_normal!(), do: exit :normal
  def exit_abnormal!(), do: exit :abnormal

  def any(), do: fn _ -> true end
  def map_spec(), do: Spec.map_of(&is_atom/1, &is_bitstring/1)

  def clj_spec() do
    Spec.oom(
      Spec.alt(
        n: &is_number/1,
        s: Spec.also([
          Spec.oom(&is_bitstring/1),
          &Enum.all?(&1, f(fn s -> length(s) > 0 end))
        ])
      )
    )
  end

  def clj_spec_gen() do
    SD.list_of(
      SD.one_of([
        SD.one_of([SD.integer(), SD.float()]),
        SD.list_of(SD.string([?a..?z], min_length: 1), min_length: 1)
      ]),
      min_length: 1
    )
  end

  def clj_regexop() do
    Spec.oom(
      Spec.alt(
        n: &is_number/1,
        s: Spec.amp([
          Spec.oom(&is_bitstring/1),
          &Enum.all?(&1, f(fn s -> length(s) > 0 end))
        ])
      )
    )
  end

  def clj_regexop_gen() do
    SD.list_of(
      SD.one_of([
        SD.one_of([SD.integer(), SD.float()]),
        SD.string([?a..?z], min_length: 1)
      ]),
      min_length: 1
    )
  end
end
