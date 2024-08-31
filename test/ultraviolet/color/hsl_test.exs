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
    "dark magenta" => {{204, 0, 204, 1}, {300, 1, 0.4}}
  }

  for {name, {{r, g, b, a}, {h, s, l}}} <- cases do
    test "converts #{name} from HSL to RGB properly" do
      assert {:ok, color} = Color.new([unquote(r), unquote(g), unquote(b), unquote(a)])
      assert {:ok, hsl} = HSL.from_rgb(color)
      assert hsl.h == unquote(h)
      assert hsl.s == unquote(s)
      assert hsl.l == unquote(l)
      assert hsl.a == unquote(a)
      assert {:ok, ^color} = HSL.to_rgb(hsl)
    end
  end

  describe "new/1" do
    setup do
      {:ok, h: 0, s: 0, l: 0, a: 0.5}
    end

    test "constructs from tuples properly", ctx do
      assert {:ok, %HSL{}} = HSL.new({ctx.h, ctx.s, ctx.l})
      assert {:ok, %HSL{a: 0.5}} = HSL.new({ctx.h, ctx.s, ctx.l, ctx.a})
    end

    test "constructs from lists properly", ctx do
      assert {:ok, %HSL{}} = HSL.new([ctx.h, ctx.s, ctx.l])
      assert {:ok, %HSL{a: 0.5}} = HSL.new([ctx.h, ctx.s, ctx.l, ctx.a])
    end

    test "constructs from keyword lists properly", ctx do
      assert {:ok, %HSL{}} = HSL.new(Enum.into(Map.take(ctx, [:h, :s, :l]), []))
      assert {:ok, %HSL{a: 0.5}} = HSL.new(Enum.into(ctx, []))
    end

    test "constructs from maps properly", ctx do
      assert {:ok, %HSL{}} = HSL.new(Enum.into(Map.take(ctx, [:h, :s, :l]), %{}))
      assert {:ok, %HSL{a: 0.5}} = HSL.new(Enum.into(ctx, %{}))
    end
  end

  test "new/3 constructs an HSL color" do
    assert {:ok, %HSL{}} = HSL.new(0, 0, 0)
  end

  test "new/4 constructs an HSL color" do
    assert {:ok, %HSL{a: 0.5}} = HSL.new(0, 0, 0, 0.5)
  end
end
