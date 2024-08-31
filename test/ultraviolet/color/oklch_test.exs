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
    "magenta" => {{255, 0, 255, 1}, {0.702, 0.322, 328.373}}
  }

  for {name, {{r, g, b, a}, {l, c, h}}} <- cases do
    test "converts #{name} from OKLCH to RGB properly" do
      assert {:ok, color} = Color.new([unquote(r), unquote(g), unquote(b), unquote(a)])
      assert {:ok, oklch} = OKLCH.from_rgb(color, round: false)
      assert Float.round(oklch.l, 3) == unquote(l)
      assert Float.round(oklch.c, 3) == unquote(c)

      case oklch.h do
        0 -> assert unquote(h) == 0
        other -> assert Float.round(other, 3) == unquote(h)
      end

      assert oklch.a == unquote(a)
      assert {:ok, ^color} = OKLCH.to_rgb(oklch)
    end
  end

  describe "new/1" do
    setup do
      {:ok, l: 0, c: 0, h: 0, a: 0.5}
    end

    test "constructs from tuples properly", ctx do
      assert {:ok, %OKLCH{}} = OKLCH.new({ctx.l, ctx.c, ctx.h})
      assert {:ok, %OKLCH{a: 0.5}} = OKLCH.new({ctx.l, ctx.c, ctx.h, ctx.a})
    end

    test "constructs from lists properly", ctx do
      assert {:ok, %OKLCH{}} = OKLCH.new([ctx.l, ctx.c, ctx.h])
      assert {:ok, %OKLCH{a: 0.5}} = OKLCH.new([ctx.l, ctx.c, ctx.h, ctx.a])
    end

    test "constructs from keyword lists properly", ctx do
      assert {:ok, %OKLCH{}} = OKLCH.new(Enum.into(Map.take(ctx, [:l, :c, :h]), []))
      assert {:ok, %OKLCH{a: 0.5}} = OKLCH.new(Enum.into(ctx, []))
    end

    test "constructs from maps properly", ctx do
      assert {:ok, %OKLCH{}} = OKLCH.new(Enum.into(Map.take(ctx, [:l, :c, :h]), %{}))
      assert {:ok, %OKLCH{a: 0.5}} = OKLCH.new(Enum.into(ctx, %{}))
    end
  end

  test "new/3 constructs an OKLCH color" do
    assert {:ok, %OKLCH{}} = OKLCH.new(0, 0, 0)
  end

  test "new/4 constructs an OKLCH color" do
    assert {:ok, %OKLCH{a: 0.5}} = OKLCH.new(0, 0, 0, 0.5)
  end
end
