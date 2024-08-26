defmodule OKLCHTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.OKLCH

  doctest OKLCH

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0}},
    "white" => {{255, 255, 255, 1}, {1.0, 0, 0}},
    "gray" => {{128, 128, 128, 1}, {0.6, 0, 0}},
    "red" => {{255, 0, 0, 1}, {0.628, 0.258, 29.234}},
    "yellow" => {{255, 255, 0, 1}, {0.968, 0.211, 109.763}},
    "green" => {{0, 128, 0, 1}, {0.52, 0.177, 142.495}},
    "cyan" => {{0, 255, 255, 1}, {0.905, 0.155, 194.757}},
    "blue" => {{0, 0, 255, 1}, {0.452, 0.313, 264.052}},
    "magenta" => {{255, 0, 255, 1}, {0.702, 0.322, 328.373}},
  }

  for {name, {{r, g, b, a}, {l, c, h}}} <- cases do
    test "converts #{name} from LCH to RGB properly" do
      assert {:ok, color} = Color.new(unquote(r), unquote(g), unquote(b), unquote(a))
      assert {:ok, lab} = OKLCH.from_rgb(color, round: false)
      assert Float.round(lab.l, 3) == unquote(l)
      assert Float.round(lab.c, 3) == unquote(c)
      case lab.h do
        0 -> assert unquote(h) == 0
        other -> assert Float.round(other, 3) == unquote(h)
      end
      assert lab.a == unquote(a)
      assert {:ok, ^color} = OKLCH.to_rgb(lab)
    end
  end
end
