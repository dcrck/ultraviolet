defmodule Ultraviolet do
  @moduledoc"""
  Ultraviolet is a color manipulation library designed to function similarly to
  `chroma-js`, except in Elixir. It may not have parity with `chroma-js`, but
  it includes most of the common operations and features.
  """
  alias Ultraviolet.{Color, Scale, ColorBrewer}
  import Ultraviolet.Helpers

  @doc """
  The first step to get your color into Ultraviolet is to create a
  `Ultraviolet.Color`. This can be done through any of the `new` functions, or
  with the dedicated constructors for each supported color space: `hsl/3` for
  HSL, `hsb/3` for HSB, etc.

  ## Examples

  `new` supports a wide variety of inputs:

  ### Named colors

  All named colors as defined by the
  [W3CX11 specification](https://en.wikipedia.org/wiki/X11_color_names) are
  supported:

      iex>Ultraviolet.new("hotpink")
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180, a: 1.0}}

  ### Hexadecimal Strings

  If there's no matching named color, check for a hexidecimal string.
  It ignores case, the `#` sign is optional, and it can recognize the
  shorter 3-letter format.

      iex>Ultraviolet.new("#ff3399")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new("F39")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}


  ### Hexadecimal Numbers

  Any number between `0` and `16_777_215` will be recognized as a Color:

      iex>Ultraviolet.new(0xff3399)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  ### Individual R, G, B

  You can also pass RGB values individually, Each parameter must be within
  `0..255`. You can pass the numbers as individual arguments or as an array.

      iex>Ultraviolet.new(0xff, 0x33, 0x99)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new(255, 51, 153)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new([255, 51, 153])
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  ### Other Color Spaces

  You can construct colors from different color spaces as well by passing an
  atom identifying the color space as the last argument.

  The color space channels can either be passed in as arguments or as a map.

  #### HSL

    iex>Ultraviolet.new(330, 1, 0.6, :hsl)
    {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
    iex>Ultraviolet.new(%{h: 330, s: 1, l: 0.6}, :hsl)
    {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  #### HSV

    iex>Ultraviolet.new(330, 0.8, 1, :hsv)
    {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
    iex>Ultraviolet.new(%{h: 330, s: 0.8, v: 1}, :hsv)
    {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  #### Lab

    iex>Ultraviolet.new(40, -20, 50, :lab)
    {:ok, %Ultraviolet.Color{r: 83, g: 102, b: 0, a: 1.0}}
    iex>Ultraviolet.new(%{l_: 40, a_: -20, b_: 50}, :lab)
    {:ok, %Ultraviolet.Color{r: 83, g: 102, b: 0, a: 1.0}}

  #### LCH / HCL

    iex>Ultraviolet.new(80, 40, 130, :lch)
    {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}
    iex>Ultraviolet.new(%{l: 80, c: 40, h: 130}, :lch)
    {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  #### OKLab

    iex>Ultraviolet.new(0.4, -0.2, 0.5, :oklab)
    {:ok, %Ultraviolet.Color{r: 98, g: 68, b: 0, a: 1.0}}
    iex>Ultraviolet.new(%{l_: 0.4, a_: -0.2, b_: 0.5}, :oklab)
    {:ok, %Ultraviolet.Color{r: 98, g: 68, b: 0, a: 1.0}}

  #### OKLCH

    iex>Ultraviolet.new(0.5, 0.2, 240, :oklch)
    {:ok, %Ultraviolet.Color{r: 0, g: 105, b: 199, a: 1.0}}
    iex>Ultraviolet.new(%{l: 0.5, c: 0.2, h: 240}, :oklch)
    {:ok, %Ultraviolet.Color{r: 0, g: 105, b: 199, a: 1.0}}

  """
  defdelegate new(any), to: Color
  defdelegate new(map, mode), to: Color
  defdelegate new(p1, p2, p3), to: Color
  defdelegate new(p1, p2, p3, p4), to: Color
  defdelegate new(p1, p2, p3, p4, p5), to: Color
  defdelegate new(p1, p2, p3, p4, p5, p6), to: Color

  @doc """
  Generates the sRGB representation of a `Color.HSL`.

  ## Examples

    iex>Ultraviolet.hsl(330, 0, 1)
    {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}

  """
  def hsl(h, s, l), do: new(h, s, l, :hsl)

  @doc """
  Generates the sRGB representation of a `Color.HSV`.

  ## Examples

    iex>Ultraviolet.hsv(330, 0, 1)
    {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}

  """
  def hsv(h, s, v), do: new(h, s, v, :hsv)

  @doc """
  Generates the sRGB representation of a `Color.Lab`

  ## Options

  You can pass a keyword list of options to this as the last argument

  - `:reference`: the CIE Lab white reference point. Default: `:d65`
  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  ## Examples

    iex>Ultraviolet.lab(50, -20, 50)
    {:ok, %Ultraviolet.Color{r: 110, g: 127, b: 21, a: 1.0}}
    iex>Ultraviolet.lab(80, -20, 50)
    {:ok, %Ultraviolet.Color{r: 192, g: 207, b: 102, a: 1.0}}

  """
  def lab(l, a, b, options \\ []) when is_list(options) do
    new(l, a, b, Keyword.merge(options, mode: :lab))
  end

  @doc """
  Genereates the sRGB representation of a `Color.LCH`.

  ## Example

    iex>Ultraviolet.lch(80, 40, 130)
    {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  """
  def lch(l, c, h), do: new(l, c, h, :lch)

  @doc """
  Genereates the sRGB representation of a `Color.LCH`.

  This is the same as `lch/3`, but with the arguments reversed.

  ## Example

    iex>Ultraviolet.hcl(130, 40, 80)
    {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  """
  def hcl(h, c, l), do: new(l, c, h, :lch)

  @doc """
  Genereates the sRGB representation of a `Color.OKLab`.

  ## Options

  You can pass a keyword list of options to this as the last argument

  - `:reference`: the CIE Lab white reference point. Default: `:d65`
  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  ## Example

    iex>Ultraviolet.oklab(0.5, -0.2, 0.5)
    {:ok, %Ultraviolet.Color{r: 128, g: 97, b: 0, a: 1.0}}
    iex>Ultraviolet.oklab(0.8, -0.2, 0.5)
    {:ok, %Ultraviolet.Color{r: 217, g: 197, b: 0, a: 1.0}}

  """
  def oklab(l, a, b, options \\ []) when is_list(options) do
    new(l, a, b, Keyword.merge(options, mode: :oklab))
  end

  @doc """
  Genereates the sRGB representation of a `Color.OKLCH`.

  ## Example

    iex>Ultraviolet.oklch(0.8, 0.12, 60)
    {:ok, %Ultraviolet.Color{r: 246, g: 171, b: 107, a: 1.0}}

  """
  def oklch(l, a, b), do: new(l, a, b, :oklch)

  @doc """
  Converts a temperature into a color, based on the color temperature scale.

  ## Examples

    iex>Ultraviolet.temperature(2000)
    {:ok, %Ultraviolet.Color{r: 255, g: 139, b: 20, a: 1.0}}
    iex>Ultraviolet.temperature(3500)
    {:ok, %Ultraviolet.Color{r: 255, g: 195, b: 138, a: 1.0}}
    iex>Ultraviolet.temperature(6500)
    {:ok, %Ultraviolet.Color{r: 255, g: 250, b: 254, a: 1.0}}

  """
  defdelegate temperature(kelvin), to: Color.Temperature, as: :to_rgb

  @doc """
  Mixes two colors. the mix `ratio` is a value between 0 and 1

  ## Examples

    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue");
    iex>Ultraviolet.Color.hex(mixed)
    "#b400b4"
    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue", 0.25);
    iex>Ultraviolet.Color.hex(mixed)
    "#dd0080"
    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue", 0.75);
    iex>Ultraviolet.Color.hex(mixed)
    "#8000dd"

  The color mixing produces different results based on the color space used for
  interpolation (default: `:lrgb`).

    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue", 0.5, :rgb);
    iex>Ultraviolet.Color.hex(mixed)
    "#800080"
    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue", 0.5, :hsl);
    iex>Ultraviolet.Color.hex(mixed)
    "#ff00ff"
    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue", 0.5, :lab);
    iex>Ultraviolet.Color.hex(mixed)
    "#ca0089"
    iex>{:ok, mixed} = Ultraviolet.mix("red", "blue", 0.5, :lch);
    iex>Ultraviolet.Color.hex(mixed)
    "#fa0080"

  ### Available Spaces

  - `:lrgb` (Linear RGB)
  - `:rgb`
  - `:hsv`
  - `:hsl`
  - `:lch` and `:oklch`
  - `:hcl`
  - `:lab` and `:oklab`

  """
  def mix(color, target, ratio \\ 0.5, space \\ :lrgb) do
    case validate_all([color, target], &Color.new/1) do
      {:ok, [color, target]} -> Color.mix(color, target, ratio, space)
      error -> error
    end
  end

  @doc """
  Similar to `mix/4`, but accepts more than two colors. Simple averaging
  of the R,G,B components and the alpha channel.

  ## Examples

    iex> colors = ["ddd", "yellow", "red", "teal"];
    iex>{:ok, color} = Ultraviolet.average(colors);
    iex>Ultraviolet.Color.hex(color)
    "#d3b480"
    iex>{:ok, color} = Ultraviolet.average(colors, :rgb);
    iex>Ultraviolet.Color.hex(color)
    "#b79757"
    iex>{:ok, color} = Ultraviolet.average(colors, :lab);
    iex>Ultraviolet.Color.hex(color)
    "#d3a96a"
    iex>{:ok, color} = Ultraviolet.average(colors, :lch);
    iex>Ultraviolet.Color.hex(color)
    "#ef9e4e"

  Also works with alpha channels

    iex>{:ok, color} = Ultraviolet.average(["red", %Ultraviolet.Color{r: 0, g: 0, b: 0, a: 0.0}])
    iex>Ultraviolet.Color.hex(color)
    "#b4000080"

  You can also provide an array of weights to compute a weighted average:

    iex> colors = ["ddd", "yellow", "red", "teal"];
    iex>{:ok, color} = Ultraviolet.average(colors, :lch, [1, 1, 2, 1]);
    iex>Ultraviolet.Color.hex(color)
    "#f98841"
    iex>{:ok, color} = Ultraviolet.average(colors, :lch, [1.5, 0.5, 1, 2.3]);
    iex>Ultraviolet.Color.hex(color)
    "#ae9e52"
  """
  def average(colors, mode \\ :lrgb, weights \\ nil) do
    case validate_all(colors, &Color.new/1) do
      {:ok, [color | targets]} -> Color.average(color, targets, mode, weights)
      error -> error
    end
  end

  @doc """
  Blends two colors using RGB channel-wise blend functions.

  ## Valid Blend Modes

  - `:multiply`
  - `:darken`
  - `:lighten`
  - `:screen`
  - `:overlay`
  - `:burn`
  - `:dodge`

  ## Examples

    iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :multiply);
    iex>Ultraviolet.Color.hex(color)
    "#47af22"
    iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :darken);
    iex>Ultraviolet.Color.hex(color)
    "#4cbb22"
    iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :lighten);
    iex>Ultraviolet.Color.hex(color)
    "#eeeefc"

  """
  def blend(color, mask, mode) do
    case validate_all([color, mask], &Color.new/1) do
      {:ok, [color, mask]} -> Color.blend(color, mask, mode)
      error -> error
    end
  end

  @doc """
  Color scales, created with `Ultraviolet.scale/2`, map numbers onto a color
  palette. Because they're basically lazy maps, they have similar access
  functions as maps, as well as some Enumerable:
  
  - `Ultraviolet.Scale.get/3` to get a single color
  - `Ultraviolet.Scale.fetch/2` to fetch a single color
  - `Ultraviolet.Scale.take/2` to get several colors at once

  To see other access functions, see the `Ultraviolet.Scale` documentation.

  By default, a scale has the domain `[0, 1]` and a range of `"white"` to
  `"black"`:

    iex>{:ok, scale} = Ultraviolet.scale();
    iex>{:ok, color} = Ultraviolet.Scale.fetch(scale, 0.25);
    iex>Ultraviolet.Color.hex(color)
    "#bfbfbf"

  The first argument is an array of colors. Any color that can be read by
  `Ultraviolet.new/1` works here too. If you pass more than two colors, they
  will be evenly distributed along the gradient.

    iex>{:ok, scale} = Ultraviolet.scale(["yellow", "008ae5"]);
    iex>{:ok, scale} = Ultraviolet.scale(["yellow", "red", "black"]);

  ## Options

  Scales can be created with a number of options which affect the output colors:

  ### Domain

  You can change the input domain to match your use case. The default domain is
  `[0, 1]`.

    iex>{:ok, scale} = Ultraviolet.scale(["yellow", "008ae5"], domain: [0, 100]);

  You can use this option to set the exact positions of each color:

    iex>{:ok, scale} = Ultraviolet.scale(
    ...>  ["yellow", "lightgreen", "008ae5"],
    ...>  domain: [0, 0.25, 1]
    ...>);

  ### Color Space

  As with `Ultraviolet.mix/2`, the result of color interpolation will depend on
  the color space in which the channels are interpolated. The default `:space`
  is `:rgb`.

  This default is okay, but sometimes, two-color RGB gradients go through a gray
  "dead zone", which...doesn't look great. Other color spaces can produce better
  results.

    iex>{:ok, scale} = Ultraviolet.scale(["yellow, "navy"], space: :lab);

  The available values for this option are the same as with `Ultaviolet.mix/2`.

  ### Gamma Correction

  `:gamma` can be used to "shift" a scale's center more towards the beginning
  (`:gamma` < 1) or the end (`:gamma` > 1). This option is typically used to
  "even out" the lightness gradient. The default gamma is `1`.

    iex>{:ok, scale} = Ultraviolet.scale(["yellow", "green"], gamma: 0.5);
    iex>{:ok, scale} = Ultraviolet.scale(["yellow", "green"], gamma: 1);
    iex>{:ok, scale} = Ultraviolet.scale(["yellow", "green"], gamma: 2);

  ### Lightness Correction

  `:correct_lightness?` makes sure the lightness range is spread evenly across a
  color scale. This option is especially useful when working with multi-hue
  color scales. where simple gamma correction won't help very much. The default
  value is `false`, i.e. lightness correction turned off.

    iex>{:ok, scale} = Ultraviolet.scale(
    ...>  ["black", "red", "yellow", "white"],
    ...>  correct_lightness?: true
    ...>);

  ### Padding

  `:padding` reduces the color range by cutting off a fraction of the gradient
  on both sides. If you pass a single number, the same padding will be applied
  to both sides. The default padding is `0`, i.e. no padding applied.

    iex>{:ok, scale} = Ultraviolet.scale(
    ...>  ["red", "yellow", "blue"],
    ...>  padding: 0.15
    ...>);

  Alternatively, you can specify the padding for each side individually by
  passing a two-number tuple:

    iex>{:ok, scale} = Ultraviolet.scale(
    ...>  ["red", "yellow", "blue"],
    ...>  padding: {0.2, 0}
    ...>);

  ### Classes

  If you want the scale to return a distinct set of colors instead of a
  continuous gradient, you can use the `:classes` option. Passing an integer
  will break up the scale into equidistant classes. 

    iex>{:ok, scale} = Ultraviolet.scale(["orange", "red"], classes: 5);

  You can also define custom class breaks by passing them as an array.

    iex>{:ok, scale} = Ultraviolet.scale(
    ...>  ["orange", "red"],
    ...> classes: [0, 0.3, 0.55, 0.85, 1]
    ...>);

  The default value is `0`, meaning a continuous gradient will be used.

  ### Interpolation

  By default, the colors retrieved from the scale are the result of linear
  interpolation. If you want to change this, use the `:interpolation` option.

  This option accepts a unary function (i.e. a function with one argument),
  which will be called every time a color retrieval function is called on that
  space. It should accept a number and return a `Ultraviolet.Color` or an
  `{:ok, Ultraviolet.Color}` tuple.

  There are also two builtin interpolation options: `:linear` for linear
  interpolation (the default) and `:bezier` for Bezier interpolation.

    iex>{:ok, scale} = Ultraviolet.scale(
    ...>  ["yellow", "red", "black"],
    ...>  interpolation: :bezier
    ...>);

  #### Example: `cubehelix`

  Here's how you might use this option to implement Dave Green's
  [cubehelix scheme](https://people.phy.cam.ac.uk/dag9/CUBEHELIX/):

  TODO finish this example!

    iex>params = %{start: 300, rotations: -1.5, hue: 1, gamma: 1, lightness: {0, 1}};
    iex>cubehelix = fn _x ->
    ...>  Color.new(0, 0, 0)
    ...>end;
    iex>{:ok, cubehelix} = Ultraviolet.scale(
    ...>  ["black", "white"],
    ...>  interpolation: &cubehelix/1
    ...>)

  ## Color Brewer

  Ultraviolet includes the definitions from
  [ColorBrewer](https://colorbrewer2.org) as well.

    iex>{:ok, scale} = Ultraviolet.scale("YlGnBu");

  You can reverse the colors by reversing the domain:

    iex>{:ok, scale} = Ultraviolet.scale("YlGnBu", domain: [1, 0]);

  ### Color Count

  You can include a `:count` option when creating a ColorBrewer-based scale
  to retrieve the Color Brewer palette with the given number of colors.
  The default is `9`.

    iex>{:ok, scale} = Ultraviolet.scale("YlGnBu", count: 5);

  """
  def scale(colors \\ ["white", "black"], options \\ [])

  def scale(colors, options) when is_list(options) and is_list(colors) do
    case validate_all(colors, &Color.new/1) do
      {:ok, colors} -> Scale.new(colors, options)
      error -> error
    end
  end

  def scale(palette, options) when is_binary(palette) and is_list(options) do
    {count, options} = Keyword.pop(options, :count, 9)
    case ColorBrewer.colors(palette, count) do
      {:ok, colors} -> Scale.new(colors, options)
      error -> error
    end
  end
end
