defmodule Ultraviolet do
  @moduledoc"""
  Ultraviolet is a color manipulation library designed to function similarly to
  `chroma-js`, except in Elixir. It may not have parity with `chroma-js`, but
  it includes most of the common operations and features.
  """
  alias Ultraviolet.Color

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

  #### HSL

    iex>Ultraviolet.new(330, 1, 0.6, :hsl)
    {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  #### HSV

    iex>Ultraviolet.new(330, 0.8, 1, :hsv)
    {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  #### Lab

    iex>Ultraviolet.new(40, -20, 50, :lab)
    {:ok, %Ultraviolet.Color{r: 83, g: 102, b: 0, a: 1.0}}

  #### LCH / HCL

    iex>Ultraviolet.new(80, 40, 130, :lch)
    {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  #### OKLab

    iex>Ultraviolet.new(0.4, -0.2, 0.5, :oklab)
    {:ok, %Ultraviolet.Color{r: 98, g: 68, b: 0, a: 1.0}}

  #### OKLCH

    iex>Ultraviolet.new(0.5, 0.2, 240, :oklch)
    {:ok, %Ultraviolet.Color{r: 0, g: 105, b: 199, a: 1.0}}

  """
  defdelegate new(any), to: Color
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
  """
  def mix(color, target, ratio \\ 0.5, mode \\ :lrgb) do
    Color.mix(color, target, ratio, mode)
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
  def average([color | targets], mode \\ :lrgb, weights \\ nil) do
    Color.average(color, targets, mode, weights)
  end
end
