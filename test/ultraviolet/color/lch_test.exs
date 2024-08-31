defmodule LCHTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.LCH

  doctest LCH

  cases = %{
    "black" => {{0, 0, 0, 1}, {0, 0, 0}},
    "white" => {{255, 255, 255, 1}, {100, 0, 0}},
    "gray" => {{128, 128, 128, 1}, {53.59, 0, 0}},
    "red" => {{255, 0, 0, 1}, {53.24, 104.55, 40.0}},
    "yellow" => {{255, 255, 0, 1}, {97.14, 96.91, 102.85}},
    "green" => {{0, 255, 0, 1}, {87.73, 119.78, 136.02}},
    "cyan" => {{0, 255, 255, 1}, {91.11, 50.12, 196.38}},
    "blue" => {{0, 0, 255, 1}, {32.3, 133.81, 306.28}},
    "magenta" => {{255, 0, 255, 1}, {60.32, 115.54, 328.23}}
  }

  for {name, {{r, g, b, a}, {l, c, h}}} <- cases do
    test "converts #{name} from LCH to RGB properly" do
      assert {:ok, color} = Color.new([unquote(r), unquote(g), unquote(b), unquote(a)])
      assert {:ok, lab} = LCH.from_rgb(color, round: false)
      assert Float.round(lab.l, 2) == unquote(l)
      assert Float.round(lab.c, 2) == unquote(c)

      case lab.h do
        0 -> assert unquote(h) == 0
        other -> assert Float.round(other, 2) == unquote(h)
      end

      assert lab.a == unquote(a)
      assert {:ok, ^color} = LCH.to_rgb(lab)
    end
  end

  describe "new/1" do
    setup do
      {:ok, l: 0, c: 0, h: 0, a: 0.5}
    end

    test "constructs from tuples properly", ctx do
      assert {:ok, %LCH{}} = LCH.new({ctx.l, ctx.c, ctx.h})
      assert {:ok, %LCH{a: 0.5}} = LCH.new({ctx.l, ctx.c, ctx.h, ctx.a})
    end

    test "constructs from lists properly", ctx do
      assert {:ok, %LCH{}} = LCH.new([ctx.l, ctx.c, ctx.h])
      assert {:ok, %LCH{a: 0.5}} = LCH.new([ctx.l, ctx.c, ctx.h, ctx.a])
    end

    test "constructs from keyword lists properly", ctx do
      assert {:ok, %LCH{}} = LCH.new(Enum.into(Map.take(ctx, [:l, :c, :h]), []))
      assert {:ok, %LCH{a: 0.5}} = LCH.new(Enum.into(ctx, []))
    end

    test "constructs from maps properly", ctx do
      assert {:ok, %LCH{}} = LCH.new(Enum.into(Map.take(ctx, [:l, :c, :h]), %{}))
      assert {:ok, %LCH{a: 0.5}} = LCH.new(Enum.into(ctx, %{}))
    end
  end

  test "new/3 constructs an LCH color" do
    assert {:ok, %LCH{}} = LCH.new(0, 0, 0)
  end

  test "new/4 constructs an LCH color" do
    assert {:ok, %LCH{a: 0.5}} = LCH.new(0, 0, 0, 0.5)
  end
end
