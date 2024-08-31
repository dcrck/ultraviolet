defmodule ColorTest do
  use ExUnit.Case

  alias Ultraviolet.Color

  doctest Ultraviolet.Color

  test "detects named colors" do
    {:ok, color} = Color.new("mediumslateblue")
    assert Color.hex(color) == "#7b68ee"
  end

  test "return error for a non-existant color name" do
    assert {:error, :invalid} == Color.new("fakecolor")
  end

  test "auto-detect correct hex colors" do
    Enum.each(
      ["#ff9900", "#FF9900", "#F90", "f90", "FF9900", "FF9900FF", "F90F", "#F90F"],
      fn hex ->
        assert {:ok, color} = Color.new(hex)
        assert Color.hex(color) == "#ff9900"
      end
    )
  end

  test "using color names doesn't work when directly calling the Color module functions" do
    assert {:error, :invalid} == Color.blend("black", "white", :multiply)
  end

  describe "new/1" do
    setup do
      {:ok, r: 0, g: 0, b: 0, a: 0.5}
    end

    test "constructs from tuples properly", ctx do
      assert {:ok, %Color{}} = Color.new({ctx.r, ctx.g, ctx.b})
      assert {:ok, %Color{a: 0.5}} = Color.new({ctx.r, ctx.g, ctx.b, ctx.a})
    end

    test "constructs from lists properly", ctx do
      assert {:ok, %Color{}} = Color.new([ctx.r, ctx.g, ctx.b])
      assert {:ok, %Color{a: 0.5}} = Color.new([ctx.r, ctx.g, ctx.b, ctx.a])
    end

    test "constructs from keyword lists properly", ctx do
      assert {:ok, %Color{}} = Color.new(Enum.into(Map.take(ctx, [:r, :g, :b]), []))
      assert {:ok, %Color{a: 0.5}} = Color.new(Enum.into(ctx, []))
    end

    test "constructs from maps properly", ctx do
      assert {:ok, %Color{}} = Color.new(Enum.into(Map.take(ctx, [:r, :g, :b]), %{}))
      assert {:ok, %Color{a: 0.5}} = Color.new(Enum.into(ctx, %{}))
    end

    test "re-uses an existing color" do
      assert {:ok, color} = Color.new({123, 123, 123, 0.5})
      assert {:ok, ^color} = Color.new(color)
    end
  end

  describe "new/2" do
    test "constructs in LCH space from HCL lists" do
      assert {:ok, color} = Color.new([300, 0, 0.5], space: :hcl)
      assert {:ok, ^color} = Color.new([300, 0, 0.5, 1.0], space: :hcl)
    end
  end

  describe "into/3" do
    test "doesn't work with non-Color first argument" do
      assert {:error, :invalid} = Color.into("white", :hsl, [])
    end
  end
end
