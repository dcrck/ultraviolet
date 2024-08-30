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
end
