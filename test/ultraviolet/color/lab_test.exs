defmodule LabTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.Lab

  doctest Lab

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0}},
    "white" => {{255, 255, 255, 1}, {100, 0, 0}},
    "gray" => {{128, 128, 128, 1}, {53.59, 0, 0}},
    "red" => {{255, 0, 0, 1}, {53.24, 80.09, 67.2}},
    "yellow" => {{255, 255, 0, 1}, {97.14, -21.55, 94.48}},
    "green" => {{0, 255, 0, 1}, {87.73, -86.18, 83.18}},
    "cyan" => {{0, 255, 255, 1}, {91.11, -48.09, -14.13}},
    "blue" => {{0, 0, 255, 1}, {32.3, 79.19, -107.86}},
    "magenta" => {{255, 0, 255, 1}, {60.32, 98.23, -60.82}}
  }

  for {name, {{r, g, b, a}, {l, a_star, b_star}}} <- cases do
    test "converts #{name} from L*a*b* to RGB properly" do
      assert {:ok, color} = Color.new(unquote(r), unquote(g), unquote(b), unquote(a))
      assert {:ok, lab} = Lab.from_rgb(color, round: false)
      assert Float.round(lab.l_, 2) == unquote(l)
      assert Float.round(lab.a_, 2) == unquote(a_star)
      assert Float.round(lab.b_, 2) == unquote(b_star)
      assert lab.a == unquote(a)
      assert {:ok, ^color} = Lab.to_rgb(lab)
    end
  end

  test "handles other reference illuminants" do
    {:ok, yellow_lab} = Lab.new(97.14, -21.55, 94.48)
    # defaults to :d65
    assert {:ok, %Color{r: 255, g: 255, b: 0, a: 1.0}} =
             Lab.to_rgb(yellow_lab)

    # alternate color returns alternate results
    assert {:ok, %Color{r: 243, g: 255, b: 0, a: 1.0}} =
             Lab.to_rgb(yellow_lab, reference: :d50)
  end
end
