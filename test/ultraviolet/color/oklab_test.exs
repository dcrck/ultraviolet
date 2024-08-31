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
      assert {:ok, color} = Color.new([unquote(r), unquote(g), unquote(b), unquote(a)])
      assert {:ok, lab} = OKLab.from_rgb(color, round: false)
      assert Float.round(lab.l_, 3) == unquote(l)
      assert Float.round(lab.a_, 3) == unquote(a_star)
      assert Float.round(lab.b_, 3) == unquote(b_star)
      assert lab.a == unquote(a)
      assert {:ok, ^color} = OKLab.to_rgb(lab)
    end
  end

  describe "new/1" do
    setup do
      {:ok, l_: 0, a_: 0, b_: 0, a: 0.5}
    end

    test "constructs from tuples properly", ctx do
      assert {:ok, %OKLab{}} = OKLab.new({ctx.l_, ctx.a_, ctx.b_})
      assert {:ok, %OKLab{a: 0.5}} = OKLab.new({ctx.l_, ctx.a_, ctx.b_, ctx.a})
    end

    test "constructs from lists properly", ctx do
      assert {:ok, %OKLab{}} = OKLab.new([ctx.l_, ctx.a_, ctx.b_])
      assert {:ok, %OKLab{a: 0.5}} = OKLab.new([ctx.l_, ctx.a_, ctx.b_, ctx.a])
    end

    test "constructs from keyword lists properly", ctx do
      assert {:ok, %OKLab{}} = OKLab.new(Enum.into(Map.take(ctx, [:l_, :a_, :b_]), []))
      assert {:ok, %OKLab{a: 0.5}} = OKLab.new(Enum.into(ctx, []))
    end

    test "constructs from maps properly", ctx do
      assert {:ok, %OKLab{}} = OKLab.new(Enum.into(Map.take(ctx, [:l_, :a_, :b_]), %{}))
      assert {:ok, %OKLab{a: 0.5}} = OKLab.new(Enum.into(ctx, %{}))
    end
  end

  test "new/3 constructs an OKLab color" do
    assert {:ok, %OKLab{}} = OKLab.new(0, 0, 0)
  end

  test "new/4 constructs an OKLab color" do
    assert {:ok, %OKLab{a: 0.5}} = OKLab.new(0, 0, 0, 0.5)
  end
end
