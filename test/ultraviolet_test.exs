defmodule UltravioletTest do
  use ExUnit.Case
  doctest Ultraviolet

  describe "new/1" do
    test "returns errors for invalid input" do
      assert Ultraviolet.new("#unknow") ==
               {:error, "r value must be a hex value between 0 and ff, got: un"}

      assert Ultraviolet.new("#unk") ==
               {:error, "r value must be a hex value between 0 and ff, got: uu"}

      assert Ultraviolet.new("#unkn") ==
               {:error, "r value must be a hex value between 0 and ff, got: uu"}

      assert Ultraviolet.new("#unknown!") ==
               {:error, "r value must be a hex value between 0 and ff, got: un"}
    end

    test "alpha values cannot be outside of [0, 1]" do
      assert Ultraviolet.new({0, 0, 0, -1}) ==
               {:error, :invalid}

      assert Ultraviolet.new([0, 0, 0, 1.1]) ==
               {:error, :invalid}

      assert Ultraviolet.new([0, 0, 0, 10], space: :hsl) ==
               {:error, :invalid}

      assert Ultraviolet.new([0, 0, 0, -0.1], space: :hsv) ==
               {:error, :invalid}
    end

    test "unsupported color spaces returns an error" do
      assert Ultraviolet.new({0, 0, 0, 1.0}, space: :unknown) == :error
    end

    test "unsupported Lab reference whitepoints returns an error" do
      assert Ultraviolet.new([0, 0, 0, 1.0], space: :lab, reference: :fake) ==
               {:error, "undefined reference point"}
    end
  end

  describe "mix/4" do
    test "invalid color names will return an error" do
      assert Ultraviolet.mix("red", "unknown") ==
               {:error, :invalid}
    end

    test "weight/ratio should be between 0 and 1" do
      assert Ultraviolet.mix("red", "blue", 1.1) ==
               {:error, "expected a ratio between 0 and 1, got: 1.1"}
    end
  end

  describe "average/4" do
    test "Invalid color values will return an error" do
      assert Ultraviolet.average(["red", "unknown"]) ==
               {:error, :invalid}
    end

    test "Invalid color space will return an error" do
      assert Ultraviolet.average(["red", "blue"], :fake) == :error
    end
  end

  describe "blend/3" do
    test "Invalid color values will return an error" do
      assert Ultraviolet.blend("red", "unknown", :multiply) ==
               {:error, :invalid}
    end

    test "Case testing for :dodge" do
      {:ok, color} = Ultraviolet.blend("red", "blue", :dodge)
      assert Ultraviolet.Color.hex(color) == "#ff00ff"
    end
  end
end
