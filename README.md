# Shunting-Yard Algorithm

This is a basic implementation of the [shunting-yard algorithm](https://en.wikipedia.org/wiki/Shunting-yard_algorithm)
in the elixir programming language. The `ShuntingYard` module converts [infix](https://en.wikipedia.org/wiki/Infix_notation)
(algebraic) notation to [postfix](https://en.wikipedia.org/wiki/Reverse_Polish_notation)
(reverse-polish) notation, including dice rolling (`d`) and modulo (`%`)
operators.

## Usage

```elixir
iex> ShuntingYard.to_rpn("(1+2)*(3+4)")
[1, 2, "+", 3, 4, "+", "*"]

iex> ShuntingYard.to_ast("(1+2)*(3+4)")
{"*", {"+", 1, 2}, {"+", 3, 4}}
```

Copyright (c) 2018 Kevin McAbee
