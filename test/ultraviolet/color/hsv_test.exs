defmodule HSVTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.HSV

  doctest HSV

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0}},
    "white" => {{255, 255, 255, 1}, {0, 0, 1}},
    "gray" => {{127.5, 127.5, 127.5, 1}, {0, 0, 0.5}},
    "red" => {{255, 0, 0, 1}, {0, 1, 1}},
    "yellow" => {{255, 255, 0, 1}, {60, 1, 1}},
    "green" => {{0, 255, 0, 1}, {120, 1, 1}},
    "cyan" => {{0, 255, 255, 1}, {180, 1, 1}},
    "blue" => {{0, 0, 255, 1}, {240, 1, 1}},
    "magenta" => {{255, 0, 255, 1}, {300, 1, 1}}
  }

  for {name, {{r, g, b, a}, {h, s, v}}} <- cases do
    test "converts #{name} from HSV to RGB properly" do
      assert {:ok, color} = Color.new([unquote(r), unquote(g), unquote(b), unquote(a)])
      assert {:ok, hsv} = HSV.from_rgb(color)
      assert hsv.h == unquote(h)
      assert hsv.s == unquote(s)
      assert hsv.v == unquote(v)
      assert hsv.a == unquote(a)
      assert {:ok, color2} = HSV.to_rgb(hsv, round: 1)
      assert color.r == color2.r
      assert color.g == color2.g
      assert color.b == color2.b
      assert color.a == color2.a
    end
  end

  describe "new/1" do
    setup do
      {:ok, h: 0, s: 0, v: 0, a: 0.5}
    end

    test "constructs from tuples properly", ctx do
      assert {:ok, %HSV{}} = HSV.new({ctx.h, ctx.s, ctx.v})
      assert {:ok, %HSV{a: 0.5}} = HSV.new({ctx.h, ctx.s, ctx.v, ctx.a})
    end

    test "constructs from lists properly", ctx do
      assert {:ok, %HSV{}} = HSV.new([ctx.h, ctx.s, ctx.v])
      assert {:ok, %HSV{a: 0.5}} = HSV.new([ctx.h, ctx.s, ctx.v, ctx.a])
    end

    test "constructs from keyword lists properly", ctx do
      assert {:ok, %HSV{}} = HSV.new(Enum.into(Map.take(ctx, [:h, :s, :v]), []))
      assert {:ok, %HSV{a: 0.5}} = HSV.new(Enum.into(ctx, []))
    end

    test "constructs from maps properly", ctx do
      assert {:ok, %HSV{}} = HSV.new(Enum.into(Map.take(ctx, [:h, :s, :v]), %{}))
      assert {:ok, %HSV{a: 0.5}} = HSV.new(Enum.into(ctx, %{}))
    end
  end

  test "new/3 constructs an HSV color" do
    assert {:ok, %HSV{}} = HSV.new(0, 0, 0)
  end

  test "new/4 constructs an HSV color" do
    assert {:ok, %HSV{a: 0.5}} = HSV.new(0, 0, 0, 0.5)
  end
end
