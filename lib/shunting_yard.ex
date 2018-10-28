defmodule ShuntingYard do
  @moduledoc """
  Implementation of a basic [shunting-yard algorithm](https://en.wikipedia.org/wiki/Shunting-yard_algorithm)
  for parsing algebraic expressions.

      iex> ShuntingYard.to_rpn("(1+2)*(3+4)")
      [1, 2, "+", 3, 4, "+", "*"]

      iex> ShuntingYard.to_ast("(1+2)*(3+4)")
      {"*", {"+", 1, 2}, {"+", 3, 4}}
  """

  @type expr :: String.t()
  @type acc_tuple :: {str_list, opers, acc, prev_op?}
  @type str_list :: list(String.t())
  @type op :: String.t()
  @type opers :: list(op)
  @type acc :: list(String.t() | number)
  @type prev_op? :: boolean

  @op_rules %{
    "," => [precedence: 0, assoc: :left],
    "+" => [precedence: 1, assoc: :left],
    "-" => [precedence: 1, assoc: :left],
    "*" => [precedence: 2, assoc: :left],
    "/" => [precedence: 2, assoc: :left],
    "^" => [precedence: 2, assoc: :right],
    "d" => [precedence: 3, assoc: :left],
    "%" => [precedence: 3, assoc: :left]
  }

  @doc "Convert the algebraic expression string to reverse-polish notation."
  @spec to_rpn(expr) :: list(number | op)
  def to_rpn(expr) do
    expr
    |> String.replace(~r/\s/, "")
    |> String.codepoints()
    |> Enum.reduce({[], [], [], true}, fn char, {str_list, opers, acc, prev_op?} ->
      to_rpn(char, {str_list, opers, acc, prev_op?})
    end)
    |> convert()
  end

  @doc "Convert the algebraic expression string to a syntax tree."
  @spec to_ast(expr) :: tuple
  def to_ast(expr) when is_bitstring(expr) do
    expr
    |> to_rpn()
    |> to_ast([])
    |> final_ast()
  end

  @spec to_rpn(expr, acc_tuple) :: acc_tuple

  # numbers
  for n <- ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"] do
    def to_rpn(unquote(n), {num_str_list, opers, acc, _}),
      do: {[unquote(n)] ++ num_str_list, opers, acc, false}
  end

  def to_rpn(".", {num_str_list, opers, acc, prev_op?}),
    do: {["."] ++ num_str_list, opers, acc, prev_op?}

  # parentheses
  def to_rpn("(", {[], opers, acc, _}), do: {[], ["("] ++ opers, acc, true}

  def to_rpn(")", {str_list, opers, acc, prev_op?}) do
    flush_paren({[], opers, push_num_acc(str_list, acc), prev_op?})
  end

  # unary
  def to_rpn("-", {[], opers, acc, true}), do: {["-"], opers, acc, false}
  def to_rpn("+", {[], opers, acc, true}), do: {["+"], opers, acc, false}

  # operators
  for o <- Map.keys(@op_rules) do
    def to_rpn(unquote(o), {str_list, [], acc, _}) do
      {[], [unquote(o)], push_num_acc(str_list, acc), true}
    end

    def to_rpn(unquote(o), {str_list, opers, acc, _}) do
      flush_compare_op([], unquote(o), opers, push_num_acc(str_list, acc), true)
    end
  end

  # fail on anything else
  def to_rpn(char, _) do
    raise ArgumentError, "failed to parse expression starting at #{char}"
  end

  # converts acc_tuple into final acc
  @spec convert(acc_tuple) :: acc
  defp convert({[], opers, acc, _}), do: Enum.reverse(Enum.reverse(opers) ++ acc)

  defp convert({str_list, opers, acc, _}),
    do: Enum.reverse(Enum.reverse(opers) ++ push_num_acc(str_list, acc))

  # flush all operators back to parentheses
  @spec flush_paren(acc_tuple) :: acc_tuple

  defp flush_paren({_, [], _, _} = opers_acc), do: opers_acc
  defp flush_paren({str_list, ["(" | opers], acc, prev_op?}), do: {str_list, opers, acc, prev_op?}

  defp flush_paren({str_list, [op | opers], acc, prev_op?}),
    do: flush_paren({str_list, opers, [op] ++ acc, prev_op?})

  # flush operators based on precedence and associativity
  @spec flush_compare_op(str_list, op, opers, acc, prev_op?) :: acc_tuple

  defp flush_compare_op(str_list, comparable, [], acc, prev_op?),
    do: {str_list, [comparable], acc, prev_op?}

  defp flush_compare_op(str_list, comparable, ["("], acc, prev_op?),
    do: {str_list, [comparable], acc, prev_op?}

  defp flush_compare_op(str_list, comparable, [op | rest_ops] = opers, acc, prev_op?) do
    case compare_operators(comparable, op) do
      {:higher, _} -> {str_list, [comparable] ++ opers, acc, prev_op?}
      {:equal, :right} -> {str_list, [comparable] ++ opers, acc, prev_op?}
      {:lower, _} -> flush_compare_op(str_list, comparable, rest_ops, [op] ++ acc, prev_op?)
      {:equal, :left} -> flush_compare_op(str_list, comparable, rest_ops, [op] ++ acc, prev_op?)
    end
  end

  # compare precedence and associativity for two operators
  @spec compare_operators(op, op) :: {:higher | :equal | :lower, :right | :left}
  defp compare_operators(op_1, "(") do
    {:higher, @op_rules[op_1][:assoc]}
  end

  defp compare_operators(op_1, op_2) do
    {compare_precedence(op_1, op_2), @op_rules[op_1][:assoc]}
  end

  defp compare_precedence(op_1, op_2) do
    cond do
      @op_rules[op_1][:precedence] > @op_rules[op_2][:precedence] -> :higher
      @op_rules[op_1][:precedence] == @op_rules[op_2][:precedence] -> :equal
      @op_rules[op_1][:precedence] < @op_rules[op_2][:precedence] -> :lower
    end
  end

  # join a list of number strings, convert the list to a number, and add it to acc
  @spec push_num_acc(str_list, acc) :: acc

  defp push_num_acc([], acc), do: acc
  defp push_num_acc(str_list, acc), do: [str_list_to_num(str_list)] ++ acc

  @spec str_list_to_str(str_list) :: String.t()
  defp str_list_to_str(str_list), do: str_list |> Enum.reverse() |> Enum.join("")

  @spec str_list_to_num(str_list) :: number
  defp str_list_to_num(str_list) do
    str = str_list_to_str(str_list)

    case String.contains?(str, ".") do
      true -> String.to_float(str)
      false -> String.to_integer(str)
    end
  end

  @spec to_ast(list(number | op), list(tuple | number)) :: list(tuple)

  defp to_ast([], l_acc), do: l_acc

  defp to_ast([l | rest], l_acc) when not is_bitstring(l) do
    to_ast(rest, [l] ++ l_acc)
  end

  defp to_ast([o | rest], l_acc) when is_bitstring(o) do
    [r, l | l_acc] = l_acc
    to_ast(rest, [{o, l, r}] ++ l_acc)
  end

  # converts the final ast value to a tuple
  @spec final_ast(list) :: tuple
  defp final_ast([]), do: {}
  defp final_ast(list), do: hd(list)
end
