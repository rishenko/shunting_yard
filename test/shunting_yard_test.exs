defmodule ShuntingYardTest do
  use ExUnit.Case
  doctest ShuntingYard

  describe "to_rpn" do
    test "simple" do
      assert [1, 2, "+", 3, "+"] == ShuntingYard.to_rpn("1+2+3")
      assert [1, 2, "*", 3, "+"] == ShuntingYard.to_rpn("1*2+3")
      assert [1, 2, 3, "*", "+"] == ShuntingYard.to_rpn("1+2*3")
      assert [1, 2, "+", 3, "*"] == ShuntingYard.to_rpn("(1+2) * 3")
      assert [1, 2, "+", 3, 4, "+", "*"] == ShuntingYard.to_rpn("(1+2)*(3+4)")
      assert [1, 2, 3, "^", "^"] == ShuntingYard.to_rpn("1^2^3")
    end

    test "complex" do
      assert [1, 2, "^", 2, "*", 3, 4, "^", "+"] == ShuntingYard.to_rpn("1^2*2+3^4")

      assert [1, 2, 3, "/", "-", 3, 4, 2, "*", "^", "*"] ==
               ShuntingYard.to_rpn("(1-2/3)*(3^(4*2))")

      assert [1, 4, "d", 5, 6, "d", 2, "%", 3.4, "/", "+", 3, 4, 2, "*", 5, 6, "d", "-", "^", "*"] ==
               ShuntingYard.to_rpn("(1d4+(5d6%2)/3.4)*(3^(4*2-5d6))")
    end

    test "negative unary" do
      assert [1, 2, "+", -3, "+"] == ShuntingYard.to_rpn("1+2+-3")
      assert [-1, -2, "+", -3, "+"] == ShuntingYard.to_rpn("-1+(-2)+-3")
      assert [-1.4, -2.5, "*", -3.6, "/"] == ShuntingYard.to_rpn("-1.4*-2.5/- 3.6")
      assert [-1, -2, "*", -3, "/"] == ShuntingYard.to_rpn("(-1*-2/- 3)")
    end

    test "positive unary" do
      assert [1, 2, "+", 3, "+"] == ShuntingYard.to_rpn("1+2++3")
      assert [1, 2, "+", 3, "+"] == ShuntingYard.to_rpn("+1+(+2)++3")
      assert [1.4, 2.5, "*", 3.6, "/"] == ShuntingYard.to_rpn("+1.4*+2.5/+ 3.6")
      assert [1, 2, "*", 3, "/"] == ShuntingYard.to_rpn("(+1*+2/+ 3)")
    end

    test "error" do
      assert_raise ArgumentError, fn -> ShuntingYard.to_rpn("x") end
    end
  end

  describe "to_ast" do
    test "simple" do
      assert {} == ShuntingYard.to_ast("")
      assert 1 == ShuntingYard.to_ast("1")
      assert {"+", {"+", 1, 2}, 3} == ShuntingYard.to_ast("1+2+3")
      assert {"+", {"*", 1, 2}, 3} == ShuntingYard.to_ast("1*2+3")
      assert {"+", 1, {"*", 2, 3}} == ShuntingYard.to_ast("1+2*3")
      assert {"*", {"+", 1, 2}, 3} == ShuntingYard.to_ast("(1+2)*3")
      assert {"*", {"+", 1, 2}, {"+", 3, 4}} == ShuntingYard.to_ast("(1+2)*(3+4)")
    end

    test "complex" do
      expected =
        {"*", {"+", {"d", 1, 4}, {"/", {"%", {"d", 5, 6}, 2}, 3.4}},
         {"^", 3, {"-", {"*", 4, 2}, {"d", 5, 6}}}}

      assert expected == ShuntingYard.to_ast("(1d4+(5d6%2)/3.4)*(3^(4*2-5d6))")
    end
  end
end
