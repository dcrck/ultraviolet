defmodule HSLTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.HSL

  doctest HSL

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0.0}},
    "white" => {{255, 255, 255, 1}, {0, 0, 1.0}},
    "gray" => {{128, 128, 128, 1}, {0, 0, 0.5019607843137255}},
    "red" => {{255, 0, 0, 1}, {0, 1, 0.5}},
    "yellow" => {{255, 255, 0, 1}, {60, 1, 0.5}},
    "green" => {{0, 255, 0, 1}, {120, 1, 0.5}},
    "cyan" => {{0, 255, 255, 1}, {180, 1, 0.5}},
    "blue" => {{0, 0, 255, 1}, {240, 1, 0.5}},
    "magenta" => {{255, 0, 255, 1}, {300, 1, 0.5}},
  }

  for {name, {{r, g, b, a}, {h, s, l}}} <- cases do
    test "converts #{name} from HSL to RGB properly" do
      assert {:ok, color} = Color.new(unquote(r), unquote(g), unquote(b), unquote(a))
      assert {:ok, hsl} = HSL.from_rgb(color)
      assert hsl.h == unquote(h)
      assert hsl.s == unquote(s)
      assert hsl.l == unquote(l)
      assert hsl.a == unquote(a)
      assert {:ok, ^color} = HSL.to_rgb(hsl)
    end
  end
end
