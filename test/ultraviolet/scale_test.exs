defmodule ScaleTest do
  use ExUnit.Case

  alias Ultraviolet.{Scale, Color}

  doctest Ultraviolet.Scale

  describe "simple RGB scale (white -> black)" do
    setup do
      {:ok, scale} = Ultraviolet.scale()
      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a gray middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#808080"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end

    test "fetch/1 works outside of the domain", ctx do
      assert {:ok, _} = Scale.fetch(ctx.scale, -1)
      assert {:ok, _} = Scale.fetch(ctx.scale, 100)
    end
  end

  describe "RGB scale (white -> black), domain and classses checks" do
    test "linearly interpolates with no classes" do
      {:ok, scale} = Ultraviolet.scale(["black", "white"], classes: [])
      assert Color.hex(Scale.get(scale, 0.5)) == "#808080"
    end

    test "linearly interpolates with one class" do
      {:ok, scale} = Ultraviolet.scale(["black", "white"], classes: [1])
      assert Color.hex(Scale.get(scale, 0.5)) == "#808080"
    end

    test "linearly interpolates with two classes" do
      {:ok, scale} = Ultraviolet.scale(["black", "white"], classes: [0, 1])
      assert Color.hex(Scale.get(scale, 0.5)) == "#808080"
    end

    test "linearly interpolates with no domain" do
      {:ok, scale} = Ultraviolet.scale(["black", "white"], domain: [])
      assert Color.hex(Scale.get(scale, 0.5)) == "#808080"
    end

    test "linearly interpolates with one-element domain" do
      {:ok, scale} = Ultraviolet.scale(["black", "white"], domain: [1])
      assert Color.hex(Scale.get(scale, 0.5)) == "#808080"
    end
  end

  describe "simple HSV scale (white -> black)" do
    setup do
      {:ok, scale} = Ultraviolet.scale(["white", "black"], space: :hsv)
      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a gray middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#808080"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end

    test "stores the right colors", ctx do
      assert Enum.map(ctx.scale.colors, &Color.hex/1) == ["#ffffff", "#000000"]
    end

    test "returns the bounds when asked to take 2", ctx do
      assert Enum.map(Scale.take(ctx.scale, 2), &Color.hex/1) == ["#ffffff", "#000000"]
    end

    test "does not take invalid keys", ctx do
      assert Enum.map(Scale.take_keys(ctx.scale, [nil, 1]), &Color.hex/1) == ["#000000"]
    end
  end

  describe "classified HSV scale (white -> black)" do
    setup do
      {:ok, scale} =
        Ultraviolet.scale(
          ["white", "black"],
          space: :hsv,
          classes: 7
        )

      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a gray middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#808080"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end

    test "returns the proper classes", ctx do
      assert Enum.map(Scale.take(ctx.scale, 7), &Color.hex/1) == [
               "#ffffff",
               "#d5d5d5",
               "#aaaaaa",
               "#808080",
               "#555555",
               "#2a2a2a",
               "#000000"
             ]
    end
  end

  describe "Simple Lab scale (white -> black)" do
    setup do
      {:ok, scale} = Ultraviolet.scale(["white", "black"], space: :lab)
      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a gray middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#777777"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end
  end

  describe "RdYlGn ColorBrewer scale" do
    setup do
      {:ok, scale} = Ultraviolet.scale("RdYlGn", count: 11)
      {:ok, scale: scale}
    end

    test "starts red", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#a50026"
    end

    test "has a yellow middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#ffffbf"
    end

    test "ends green", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#006837"
    end
  end

  describe "domained RdYlGn ColorBrewer scale" do
    setup do
      {:ok, scale} = Ultraviolet.scale("RdYlGn", count: 11, domain: [0, 100])
      {:ok, scale: scale}
    end

    test "stores the proper domain", ctx do
      assert ctx.scale.domain == [0, 100]
    end

    test "starts red", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#a50026"
    end

    test "has a non-yellow decile", ctx do
      assert Color.hex(Scale.get(ctx.scale, 10)) != "#ffffbf"
    end

    test "has a yellow middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 50)) == "#ffffbf"
    end

    test "ends green", ctx do
      assert Color.hex(Scale.get(ctx.scale, 100)) == "#006837"
    end
  end

  describe "domained, classified RdYlGn ColorBrewer scale" do
    setup do
      {:ok, scale} =
        Ultraviolet.scale(
          "RdYlGn",
          count: 11,
          domain: [0, 100],
          classes: 5
        )

      {:ok, scale: scale}
    end

    test "starts red", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#a50026"
    end

    test "stays red at the decile", ctx do
      assert Color.hex(Scale.get(ctx.scale, 10)) == "#a50026"
    end

    test "has a yellow middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 50)) == "#ffffbf"
    end

    test "ends green", ctx do
      assert Color.hex(Scale.get(ctx.scale, 100)) == "#006837"
    end

    test "returns the proper classes", ctx do
      assert Enum.map(Scale.take(ctx.scale, 5), &Color.hex/1) == [
               "#a50026",
               "#f98e52",
               "#ffffbf",
               "#86cb67",
               "#006837"
             ]
    end
  end

  describe "domain with the same min and max" do
    setup do
      {:ok, scale} = Ultraviolet.scale(["white", "black"], domain: [1, 1])
      {:ok, scale: scale}
    end

    test "returns a color", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end
  end

  describe "css rgba colors" do
    setup do
      {:ok, scale} = Ultraviolet.scale("YlGnBu")
      {:ok, scale: scale}
    end

    test "don't round alpha values", ctx do
      {:ok, color} = Scale.fetch(ctx.scale, 0.3)
      assert Color.css(%{color | a: 0.675}) == "rgb(170 222 183 / 0.675)"
    end
  end

  describe "get colors from a scale -" do
    setup do
      {:ok, scale} = Ultraviolet.scale(["yellow", "darkgreen"])
      {:ok, scale: scale}
    end

    test "5 hex colors", ctx do
      assert Enum.map(Scale.take(ctx.scale, 5), &Color.hex/1) == [
               "#ffff00",
               "#bfd800",
               "#80b200",
               "#408b00",
               "#006400"
             ]
    end

    test "3 css colors", ctx do
      assert Enum.map(Scale.take(ctx.scale, 3), &Color.css/1) == [
               "rgb(255 255 0)",
               "rgb(128 178 0)",
               "rgb(0 100 0)"
             ]
    end
  end

  describe "simple scale padding - " do
    setup do
      {:ok, scale} = Ultraviolet.scale("RdYlBu", count: 11, padding: 0.15)
      {:ok, scale: scale}
    end

    test "beginning is different", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#e64f35"
    end

    test "middle is unchanged", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#ffffbf"
    end

    test "end is different", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#5d91c3"
    end
  end

  describe "one-sided scale padding -" do
    setup do
      {:ok, scale} = Ultraviolet.scale("OrRd", count: 9, padding: {0.2, 0})
      {:ok, scale: scale}
    end

    test "beginning is different", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#fddcaf"
    end

    test "middle is different", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#f26d4b"
    end

    test "end is the same", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#7f0000"
    end
  end

  describe "scale with gamma < 1" do
    setup do
      {:ok, scale} = Ultraviolet.scale("YlGn", count: 9, gamma: 0.5)
      {:ok, scale: scale}
    end

    test "beginning is greener than expected", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.1)) == "#c2e698"
    end

    test "middle is greener than expected", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#2d914c"
    end

    test "end is the same", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#004529"
    end
  end

  describe "scale with gamma > 1" do
    setup do
      {:ok, scale} = Ultraviolet.scale("YlGn", count: 9, gamma: 2)
      {:ok, scale: scale}
    end

    test "beginning is yellower than expected", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.1)) == "#feffe1"
    end

    test "middle is yellower than expected", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#d9f0a3"
    end

    test "end is the same", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#004529"
    end
  end

  describe "scale with one color" do
    setup do
      {:ok, scale} = Ultraviolet.scale(["red"])
      {:ok, scale: scale}
    end

    test "should return that color", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.3)) == "#ff0000"
    end
  end

  describe "scale with invalid domain values" do
    setup do
      {:ok, scale} = Ultraviolet.scale("OrRd")
      {:ok, scale: scale}
    end

    test "returns black by default", ctx do
      assert Color.hex(Scale.get(ctx.scale, nil)) == "#000000"
    end

    test "returns the default value", ctx do
      default = %Color{r: 128, g: 128, b: 128}
      assert Color.hex(Scale.get(ctx.scale, nil, default)) == "#808080"
    end
  end

  describe "scale wrapped in a scale" do
    setup do
      {:ok, scale1} = Ultraviolet.scale("OrRd", count: 9)
      {:ok, scale2} = Ultraviolet.scale("OrRd", count: 9, domain: [0, 0.25, 1])
      {:ok, scale1: scale1, scale2: scale2}
    end

    test "matches at the beginning", ctx do
      assert Color.hex(Scale.get(ctx.scale1, 0)) ==
               Color.hex(Scale.get(ctx.scale2, 0))
    end

    test "matches at one middle", ctx do
      assert Color.hex(Scale.get(ctx.scale1, 0.25)) ==
               Color.hex(Scale.get(ctx.scale2, 0.125))
    end

    test "matches at a second middle", ctx do
      assert Color.hex(Scale.get(ctx.scale1, 0.5)) ==
               Color.hex(Scale.get(ctx.scale2, 0.25))
    end

    test "matches at a third middle", ctx do
      assert Color.hex(Scale.get(ctx.scale1, 0.75)) ==
               Color.hex(Scale.get(ctx.scale2, 0.625))
    end

    test "matches at the end", ctx do
      assert Color.hex(Scale.get(ctx.scale1, 1)) ==
               Color.hex(Scale.get(ctx.scale2, 1))
    end
  end

  describe "bezier scale with one color" do
    setup do
      {:ok, scale} = Ultraviolet.scale(["red"], interpolation: :bezier)
      {:ok, scale: scale}
    end

    test "should return that color", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.3)) == "#ff0000"
    end
  end

  describe "two-color scale with bezier (i.e. linear) interpolation" do
    setup do
      {:ok, scale} =
        Ultraviolet.scale(
          ["white", "black"],
          interpolation: :bezier
        )

      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a gray middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#777777"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end
  end

  describe "three-color scale with quadratic bezier interpolation" do
    setup do
      {:ok, scale} =
        Ultraviolet.scale(
          ["white", "red", "black"],
          interpolation: :bezier
        )

      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a grayish red middle", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#c45c44"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end
  end

  describe "four-color scale with cubic bezier interpolation" do
    setup do
      {:ok, scale} =
        Ultraviolet.scale(
          ["white", "yellow", "red", "black"],
          interpolation: :bezier
        )

      {:ok, scale: scale}
    end

    test "starts at white", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#ffffff"
    end

    test "has a yellow first quartile", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.25)) == "#ffe085"
    end

    test "has an orange center", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#e69735"
    end

    test "has an brownish third quartile", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.75)) == "#914213"
    end

    test "ends with black", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#000000"
    end
  end

  describe "five-color diverging scale with quadratic bezier interpolation" do
    setup do
      {:ok, scale} =
        Ultraviolet.scale(
          ["darkred", "orange", "snow", "lightgreen", "royalblue"],
          interpolation: :bezier
        )

      {:ok, scale: scale}
    end

    test "starts at darkred", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0)) == "#8b0000"
    end

    test "has an orange first quartile", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.25)) == "#dd8d49"
    end

    test "has an tan center", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.5)) == "#dfcb98"
    end

    test "has an light green third quartile", ctx do
      assert Color.hex(Scale.get(ctx.scale, 0.75)) == "#a7c1bd"
    end

    test "ends with royalblue", ctx do
      assert Color.hex(Scale.get(ctx.scale, 1)) == "#4169e1"
    end
  end

  describe "invalid cases:" do
    test "if any colors are invalid, an error is returned" do
      assert Ultraviolet.scale(["red", "unknown"]) ==
               {:error, :invalid}
    end

    test "if a colorbrewer color is invalid, an error is returned" do
      assert Ultraviolet.scale("unknown") ==
               {:error, :not_found}
    end
  end

  describe "bezier scale" do
    test "is created in :oklab space" do
      assert {:ok, _scale} =
               Ultraviolet.scale(
                 ["white", "black"],
                 interpolation: :bezier,
                 space: :lab
               )
    end

    test "is created in :lab space" do
      assert {:ok, _scale} =
               Ultraviolet.scale(
                 ["white", "black"],
                 interpolation: :bezier,
                 space: :oklab
               )
    end
  end
end
