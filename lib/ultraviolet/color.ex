defmodule Ultraviolet.Color do
  @moduledoc """
  functions related to parsing and generating Color structs for use elsewhere
  in Ultraviolet.

  ## Color Spaces

  Colors, by default, are stored in sRGB representation, but supports other
  color spaces as input to `new/4` and `new/5`, where the last parameter is the
  color space to translate from.

  ### Available Spaces

  - sRGB (the default): `:rgb`
  - HSL: `:hsl`
  - CIE Lab: `:lab`
  - LCH: `:lch`, `:hcl`
  - OKLab: `:oklab`
  - OKLCH: `:oklch`

  ### To add

  - GL (RGBA normalized to `0..1`)
  - CMYK

  """
  import Bitwise, only: [bsr: 2, band: 2]
  import Ultraviolet.Helpers

  alias Ultraviolet.Color.{HSL, HSV, Lab, LCH, OKLab, OKLCH, Temperature}
  alias __MODULE__

  @me __MODULE__

  @space_to_module %{
    hsl: HSL,
    hsv: HSV,
    lab: Lab,
    lch: LCH,
    hcl: LCH,
    oklab: OKLab,
    oklch: OKLCH
  }
  @typedoc """
  A structure defining the channels in an sRGB Color.

  This is the core Ultraviolet structure. See `Ultraviolet` for examples
  of how it can be used.
  """
  @type t :: %{r: number(), g: number(), b: number(), a: number()}

  @typedoc """
  The available color spaces for transformation, interpolation, and scales.
  """
  @type space :: :rgb | :lrgb | :hsl | :lab | :lch | :hcl | :oklab | :oklch
  @type space_t :: t() | HSL.t() | HSV.t() | Lab.t() | LCH.t() | OKLab.t() | OKLCH.t()

  @typedoc """
  Generic channel input for a color creation function.
  """
  @type channels :: [number()] | tuple() | [...] | map()

  @typedoc """
  Generic input for a color creation function.
  """
  @type input :: String.t() | integer() | channels() | t()

  defstruct r: 0, g: 0, b: 0, a: 1.0

  # source of named colors
  @external_resource named_colors_path = Path.join([__DIR__, "named-colors.txt"])

  @doc """
  Generates a `Color` from a hex string, W3CX11 specification color name,
  integer, or channel tuple/map/list/keyword list.

  See `Ultraviolet.new/1` for more details.
  """
  @spec new(String.t() | integer() | [...] | map() | t()) ::
          {:ok, t()} | {:error, term()}
  for line <- File.stream!(named_colors_path, [], :line) do
    [name, hex] = line |> String.split(" ") |> Enum.map(&String.trim/1)

    def new(unquote(name)), do: new(unquote(hex))
  end

  def new("#" <> rest), do: new(rest)

  # normal hexadecimal
  def new(<<r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    case parse_hex_list(r: r, g: g, b: b) do
      {:error, _} = error -> error
      valid_list -> {:ok, struct(@me, valid_list)}
    end
  end

  # hexadecimal with alpha
  def new(<<r::binary-size(2), g::binary-size(2), b::binary-size(2), a::binary-size(2)>>) do
    case parse_hex_list(r: r, g: g, b: b, a: a) do
      {:error, _} = error ->
        error

      valid_list ->
        {:ok, struct(@me, Keyword.update!(valid_list, :a, &(&1 / 255)))}
    end
  end

  # short hexadecimal
  def new(<<r::binary-size(1), g::binary-size(1), b::binary-size(1)>>) do
    case parse_hex_list(r: r <> r, g: g <> g, b: b <> b) do
      {:error, _} = error -> error
      valid_list -> {:ok, struct(@me, valid_list)}
    end
  end

  # short hexadecimal with alpha
  def new(<<r::binary-size(1), g::binary-size(1), b::binary-size(1), a::binary-size(1)>>) do
    case parse_hex_list(r: r <> r, g: g <> g, b: b <> b, a: a <> a) do
      {:error, _} = error ->
        error

      valid_list ->
        {:ok, struct(@me, Keyword.update!(valid_list, :a, &(&1 / 255)))}
    end
  end

  # hexadecimal number (6-digit only!)
  def new(n) when is_integer(n) and n >= 0 and n <= 16_777_215 do
    [:b, :g, :r]
    |> Enum.reduce_while({[], n}, fn
      _, {list, 0} ->
        {:halt, {list, 0}}

      key, {list, acc} ->
        {:cont, {Keyword.put(list, key, band(acc, 0xFF)), bsr(acc, 8)}}
    end)
    |> then(fn {list, _n} -> {:ok, struct(@me, list)} end)
  end

  # list of RGB values
  def new([r, g, b]) when is_byte(r) and is_byte(g) and is_byte(b) do
    {:ok, struct(@me, r: r, g: g, b: b)}
  end

  def new([r, g, b, a])
      when is_byte(r) and is_byte(g) and is_byte(b) and is_unit_interval(a) do
    {:ok, struct(@me, r: r, g: g, b: b, a: a)}
  end

  # tuple of RGB values
  def new({r, g, b}) when is_byte(r) and is_byte(g) and is_byte(b) do
    {:ok, struct(@me, r: r, g: g, b: b)}
  end

  def new({r, g, b, a})
      when is_byte(r) and is_byte(g) and is_byte(b) and is_unit_interval(a) do
    {:ok, struct(@me, r: r, g: g, b: b, a: a)}
  end

  # already a Color
  def new(%Color{} = c), do: {:ok, c}

  # map of RGB values
  def new(channels) when is_map(channels) do
    new([
      Map.get(channels, :r),
      Map.get(channels, :g),
      Map.get(channels, :b),
      Map.get(channels, :a, 1.0)
    ])
  end

  # keyword list of RGB values
  def new([{k, _} | _rest] = channels) when is_list(channels) and is_atom(k) do
    new(Enum.into(channels, %{}))
  end

  def new(_), do: {:error, :invalid}

  @doc """
  Creates a new `Color` from the given `input` and `options`.

  See `Ultraviolet.new/2` for more details.
  """
  @spec new(channels(), [...]) :: {:ok, t()} | {:error, term()}
  def new(channels, options) when is_list(options) do
    {space, options} = Keyword.pop(options, :space, :rgb)
    new_in_space(channels, space, options)
  end

  defp parse_hex_list(arg_list) when is_list(arg_list) do
    Enum.reduce_while(arg_list, [], fn {key, hex}, acc ->
      case Integer.parse(hex, 16) do
        {value, ""} when is_byte(value) ->
          {:cont, [{key, value} | acc]}

        :error ->
          {:halt, {:error, "#{key} value must be a hex value between 0 and ff, got: #{hex}"}}
      end
    end)
  end

  defp new_in_space(channels, space, _opts) when space in [:rgb, :lrgb] do
    new(channels)
  end

  # reverse HCL channels in these cases
  defp new_in_space({h, c, l}, :hcl, opts) do
    new_in_space({l, c, h}, :lch, opts)
  end

  defp new_in_space({h, c, l, a}, :hcl, opts) do
    new_in_space({l, c, h, a}, :lch, opts)
  end

  defp new_in_space([h, c, l], :hcl, opts) when is_number(h) do
    new_in_space([l, c, h], :lch, opts)
  end

  defp new_in_space([h, c, l, a], :hcl, opts) when is_number(h) do
    new_in_space([l, c, h, a], :lch, opts)
  end

  defp new_in_space(channels, other, opts) do
    with {:ok, module} <- Map.fetch(@space_to_module, other),
         {:ok, color} <- module.new(channels) do
      module.to_rgb(color, opts)
    end
  end

  @doc """
  Converts a Color to a different colorspace.

  ## Examples

  ### HSL

      iex>{:ok, color} = Ultraviolet.Color.new("#ff3399")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153}}
      iex> Ultraviolet.Color.into(color, :hsl)
      {:ok, %Ultraviolet.Color.HSL{h: 330, s: 1.0, l: 0.6}}

  ### HSV / HSB

      iex>{:ok, color} = Ultraviolet.Color.new("#ff3399")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153}}
      iex> Ultraviolet.Color.into(color, :hsv)
      {:ok, %Ultraviolet.Color.HSV{h: 330, s: 0.8, v: 1.0}}

  ### Lab

      iex>{:ok, color} = Ultraviolet.Color.new("hotpink")
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180}}
      iex> Ultraviolet.Color.into(color, :lab)
      {:ok, %Ultraviolet.Color.Lab{l_: 65.49, a_: 64.24, b_: -10.65}}
      iex> Ultraviolet.Color.into(color, :lab, reference: :f2)
      {:ok, %Ultraviolet.Color.Lab{l_: 66.28, a_: 61.45, b_: -8.62}}
      # try going the other way now
      iex> Ultraviolet.new({66.28, 61.45, -8.62, 1.0}, space: :lab, reference: :f2)
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180}}
      iex> Ultraviolet.new(%{l_: 66.28, a_: 61.45, b_: -8.62}, space: :lab, reference: :f2)
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180}}
      iex> Ultraviolet.new({65.49, 64.24, -10.65, 1.0}, space: :lab)
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180}}

  ### LCH / HCL

      iex>{:ok, color} = Ultraviolet.Color.new("#aad28c")
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}
      iex> Ultraviolet.Color.into(color, :lch, round: 0)
      {:ok, %Ultraviolet.Color.LCH{l: 80, c: 40, h: 130}}
      iex> Ultraviolet.Color.into(color, :hcl, round: 0)
      {:ok, %Ultraviolet.Color.LCH{l: 80, c: 40, h: 130}}

  ### OKLab

      iex>{:ok, color} = Ultraviolet.Color.new("#d9c500")
      {:ok, %Ultraviolet.Color{r: 217, g: 197, b: 0, a: 1.0}}
      iex> Ultraviolet.Color.into(color, :oklab, round: 2)
      {:ok, %Ultraviolet.Color.OKLab{l_: 0.81, a_: -0.04, b_: 0.17}}

  ### OKLCH

      iex>{:ok, color} = Ultraviolet.Color.new("#aad28c")
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}
      iex> Ultraviolet.Color.into(color, :oklch, round: 0)
      {:ok, %Ultraviolet.Color.OKLCH{l: 1, c: 0, h: 132}}
      iex> Ultraviolet.Color.into(color, :oklch, round: 1)
      {:ok, %Ultraviolet.Color.OKLCH{l: 0.8, c: 0.1, h: 132.5}}
  """
  @spec into(t(), space()) :: {:ok, space_t()} | {:error, term()}
  @spec into(t(), space(), [...]) :: {:ok, space_t()} | {:error, term()}
  def into(color, space, options \\ [])

  def into(%Color{} = color, rgb, _options) when rgb in [:rgb, :lrgb] do
    {:ok, color}
  end

  def into(%Color{} = color, space, options) when is_list(options) do
    with {:ok, module} <- Map.fetch(@space_to_module, space) do
      module.from_rgb(color, options)
    end
  end

  def into(_, _, _), do: {:error, :invalid}

  @doc """
  Estimates the temperature of a given color, though this only makes sense for
  colors from the temperature gradient.

  ## Examples

      iex> {:ok, color} = Color.new("#ff3300");
      iex> Color.temperature(color)
      1000
      iex> {:ok, color} = Color.new("#ff8a13");
      iex> Color.temperature(color)
      2000
      iex> {:ok, color} = Color.new("#ffe3cd");
      iex> Color.temperature(color)
      4985
      iex> {:ok, color} = Color.new("#cbdbff");
      iex> Color.temperature(color)
      10049
      iex> {:ok, color} = Color.new("#b3ccff");
      iex> Color.temperature(color)
      15005

  """
  def temperature(%Color{} = color), do: Temperature.from_rgb(color)

  @doc """
  Get the color opacity.

  ## Examples

      iex> {:ok, color} = Color.new("red");
      iex> Color.alpha(color)
      1.0
  """
  # this works because all Color structs use `:a` for opacity
  @spec alpha(space_t()) :: number()
  def alpha(%{a: a} = color) when is_struct(color), do: a

  @doc """
  Set the color opacity.

  ## Examples

      iex> {:ok, color} = Color.new("red");
      iex> Color.alpha(color, 0.5)
      %Color{r: 255, g: 0, b: 0, a: 0.5}
  """
  @spec alpha(space_t(), number()) :: space_t()
  def alpha(color, alpha) when is_struct(color) and is_unit_interval(alpha) do
    %{color | a: alpha}
  end

  # operation step amount
  @op_step 18

  @doc """
  Brighten a color.

  ## Examples

      iex> {:ok, color} = Color.new("hotpink");
      iex> Color.hex(Color.brighten!(color))
      "#ff9ce6"
      iex> Color.hex(Color.brighten!(color, 2))
      "#ffd1ff"
      iex> Color.hex(Color.brighten!(color, 3))
      "#ffffff"

  """
  @spec brighten!(t(), number()) :: t()
  def brighten!(%Color{} = color, amount \\ 1) do
    color
    |> into(:lab)
    |> ok!()
    |> Map.update!(:l_, &(&1 + @op_step * amount))
    |> Lab.to_rgb(round: false)
    |> ok!()
  end

  @doc """
  Darken a color.

  ## Examples

      iex> {:ok, color} = Color.new("hotpink");
      iex> Color.hex(Color.darken!(color))
      "#c93384"
      iex> Color.hex(Color.darken!(color, 2))
      "#940058"
      iex> Color.hex(Color.darken!(color, 2.6))
      "#74003f"

  """
  @spec darken!(t(), number()) :: t()
  def darken!(%Color{} = color, amount \\ 1), do: brighten!(color, -amount)

  @doc """
  Increases the saturation of a color by manipulating the Lch chromaticity.

  ## Examples

      iex> {:ok, color} = Color.new("slategray");
      iex> Color.hex(Color.saturate!(color))
      "#4b83ae"
      iex> Color.hex(Color.saturate!(color, 2))
      "#0087cd"
      iex> Color.hex(Color.saturate!(color, 3))
      "#008bec"
  """
  @spec saturate!(t(), number()) :: t()
  def saturate!(%Color{} = color, amount \\ 1) do
    color
    |> into(:lch)
    |> ok!()
    |> Map.update!(:c, &(&1 + @op_step * amount))
    |> LCH.to_rgb(round: false)
    |> ok!()
  end

  @doc """
  Decreases the saturation of a color by manipulating the Lch chromaticity.

  ## Examples

      iex> {:ok, color} = Color.new("hotpink");
      iex> Color.hex(Color.desaturate!(color))
      "#e77dae"
      iex> Color.hex(Color.desaturate!(color, 2))
      "#cd8ca8"
      iex> Color.hex(Color.desaturate!(color, 3))
      "#b199a3"
  """
  @spec desaturate!(t(), number()) :: t()
  def desaturate!(%Color{} = color, amount \\ 1), do: saturate!(color, -amount)

  @doc """
  Produces a shade of the given color. This is syntactic sugar for `mix/4`
  with a target color of `black`.

  ## Examples

      iex>{:ok, color} = Color.new("hotpink");
      iex> Color.hex(Color.shade!(color, 0.25))
      "#dd5b9c"
      iex> Color.hex(Color.shade!(color, 0.5))
      "#b44a7f"
      iex> Color.hex(Color.shade!(color, 0.75))
      "#80355a"
  """
  @spec shade!(t()) :: t()
  @spec shade!(t(), number()) :: t()
  @spec shade!(t(), number(), space()) :: t()
  def shade!(color, ratio \\ 0.5, space \\ :lrgb) do
    color
    |> mix(%Color{r: 0, g: 0, b: 0}, ratio, space)
    |> ok!()
  end

  @doc """
  Produces a tint of the given color. This is syntactic sugar for `mix/4`
  with a target color of `white`.

  ## Examples

      iex>{:ok, color} = Color.new("hotpink");
      iex> Color.hex(Color.tint!(color, 0.25))
      "#ff9dc9"
      iex> Color.hex(Color.tint!(color, 0.5))
      "#ffc3dd"
      iex> Color.hex(Color.tint!(color, 0.75))
      "#ffe3ee"
  """
  @spec tint!(t()) :: t()
  @spec tint!(t(), number()) :: t()
  @spec tint!(t(), number(), space()) :: t()
  def tint!(color, ratio \\ 0.5, space \\ :lrgb) do
    color
    |> mix(%Color{r: 255, g: 255, b: 255}, ratio, space)
    |> ok!()
  end

  @doc """
  Mixes two colors. The mix `weight` is a value between 0 and 1.

  See `Ultraviolet.mix/4` for documentation and examples.
  """
  @spec mix(t(), t()) :: {:ok, t()} | {:error, term()}
  @spec mix(t(), t(), number()) :: {:ok, t()} | {:error, term()}
  @spec mix(t(), t(), number(), space()) :: {:ok, t()} | {:error, term()}
  # coveralls-ignore-next-line
  def mix(color, target, weight \\ 0.5, space \\ :lrgb)

  def mix(_color, _target, w, _space) when not is_unit_interval(w) do
    {:error, "expected a ratio between 0 and 1, got: #{w}"}
  end

  def mix(color, target, w, space) do
    average(color, [target], space, [1 - w, w])
  end

  @doc """
  Mixes several colors. If `weights` are given, a weighted average is
  calculated; the number of `weights` must equal the number of colors.

  See `Ultraviolet.average/3` for documentation and examples.
  """
  @spec average(t(), [t()]) :: {:ok, t()} | {:error, term()}
  @spec average(t(), [t()], space()) :: {:ok, t()} | {:error, term()}
  @spec average(t(), [t()], space(), [number()] | nil) :: {:ok, t()} | {:error, term()}
  # coveralls-ignore-next-line
  def average(color, targets, space \\ :lrgb, weights \\ nil)

  def average(color, targets, space, nil) do
    average(color, targets, space, Enum.map([color | targets], fn _ -> 1 end))
  end

  def average(color, targets, space, weights) do
    case validate_all([color | targets], &into(&1, space)) do
      {:ok, color_list} ->
        color_list
        |> Enum.map(&Map.from_struct/1)
        |> Enum.zip_with(& &1)
        |> Enum.map(&weighted_average(&1, normalize(weights), space))
        |> List.flatten()
        |> Enum.reduce(%{}, fn {k, v}, m ->
          Map.update(m, k, v, &tuple_sum(&1, v))
        end)
        |> Enum.map(&consolidate(&1, space))
        |> Enum.into(%{})
        |> new(space: space)

      error ->
        error
    end
  end

  defp normalize(values) do
    values
    |> Enum.sum()
    |> then(&Enum.map(values, fn v -> v / &1 end))
  end

  defp weighted_average(components, weights, space) do
    components
    |> Enum.zip(weights)
    |> Enum.map(&channel_with_weight(&1, space))
  end

  # alpha channel is always a simple weighted average
  defp channel_with_weight({{:a, value}, weight}, _space) do
    {:a, weight * value}
  end

  defp channel_with_weight({{channel, value}, weight}, :lrgb) do
    {channel, weight * value * value}
  end

  # since hues are angles, we need to use a different weighted average
  defp channel_with_weight({{:h, degrees}, weight}, _space) do
    radians = degrees * :math.pi() / 180
    {:h, {:math.cos(radians) * weight, :math.sin(radians) * weight}}
  end

  defp channel_with_weight({{channel, value}, weight}, _space) do
    {channel, weight * value}
  end

  # required because sometimes the weighted average returns a tuple
  # the tuple will be resolved during `consolidate/2`
  defp tuple_sum({v1, w1}, {v2, w2}), do: {v1 + v2, w1 + w2}
  defp tuple_sum(v1, v2), do: v1 + v2

  # the final step...
  # alpha channel is always a simple weighted average
  defp consolidate({:a, v}, _space), do: {:a, v}
  defp consolidate({k, v}, :lrgb), do: {k, clamp_to_byte(:math.sqrt(v))}
  defp consolidate({k, v}, :rgb), do: {k, clamp_to_byte(v)}

  defp consolidate({:h, {cos, sin}}, _space) do
    {:h, maybe_correct_hue(:math.atan2(sin, cos) * 180 / :math.pi())}
  end

  defp consolidate({k, v}, _space), do: {k, v}

  defp maybe_correct_hue(h) when h < 0, do: maybe_correct_hue(h + 360)
  defp maybe_correct_hue(h) when h > 360, do: maybe_correct_hue(h - 360)
  defp maybe_correct_hue(h), do: h

  @type blend_mode ::
          :normal | :multiply | :darken | :lighten | :screen | :overlay | :burn | :dodge

  @doc """
  Blends two colors using RGB channel-wise blend functions. See
  `Ultraviolet.blend/3` for examples and valid blend spaces.
  """
  @spec blend(t(), t()) :: {:ok, t()} | {:error, term()}
  @spec blend(t(), t(), blend_mode()) :: {:ok, t()} | {:error, term()}
  def blend(color, mask, blend_mode \\ :normal)

  def blend(%Color{} = color, %Color{} = mask, blend_mode) do
    [color, mask]
    |> Enum.map(&[&1.r, &1.g, &1.b])
    |> Enum.zip()
    |> Enum.map(&do_blend(&1, blend_mode))
    |> new()
  end

  def blend(_, _, _), do: {:error, :invalid}

  defp do_blend({color, mask}, :multiply), do: color * mask / 255
  defp do_blend({color, mask}, :darken), do: min(color, mask)
  defp do_blend({color, mask}, :lighten), do: max(color, mask)

  defp do_blend({color, mask}, :screen) do
    255 * (1 - (1 - color / 255) * (1 - mask / 255))
  end

  defp do_blend({color, mask}, :overlay) when mask < 128 do
    2 * color * mask / 255
  end

  defp do_blend({color, mask}, :overlay) do
    255 * (1 - 2 * (1 - color / 255) * (1 - mask / 255))
  end

  defp do_blend({color, mask}, :burn) do
    255 * (1 - (1 - mask / 255) / (color / 255))
  end

  defp do_blend({255, _mask}, :dodge), do: 255

  defp do_blend({color, mask}, :dodge) do
    min(255 * (mask / 255) / (1 - color / 255), 255)
  end

  defp do_blend({color, _}, _), do: color

  @doc """
  Returns the hexadecimal representation of an RGB color.

  ## Examples

      iex>Color.hex(%Color{})
      "#000000"
      iex>Color.hex(%Color{r: 255})
      "#ff0000"
      iex>Color.hex(%Color{r: 255, a: 0.5})
      "#ff000080"

  You can also use `to_string` to output this value

      iex>to_string(%Color{r: 255, a: 0.5})
      "#ff000080"

  """
  @spec hex(t()) :: String.t()
  def hex(%Color{r: r, g: g, b: b, a: 1.0}) do
    [r, g, b]
    |> Enum.map(&to_hex/1)
    |> Enum.join()
    |> then(&String.downcase("##{&1}"))
  end

  def hex(%Color{r: r, g: g, b: b, a: a}) do
    [r, g, b, a * 255]
    |> Enum.map(&to_hex/1)
    |> Enum.join()
    |> then(&String.downcase("##{&1}"))
  end

  defp to_hex(value) when is_float(value), do: to_hex(round(value))
  defp to_hex(value) when value < 16, do: "0" <> Integer.to_string(value, 16)
  defp to_hex(value), do: Integer.to_string(value, 16)

  @doc """
  Returns the CSS representation of an RGB color

  ## Examples

      iex>Color.css(%Color{})
      "rgb(0 0 0)"
      iex>Color.css(%Color{r: 255})
      "rgb(255 0 0)"
      iex>Color.css(%Color{r: 255, a: 0.5})
      "rgb(255 0 0 / 0.5)"
  """
  @spec css(t()) :: String.t()
  def css(%Color{r: r, g: g, b: b, a: 1.0}) do
    [r, g, b]
    |> Enum.map(&round/1)
    |> Enum.join(" ")
    |> then(&"rgb(#{&1})")
  end

  def css(%Color{r: r, g: g, b: b, a: a}) do
    [r, g, b]
    |> Enum.map(&round/1)
    |> Enum.join(" ")
    |> then(&"rgb(#{&1} / #{a})")
  end

  # shorthand to deconstruct {:ok, result} structs
  defp ok!({:ok, result}), do: result

  defp ok!(other) do
    raise "expected a structure like {:ok, result}, got: #{inspect(other)}"
  end
end

defimpl String.Chars, for: Ultraviolet.Color do
  def to_string(color), do: Ultraviolet.Color.hex(color)
end
