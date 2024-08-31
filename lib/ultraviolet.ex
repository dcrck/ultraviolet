defmodule Ultraviolet do
  @moduledoc """
  Ultraviolet is a color manipulation library designed to work like
  [`chroma-js`](https://github.com/gka/chroma.js). It may not have full parity
  with `chroma-js`, but it includes most of the common operations and features.

  The first step to get your color into Ultraviolet is to create a
  `Ultraviolet.Color`. This can be done through `new/1`, `new/2`, or the
  constructors for each supported color space: `hsl/2` for HSL, `hsb/2` for HSB,
  etc.

  ## Getting Started

  """
  alias Ultraviolet.{Color, Scale, ColorBrewer}
  import Ultraviolet.Helpers

  @doc """
  Creates a new `Ultraviolet.Color` from the given `input`.

  ## Examples

  `new/1` supports a wide variety of inputs:

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

      iex>Ultraviolet.new(0x000000)
      {:ok, %Ultraviolet.Color{r: 0, g: 0, b: 0, a: 1.0}}
      iex>Ultraviolet.new(0xff3399)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  ### Individual R, G, B, A

  You can also pass RGBA channel values individually in an array or tuple, Each
  channel must be within `0..255`.

      iex>Ultraviolet.new({0xff, 0x33, 0x99})
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new({255, 51, 153})
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new([255, 51, 153])
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new([255, 51, 153, 0.5])
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 0.5}}

  """
  @spec new(Color.input()) :: {:ok, Color.t()} | {:error, term()}
  def new(input), do: Color.new(input)

  @doc """
  Creates a new `Ultraviolet.Color` from the given `input` and `options`.

  `new/2` allows a bit more control over the colors you create. You can pass in
  colorspace-specific options, the `colorspace` you want to use, and other
  transformation-related options.

  See the colorspace-specific constructors for more details about what options
  are available for each colorspace.

  This also allows for different datatype options, e.g. simple lists and tuples,
  for the first argument.

  ## Generic Options

  These options are available to `new/2` as well as all colorspace-specific
  constructors:

  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  ## Examples

  #### HSL

      iex>Ultraviolet.new({330, 1, 0.6}, space: :hsl)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new([330, 1, 0.6, 0.5], space: :hsl)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 0.5}}

  #### HSV

      iex>Ultraviolet.new({330, 0.8, 1}, space: :hsv)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.new([330, 0.8, 1, 0.5], space: :hsv)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 0.5}}

  #### Lab

      iex>Ultraviolet.new({40, -20, 50}, space: :lab)
      {:ok, %Ultraviolet.Color{r: 83, g: 102, b: 0, a: 1.0}}
      iex>Ultraviolet.new([40, -20, 50, 0.5], space: :lab)
      {:ok, %Ultraviolet.Color{r: 83, g: 102, b: 0, a: 0.5}}

  #### LCH / HCL

      iex>Ultraviolet.new({80, 40, 130}, space: :lch)
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}
      iex>Ultraviolet.new({130, 40, 80, 0.5}, space: :hcl)
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 0.5}}
      iex>Ultraviolet.new([80, 40, 130], space: :lch)
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}
      iex>Ultraviolet.new([h: 130, c: 40, l: 80, a: 0.5], space: :hcl)
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 0.5}}

  #### OKLab

      iex>Ultraviolet.new([0.4, -0.2, 0.5], space: :oklab)
      {:ok, %Ultraviolet.Color{r: 98, g: 68, b: 0, a: 1.0}}
      iex>Ultraviolet.new({0.4, -0.2, 0.5, 0.5}, space: :oklab)
      {:ok, %Ultraviolet.Color{r: 98, g: 68, b: 0, a: 0.5}}

  #### OKLCH

      iex>Ultraviolet.new([0.5, 0.2, 240], space: :oklch)
      {:ok, %Ultraviolet.Color{r: 0, g: 105, b: 199, a: 1.0}}
      iex>Ultraviolet.new({0.5, 0.2, 240, 0.5}, space: :oklch)
      {:ok, %Ultraviolet.Color{r: 0, g: 105, b: 199, a: 0.5}}
  """
  @spec new(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def new(input, options), do: Color.new(input, options)

  @doc """
  Generates the sRGB representation of a `Color.HSL`.

  ## Examples

      iex>Ultraviolet.hsl({330, 0.5, 1})
      {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}
      iex>Ultraviolet.hsl([330, 0.5, 1, 0.5], round: 1)
      {:ok, %Ultraviolet.Color{r: 255.0, g: 255.0, b: 255.0, a: 0.5}}

  """
  @spec hsl(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec hsl(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def hsl(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :hsl))
  end

  @doc """
  Generates the sRGB representation of a `Color.HSV`.

  ## Examples

      iex>Ultraviolet.hsv([330, 0.5, 1])
      {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}
      iex>Ultraviolet.hsv({330, 0.5, 1, 0.5}, round: 1)
      {:ok, %Ultraviolet.Color{r: 255.0, g: 255.0, b: 255.0, a: 0.5}}

  """
  @spec hsv(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec hsv(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def hsv(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :hsl))
  end

  @doc """
  Generates the sRGB representation of a `Color.Lab`

  ## Colorspace Options

  - `:reference`: the CIE Lab white reference point. Default: `:d65`

  ## Examples

      iex>Ultraviolet.lab({50, -20, 50})
      {:ok, %Ultraviolet.Color{r: 110, g: 127, b: 21, a: 1.0}}
      iex>Ultraviolet.lab([80, -20, 50], round: 1)
      {:ok, %Ultraviolet.Color{r: 192.3, g: 206.7, b: 101.7, a: 1.0}}
      iex>Ultraviolet.lab([80, -20, 50, 0.5], reference: :d50)
      {:ok, %Ultraviolet.Color{r: 184, g: 208, b: 100, a: 0.5}}

  """
  @spec lab(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec lab(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def lab(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :lab))
  end

  @doc """
  Genereates the sRGB representation of a `Color.LCH`.

  ## Colorspace Options

  - `:reference`: the CIE Lab white reference point. Default: `:d65`

  ## Example

      iex>Ultraviolet.lch({80, 40, 130})
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  """
  @spec lch(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec lch(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def lch(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :lch))
  end

  @doc """
  Genereates the sRGB representation of a `Color.LCH`.

  This is the same as `lch/2`, but with the channel order of the first
  argument reversed.

  ## Example

      iex>Ultraviolet.hcl({130, 40, 80})
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  """
  @spec hcl(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec hcl(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def hcl(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :hcl))
  end

  @doc """
  Genereates the sRGB representation of a `Color.OKLab`.

  ## Example

      iex>Ultraviolet.oklab({0.5, -0.2, 0.5})
      {:ok, %Ultraviolet.Color{r: 128, g: 97, b: 0, a: 1.0}}
      iex>Ultraviolet.oklab([0.8, -0.2, 0.5])
      {:ok, %Ultraviolet.Color{r: 217, g: 197, b: 0, a: 1.0}}

  """
  @spec oklab(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec oklab(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def oklab(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :oklab))
  end

  @doc """
  Genereates the sRGB representation of a `Color.OKLCH`.

  ## Example

      iex>Ultraviolet.oklch({0.8, 0.12, 60})
      {:ok, %Ultraviolet.Color{r: 246, g: 171, b: 107, a: 1.0}}

  """
  @spec oklch(Color.channels()) :: {:ok, Color.t()} | {:error, term()}
  @spec oklch(Color.channels(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def oklch(channels, options \\ []) when is_list(options) do
    new(channels, Keyword.merge(options, space: :oklch))
  end

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
  @spec temperature(non_neg_integer()) :: {:ok, Color.t()} | {:error, term()}
  def temperature(kelvin), do: Color.Temperature.to_rgb(kelvin)

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
  @spec mix(Color.input(), Color.input()) :: {:ok, Color.t()} | {:error, term()}
  @spec mix(Color.input(), Color.input(), float()) :: {:ok, Color.t()} | {:error, term()}
  @spec mix(Color.input(), Color.input(), float(), Color.space()) ::
          {:ok, Color.t()} | {:error, term()}
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

  Also works with alpha channels:

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
  @spec average([Color.input()]) :: {:ok, Color.t()} | {:error, term()}
  @spec average([Color.input()], float()) :: {:ok, Color.t()} | {:error, term()}
  @spec average([Color.input()], float(), Color.space()) :: {:ok, Color.t()} | {:error, term()}
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
      iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :screen);
      iex>Ultraviolet.Color.hex(color)
      "#f3fafc"
      iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :overlay);
      iex>Ultraviolet.Color.hex(color)
      "#e7f643"
      iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :burn);
      iex>Ultraviolet.Color.hex(color)
      "#c6e81f"
      iex>{:ok, color} = Ultraviolet.blend("4cbbfc", "eeee22", :dodge);
      iex>Ultraviolet.Color.hex(color)
      "#ffffff"

  """
  @spec blend(Color.input(), Color.input(), Color.space()) :: {:ok, Color.t()} | {:error, term()}
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
  - `Ultraviolet.Scale.take/2` or `Ultraviolet.Scale.take_keys/2` to get several colors at once

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
      iex>Ultraviolet.Scale.take_keys(scale, [0, 1])
      [
        %Ultraviolet.Color{r: 255, g: 255, b: 0},
        %Ultraviolet.Color{r: 0, g: 138, b: 229},
      ]
      iex>{:ok, scale} = Ultraviolet.scale(["yellow", "red", "black"]);
      iex>Ultraviolet.Scale.take_keys(scale, [0, 0.5, 1])
      [
        %Ultraviolet.Color{r: 255, g: 255, b: 0},
        %Ultraviolet.Color{r: 255, g: 0, b: 0},
        %Ultraviolet.Color{r: 0, g: 0, b: 0},
      ]

  ## Options

  Scales can be created with a number of options which affect the output colors:

  ### Domain

  You can change the input domain to match your use case. The default domain is
  `[0, 1]`.

      iex>{:ok, scale} = Ultraviolet.scale(["yellow", "008ae5"], domain: [0, 100]);
      iex>Enum.map(Ultraviolet.Scale.take_keys(scale, [0, 100]), &Ultraviolet.Color.hex/1)
      ["#ffff00", "#008ae5"]

  You can use this option to set the exact positions of each color:

      iex>{:ok, scale} = Ultraviolet.scale(
      ...>  ["yellow", "lightgreen", "008ae5"],
      ...>  domain: [0, 0.25, 1]
      ...>);
      iex>Enum.map(Ultraviolet.Scale.take_keys(scale, [0, 0.25, 1]), &Ultraviolet.Color.hex/1)
      ["#ffff00", "#90ee90", "#008ae5"]

  ### Color Space

  As with `mix/2`, the result of color interpolation will depend on the color
  space in which the channels are interpolated. The default `:space` is `:rgb`.

  This default is okay, but sometimes, two-color RGB gradients go through a gray
  "dead zone", which...doesn't look great. Other color spaces can produce better
  results.

      iex>{:ok, scale} = Ultraviolet.scale(["yellow", "navy"]);
      iex>{:ok, color} = Ultraviolet.Scale.fetch(scale, 0.6);
      iex>Ultraviolet.Color.hex(color)
      # this is mostly gray
      "#66664d"
      iex>{:ok, scale} = Ultraviolet.scale(["yellow", "navy"], space: :lab);
      iex>{:ok, color} = Ultraviolet.Scale.fetch(scale, 0.6);
      iex>Ultraviolet.Color.hex(color)
      # this is better
      "#8e6271"

  The available values for this option are the same as with `Ultaviolet.mix/2`.

  ### Gamma Correction

  `:gamma` can be used to "shift" a scale's center more towards the beginning
  (`:gamma` < 1) or the end (`:gamma` > 1). This option is typically used to
  "even out" the lightness gradient. The default gamma is `1`.

      iex>{:ok, _scale} = Ultraviolet.scale(["yellow", "green"], gamma: 0.5);
      iex>{:ok, _scale} = Ultraviolet.scale(["yellow", "green"], gamma: 1);
      iex>{:ok, _scale} = Ultraviolet.scale(["yellow", "green"], gamma: 2);

  ### Lightness Correction

  `:correct_lightness?` makes sure the lightness range is spread evenly across a
  color scale. This option is especially useful when working with multi-hue
  color scales. where simple gamma correction won't help very much. The default
  value is `false`, i.e. lightness correction turned off.

      iex>{:ok, scale} = Ultraviolet.scale(
      ...>  ["black", "red", "yellow", "white"]
      ...>);
      iex>{:ok, color} = Ultraviolet.Scale.fetch(scale, 0.67);
      iex>Ultraviolet.Color.hex(color)
      "#ffff03"
      iex>{:ok, corrected_scale} = Ultraviolet.scale(
      ...>  ["black", "red", "yellow", "white"],
      ...>  correct_lightness?: true
      ...>);
      iex>{:ok, color} = Ultraviolet.Scale.fetch(corrected_scale, 0.67);
      iex>Ultraviolet.Color.hex(color)
      "#ff8000"

  ### Padding

  `:padding` reduces the color range by cutting off a fraction of the gradient
  on both sides. If you pass a single number, the same padding will be applied
  to both sides. The default padding is `0`, i.e. no padding applied.

      iex>{:ok, _scale} = Ultraviolet.scale(
      ...>  ["red", "yellow", "blue"],
      ...>  padding: 0.15
      ...>);

  Alternatively, you can specify the padding for each side individually by
  passing a two-number tuple:

      iex>{:ok, _scale} = Ultraviolet.scale(
      ...>  ["red", "yellow", "blue"],
      ...>  padding: {0.2, 0}
      ...>);

  ### Classes

  If you want the scale to return a distinct set of colors instead of a
  continuous gradient, you can use the `:classes` option. Passing an integer
  will break up the scale into equidistant classes. 

      iex>{:ok, scale} = Ultraviolet.scale("OrRd", classes: 5);
      iex>Enum.map(Ultraviolet.Scale.take_keys(scale, [0.1, 0.15]), &Ultraviolet.Color.hex/1)
      ["#fff7ec", "#fff7ec"]

  You can also define custom class breaks by passing them as an array.

      iex>{:ok, scale} = Ultraviolet.scale(
      ...>  "OrRd",
      ...>  classes: [0, 0.3, 0.55, 0.85, 1]
      ...>);
      iex>Enum.map(Ultraviolet.Scale.take_keys(scale, [0.15, 0.25]), &Ultraviolet.Color.hex/1)
      ["#fff7ec", "#fff7ec"]

  The default value is `0`, meaning a continuous gradient will be used.

  ### Interpolation

  By default, the colors retrieved from the scale are the result of linear
  interpolation. If you want to change this, use the `:interpolation` option.

  This option accepts a unary function (i.e. a function with one argument),
  which will be called every time a color retrieval function is called on that
  space. It should accept a number and return a `Ultraviolet.Color` or an
  `{:ok, Ultraviolet.Color}` tuple.

  There are also two builtin interpolation options: `:linear` for linear
  interpolation (the default) and `:bezier` for Bezier interpolation. For
  `:bezier` interpolation, the `:space` must be either `:lab` or `:oklab`.
  If no `:space` option is passed, `:lab` will be used.

      iex>{:ok, scale} = Ultraviolet.scale(["yellow", "red", "black"]);
      iex>Enum.map(Ultraviolet.Scale.take(scale, 5), &Ultraviolet.Color.hex/1)
      ["#ffff00", "#ff8000", "#ff0000", "#800000", "#000000"]
      iex>Ultraviolet.scale(
      ...>  ["yellow", "red", "black"],
      ...>  interpolation: :bezier,
      ...>  space: :rgb
      ...>)
      {:error, "bezier interpolation requires either Lab or OKLab colorspace"}
      iex>{:ok, bezier_scale} = Ultraviolet.scale(
      ...>  ["yellow", "red", "black"],
      ...>  interpolation: :bezier
      ...>);
      iex>Enum.map(Ultraviolet.Scale.take(bezier_scale, 5), &Ultraviolet.Color.hex/1)
      ["#ffff00", "#f5a900", "#bf5e0b", "#6c280e", "#000000"]

  #### Example: `cubehelix`

  Here's how you might use this option to implement Dave Green's
  [cubehelix scheme](https://people.phy.cam.ac.uk/dag9/CUBEHELIX/):

      iex>defmodule CubeHelix do
      ...>  def interpolate(x, params) do
      ...>    a = :math.tau() * ((params.start + 120) / 360 + params.rotations * x)
      ...>    l = :math.pow(lightness(params) + dl(params) * x, params.gamma)
      ...>    h = hue(params, x)
      ...>    amp = (h * l * (1 - l)) / 2
      ...>    cos_a = :math.cos(a)
      ...>    sin_a = :math.sin(a)
      ...>    [
      ...>      l + amp * (-0.14861 * cos_a + 1.78277 * sin_a),
      ...>      l + amp * (-0.29277 * cos_a - 0.90649 * sin_a),
      ...>      l + amp * (1.97294 * cos_a)
      ...>    ]
      ...>    |> Enum.map(&clamp_byte(&1 * 255))
      ...>    |> Ultraviolet.Color.new()
      ...>  end
      ...>
      ...>  defp lightness(%{lightness: {l0, _}}), do: l0
      ...>  defp lightness(%{lightness: l}), do: l
      ...>
      ...>  defp dl(%{lightness: {l0, l1}}), do: l1 - l0
      ...>  defp dl(%{lightness: _}), do: 0
      ...>
      ...>  defp hue(%{hue: {h0, h1}}, x), do: h0 + x * (h1 - h0)
      ...>  defp hue(%{hue: hue}, _x), do: hue
      ...>
      ...>  defp clamp_byte(n), do: min(max(n, 0), 255)
      ...>end;
      iex>params = %{start: 300, rotations: -1.5, hue: 1, gamma: 1, lightness: {0, 1}};
      iex>{:ok, cubehelix} = Ultraviolet.scale(
      ...>  ["black", "white"],
      ...>  domain: [0, 1],
      ...>  interpolation: fn x -> CubeHelix.interpolate(x, params) end
      ...>);
      iex>Enum.map(Ultraviolet.Scale.take(cubehelix, 5), &Ultraviolet.Color.hex/1)
      ["#000000", "#16534c", "#a07949", "#c7b3ed", "#ffffff"]

  ## Color Brewer

  Ultraviolet includes the definitions from
  [ColorBrewer](https://colorbrewer2.org) as well.

      iex>{:ok, scale} = Ultraviolet.scale("OrRd");
      iex>Enum.map(Ultraviolet.Scale.take(scale, 5), &Ultraviolet.Color.hex/1)
      ["#fff7ec", "#fdd49e", "#fc8d59", "#d7301f", "#7f0000"]

  You can reverse the colors by reversing the domain:

      iex>{:ok, scale} = Ultraviolet.scale("YlGnBu", domain: [1, 0]);
      iex>Ultraviolet.Scale.fetch(scale, 0.25)
      {:ok, %Ultraviolet.Color{r: 34, g: 94, b: 168}}

  ### Color Count

  You can include a `:count` option when creating a ColorBrewer-based scale
  to retrieve the Color Brewer palette with the given number of colors.
  The default is `9`.

      iex>{:ok, scale} = Ultraviolet.scale("YlGnBu", count: 5);
      iex> scale.colors
      [
        %Ultraviolet.Color{r: 255, g: 255, b: 204, a: 1.0},
        %Ultraviolet.Color{r: 161, g: 218, b: 180, a: 1.0},
        %Ultraviolet.Color{r: 65, g: 182, b: 196, a: 1.0},
        %Ultraviolet.Color{r: 44, g: 127, b: 184, a: 1.0},
        %Ultraviolet.Color{r: 37, g: 52, b: 148, a: 1.0}
      ]

  """
  @spec scale() :: {:ok, Scale.t()} | {:error, term()}
  def scale(), do: scale(["white", "black"], [])

  @spec scale([Color.input()] | String.t()) :: {:ok, Scale.t()} | {:error, term()}
  def scale(colors), do: scale(colors, [])

  @spec scale([Color.input()] | String.t(), [...]) :: {:ok, Scale.t()} | {:error, term()}
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
