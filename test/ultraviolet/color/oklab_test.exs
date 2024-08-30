defmodule OKLabTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.OKLab

  doctest OKLab

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0}},
    "white" => {{255, 255, 255, 1}, {1.0, 0, 0}},
    "gray" => {{128, 128, 128, 1}, {0.6, 0, 0}},
    "red" => {{255, 0, 0, 1}, {0.628, 0.225, 0.126}},
    "yellow" => {{255, 255, 0, 1}, {0.968, -0.071, 0.199}},
    "green" => {{0, 128, 0, 1}, {0.52, -0.14, 0.108}},
    "cyan" => {{0, 255, 255, 1}, {0.905, -0.149, -0.039}},
    "blue" => {{0, 0, 255, 1}, {0.452, -0.032, -0.312}},
    "magenta" => {{255, 0, 255, 1}, {0.702, 0.275, -0.169}}
  }

  for {name, {{r, g, b, a}, {l, a_star, b_star}}} <- cases do
    test "converts #{name} from OKLab to RGB properly" do
      assert {:ok, color} = Color.new(unquote(r), unquote(g), unquote(b), unquote(a))
      assert {:ok, lab} = OKLab.from_rgb(color, round: false)
      assert Float.round(lab.l_, 3) == unquote(l)
      assert Float.round(lab.a_, 3) == unquote(a_star)
      assert Float.round(lab.b_, 3) == unquote(b_star)
      assert lab.a == unquote(a)
      assert {:ok, ^color} = OKLab.to_rgb(lab)
    end
  end
end
