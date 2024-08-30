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

  defstruct r: 0, g: 0, b: 0, a: 1.0

  # shortcut for checking valid rgba values
  defguardp is_byte(n) when is_number(n) and n >= 0 and n <= 255
  defguardp is_normalized(n) when is_number(n) and n >= 0 and n <= 1

  # source of named colors
  @external_resource named_colors_path = Path.join([__DIR__, "named-colors.txt"])

  for line <- File.stream!(named_colors_path, [], :line) do
    [name, hex] = line |> String.split(" ") |> Enum.map(&String.trim/1)

    def new(unquote(name)), do: new(unquote(hex))
  end

  # hexadecimal: leading '#' is optional
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
    case parse_hex_list(r: r<>r, g: g<>g, b: b<>b) do
      {:error, _} = error -> error
      valid_list -> {:ok, struct(@me, valid_list)}
    end
  end

  # short hexadecimal with alpha
  def new(<<r::binary-size(1), g::binary-size(1), b::binary-size(1), a::binary-size(1)>>) do
    case parse_hex_list(r: r<>r, g: g<>g, b: b<>b, a: a<>a) do
      {:error, _} = error ->
        error
      valid_list ->
        {:ok, struct(@me, Keyword.update!(valid_list, :a, &(&1 / 255)))}
    end
  end

  # hexadecimal number (6-digit only!)
  def new(n) when is_integer(n) and n >= 0 and n <= 16777215 do
    [:b, :g, :r]
    |> Enum.reduce_while({[], n}, fn
      _, {list, 0} ->
        {:halt, {list, 0}}
      key, {list, acc} ->
        {:cont, {Keyword.put(list, key, band(acc, 0xff)), bsr(acc, 8)}}
    end)
    |> then(fn {list, _n} -> {:ok, struct(@me, list)} end)
  end

  # list of RGB values
  def new([r, g, b]) when is_byte(r) and is_byte(g) and is_byte(b) do
    {:ok, struct(@me, r: r, g: g, b: b)}
  end

  # already a Color
  def new(%Color{} = c), do: {:ok, c}

  def new(_), do: {:error, :invalid}

  # map + mode
  def new(%{r: r, g: g, b: b} = rgb, mode) when mode in [:rgb, :lrgb] do
    new(r, g, b, alpha: Map.get(rgb, :a, 1.0), mode: :rgb)
  end

  def new(%{l_: l, a_: a, b_: b} = lab, mode) when mode in [:lab, :oklab] do
    new(l, a, b, alpha: Map.get(lab, :a, 1.0), mode: mode)
  end

  def new(%{l: l, c: c, h: h} = lch, mode) when mode in [:oklch, :lch] do
    new(l, c, h, alpha: Map.get(lch, :a, 1.0), mode: mode)
  end

  def new(%{l: l, c: c, h: h} = hcl, :hcl) do
    new(h, c, l, alpha: Map.get(hcl, :a, 1.0), mode: :hcl)
  end

  def new(%{v: v, s: s, h: h} = hsv, :hsv) do
    new(h, s, v, alpha: Map.get(hsv, :a, 1.0), mode: :hsv)
  end

  def new(%{l: l, s: s, h: h} = hsl, :hsl) do
    new(h, s, l, alpha: Map.get(hsl, :a, 1.0), mode: :hsl)
  end

  def new(%{l_: l, a_: a, b_: b} = lab, mode, opts)
  when mode in [:lab, :oklab] and is_list(opts) do
    new(l, a, b, Keyword.merge(opts, alpha: Map.get(lab, :a, 1.0), mode: mode))
  end

  def new(p1, p2, p3, options \\ [])

  def new(p1, p2, p3, options) when is_list(options) do
    {mode, options} = Keyword.pop(options, :mode, :rgb)
    {a, options} = Keyword.pop(options, :alpha, 1.0)
    new(p1, p2, p3, a, mode, options)
  end

  def new(p1, p2, p3, mode) when is_atom(mode), do: new(p1, p2, p3, mode: mode)
  def new(p1, p2, p3, a) when is_normalized(a), do: new(p1, p2, p3, alpha: a)
  def new(_, _, _, _), do: {:error, :invalid}

  def new(p1, p2, p3, a, mode) when is_atom(mode) and is_normalized(a) do
    new(p1, p2, p3, mode: mode, alpha: a)
  end

  def new(_, _, _, _, _), do: {:error, :invalid}

  def new(r, g, b, a, :rgb, _options)
  when is_normalized(a) and is_byte(r) and is_byte(g) and is_byte(b) do
    {:ok, struct(@me, r: r, g: g, b: b, a: a)}
  end

  def new(h, s, l, a, :hsl, _options) do
    case HSL.new(h, s, l, a) do
      {:ok, hsl} -> HSL.to_rgb(hsl)
      error -> error
    end
  end

  def new(h, s, v, a, :hsv, _options) do
    case HSV.new(h, s, v, a) do
      {:ok, hsv} -> HSV.to_rgb(hsv)
      error -> error
    end
  end

  def new(l, a_star, b_star, a, :lab, options) when is_list(options) do
    {:ok, lab} = Lab.new(l, a_star, b_star, a)
    Lab.to_rgb(lab, options)
  end

  def new(l, a_star, b_star, a, :oklab, options) when is_list(options) do
    {:ok, lab} = OKLab.new(l, a_star, b_star, a)
    OKLab.to_rgb(lab, options)
  end

  def new(l, c, h, a, :lch, options) when is_list(options) do
    {:ok, lch} = LCH.new(l, c, h, a)
    LCH.to_rgb(lch, options)
  end

  def new(l, c, h, a, :oklch, options) when is_list(options) do
    {:ok, oklch} = OKLCH.new(l, c, h, a)
    OKLCH.to_rgb(oklch, options)
  end

  def new(h, c, l, a, :hcl, options) when is_list(options) do
    new(l, c, h, a, :lch, options)
  end

  def new(_, _, _, _, _, _), do: {:error, :invalid}

  defp parse_hex_list(arg_list) when is_list(arg_list) do
    Enum.reduce_while(arg_list, [], fn {key, hex}, acc ->
      case Integer.parse(hex, 16) do
        {value, ""} when is_byte(value) ->
          {:cont, [{key, value} | acc]}
        _ ->
          {:halt, {:error, "#{key} value must be a hex value between 0 and ff, got: #{hex}"}}
      end
    end)
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
      iex> Ultraviolet.new(66.28, 61.45, -8.62, 1.0, :lab, reference: :f2)
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180}}
      iex> Ultraviolet.new(%{l_: 66.28, a_: 61.45, b_: -8.62}, :lab, reference: :f2)
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180}}
      iex> Ultraviolet.new(65.49, 64.24, -10.65, 1.0, :lab)
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
  """
  def into(color, mode, options \\ [])

  def into(%Color{} = color, rgb, _options) when rgb in [:rgb, :lrgb] do
    {:ok, color}
  end
  def into(%Color{} = color, :hsl, _options), do: HSL.from_rgb(color)
  def into(%Color{} = color, :hsv, _options), do: HSV.from_rgb(color)

  def into(%Color{} = color, :lab, options) when is_list(options) do
    Lab.from_rgb(color, options)
  end

  def into(%Color{} = color, :oklab, options) when is_list(options) do
    OKLab.from_rgb(color, options)
  end

  def into(%Color{} = color, lch_or_hcl, options)
  when is_list(options) and lch_or_hcl in [:hcl, :lch] do
    LCH.from_rgb(color, options)
  end

  def into(%Color{} = color, :oklch, options) when is_list(options) do
    OKLCH.from_rgb(color, options)
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

  @doc"""
  Get or set the color opacity.

  ## Examples

    iex> {:ok, color} = Color.new("red");
    iex> color = Color.alpha(color, 0.5)
    %Color{r: 255, g: 0, b: 0, a: 0.5}
    iex> Color.alpha(color)
    0.5
  """
  # this works because all Color structs use `:a` for opacity
  def alpha(%{a: a} = color) when is_struct(color), do: a
  def alpha(color, alpha) when is_struct(color) and is_normalized(alpha) do
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
  def shade!(color, ratio \\ 0.5, mode \\ :lrgb) do
    color
    |> mix(%Color{r: 0, g: 0, b: 0}, ratio, mode)
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
  def tint!(color, ratio \\ 0.5, mode \\ :lrgb) do
    color
    |> mix(%Color{r: 255, g: 255, b: 255}, ratio, mode)
    |> ok!()
  end
  @doc """
  Mixes two colors. The mix `weight` is a value between 0 and 1.

  See `Ultraviolet.mix/4` for documentation and examples.
  """
  def mix(color, target, weight \\ 0.5, mode \\ :lrgb)

  def mix(_color, _target, w, _mode) when not is_normalized(w) do
    {:error, "expected a ratio between 0 and 1, got: #{w}"}
  end

  def mix(color, target, w, mode) do
    average(color, [target], mode, [1 - w, w])
  end

  @doc """
  Mixes several colors. If `weights` are given, a weighted average is
  calculated; the number of `weights` must equal the number of colors.

  See `Ultraviolet.average/4` for documentation and examples.
  """
  def average(color, targets, mode \\ :lrgb, weights \\ nil)

  def average(color, targets, mode, nil) do
    average(color, targets, mode, Enum.map([color | targets], fn _ -> 1 end))
  end

  def average(color, targets, mode, weights) do
    case validate_all([color | targets], &into(&1, mode)) do
      {:ok, color_list} ->
        color_list
        |> Enum.map(&Map.from_struct/1)
        |> Enum.zip_with(& &1)
        |> Enum.map(&weighted_average(&1, normalize(weights), mode))
        |> List.flatten()
        |> Enum.reduce(%{}, fn {k, v}, m ->
          Map.update(m, k, v, &tuple_sum(&1, v))
        end)
        |> Enum.map(&consolidate(&1, mode))
        |> Enum.into(%{})
        |> new(mode)

      error ->
        error
    end
  end

  defp normalize(values) do
    values
    |> Enum.sum()
    |> then(&Enum.map(values, fn v -> v / &1 end))
  end

  defp weighted_average(components, weights, mode) do
    components
    |> Enum.zip(weights)
    |> Enum.map(&channel_with_weight(&1, mode))
  end

  # alpha channel is always a simple weighted average
  defp channel_with_weight({{:a, value}, weight}, _mode) do
    {:a, weight * value}
  end

  defp channel_with_weight({{channel, value}, weight}, :lrgb) do
    {channel, weight * value * value}
  end

  # since hues are angles, we need to use a different weighted average
  defp channel_with_weight({{:h, degrees}, weight}, _mode) do
    radians = degrees * :math.pi() / 180
    {:h, {:math.cos(radians) * weight, :math.sin(radians) * weight}}
  end

  defp channel_with_weight({{channel, value}, weight}, _mode) do
    {channel, weight * value}
  end

  # required because sometimes the weighted average returns a tuple
  # the tuple will be resolved during `consolidate/2`
  defp tuple_sum({v1, w1}, {v2, w2}), do: {v1 + v2, w1 + w2}
  defp tuple_sum(v1, v2), do: v1 + v2

  # the final step...
  # alpha channel is always a simple weighted average
  defp consolidate({:a, v}, _mode), do: {:a, v}
  defp consolidate({k, v}, :lrgb), do: {k, clamp_to_byte(:math.sqrt(v))}
  defp consolidate({k, v}, :rgb), do: {k, clamp_to_byte(v)}

  defp consolidate({:h, {cos, sin}}, _mode) do
    {:h, maybe_correct_hue(:math.atan2(sin, cos) * 180 / :math.pi())}
  end

  defp consolidate({k, v}, _mode), do: {k, v}

  defp maybe_correct_hue(h) when h < 0, do: maybe_correct_hue(h + 360)
  defp maybe_correct_hue(h) when h > 360, do: maybe_correct_hue(h - 360)
  defp maybe_correct_hue(h), do: h

  defp clamp_to_byte(n), do: min(max(n, 0), 255)

  @doc"""
  Blends two colors using RGB channel-wise blend functions. See
  `Ultraviolet.blend/3` for examples and valid blend modes.
  """
  def blend(color, mask, mode \\ :normal)

  def blend(%Color{} = color, %Color{} = mask, mode) do
    [color, mask]
    |> Enum.map(&[&1.r, &1.g, &1.b])
    |> Enum.zip()
    |> Enum.map(&do_blend(&1, mode))
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
    (2 * color * mask) / 255
  end

  defp do_blend({color, mask}, :overlay) do
    255 * (1 - 2 * (1 - color / 255) * (1 - mask / 255))
  end

  defp do_blend({color, mask}, :burn) do
    255 * (1 - (1 - mask / 255) / (color / 255))
  end

  defp do_blend({255, _mask}, :dodge), do: 255

  defp do_blend({color, mask}, :dodge) do
    case (255 * (mask / 255)) / (1 - color / 255) do
      a when a <= 255 -> a
      _ -> 255
    end
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
  def hex(%Color{r: r, g: g, b: b, a: 1.0}) do
    [r, g, b]
    |> Enum.map(&to_hex/1)
    |> Enum.join()
    |> then(&String.downcase("##{&1}"))
  end

  def hex(%Color{r: r, g: g, b: b, a: a}) do
    [r, g, b, a*255]
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
