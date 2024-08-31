# Ultraviolet

[![hex.pm badge](https://img.shields.io/badge/Package%20on%20hex.pm-informational)](https://hex.pm/packages/ultraviolet)
[![Documentation badge](https://img.shields.io/badge/Documentation-ff69b4)][docs]

[Online Documentation][docs].

An Elixir color manipulation library designed to work like
[`chroma-js`](https://github.com/gka/chroma.js). It may not have full parity
with `chroma-js`, but it includes most of the common operations and features.

## Quick Start

Here are a few things `Ultraviolet` can do:

- read colors from a wide range of inputs
- analyze and manipulate colors
- convert colors into a wide range of formats
- linear, bezier, and custom interpolation in different color spaces

Here's an example of a simple read / manipulate / output chain

```elixir
{:ok, color} = Ultraviolet.new("pink")

color
|> Ultraviolet.Color.darken!()
|> Ultraviolet.Color.saturate!(2)
|> Ultraviolet.Color.hex()
#=> "#ff6d93"
```

Aside from that, `Ultraviolet` can help you **generate nice colors** using
various methods. These colors can be used, for example, as a color palette for
maps or data visualization.

```elixir
{:ok, scale} = Ultraviolet.scale(["#fafa6e", "#2a4858"], space: :lch)
colors = Ultraviolet.Scale.take(scale, 6)
```

There's a lot more to offer; the [documentation][docs] contains more examples
of how to use `Ultraviolet`.

## Installation

You can install `ultraviolet` by adding it to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:ultraviolet, "~> 0.0.1"}
  ]
end
```

## License

Copyright 2024 Derek Meer

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the “Software”), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[docs]: https://hexdocs.pm/ultraviolet
