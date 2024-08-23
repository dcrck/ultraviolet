defmodule HSVTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.HSV

  doctest HSV

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0}},
    "white" => {{255, 255, 255, 1}, {0, 0, 1}},
    "gray" => {{128, 128, 128, 1}, {0, 0, 0.5019607843137255}},
    "red" => {{255, 0, 0, 1}, {0, 1, 1}},
    "yellow" => {{255, 255, 0, 1}, {60, 1, 1}},
    "green" => {{0, 255, 0, 1}, {120, 1, 1}},
    "cyan" => {{0, 255, 255, 1}, {180, 1, 1}},
    "blue" => {{0, 0, 255, 1}, {240, 1, 1}},
    "magenta" => {{255, 0, 255, 1}, {300, 1, 1}},
  }

  for {name, {{r, g, b, a}, {h, s, v}}} <- cases do
    test "converts #{name} from HSV to RGB properly" do
      assert {:ok, color} = Color.new(unquote(r), unquote(g), unquote(b), unquote(a))
      assert {:ok, hsv} = HSV.from_rgb(color)
      assert hsv.h == unquote(h)
      assert hsv.s == unquote(s)
      assert hsv.v == unquote(v)
      assert hsv.a == unquote(a)
      assert {:ok, ^color} = HSV.to_rgb(hsv)
    end
  end
end
