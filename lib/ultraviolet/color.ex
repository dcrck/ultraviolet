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

  def new(%Color{} = c), do: {:ok, c}

  def new(_), do: {:error, :invalid}

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
    {:ok, struct(@me, r: r, g: g, b: b)}
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

  """
  def into(color, mode, options \\ [])

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
  Mixes two colors. the mix `weight` is a value between 0 and 1
  """
  def mix(color1, color2, weight \\ 0.5, mode \\ :lrgb)

  def mix(color2, color2, w, _mode) when not is_normalized(w) do
    {:error, "expected a ratio between 0 and 1, got: #{w}"}
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :lrgb) do
    [col1, col2]
    # extract components from each
    |> Enum.map(&[&1.r, &1.g, &1.b])
    # pair channels
    |> Enum.zip()
    # mix each channel
    |> Enum.map(fn {c1, c2} -> :math.sqrt(c1 * c1 * (1 - w) + c2 * c2 * w) end)
    # create a new color from the mixed channels
    |> then(fn [r, g, b] -> new(r, g, b, weighted_mix(col1.a, col2.a, w)) end)
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :rgb) do
    [col1, col2]
    # extract components from each
    |> Enum.map(&[&1.r, &1.g, &1.b, &1.a])
    # pair channels
    |> Enum.zip()
    # mix each channel
    |> Enum.map(fn {c1, c2} -> weighted_mix(c1, c2, w) end)
    # create a new color from the mixed channels
    |> then(fn [r, g, b, a] -> new(r, g, b, a) end)
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :hsl) do
    {:ok, hsl1} = into(col1, :hsl)
    {:ok, hsl2} = into(col2, :hsl)

    new(
      maybe_correct_hue(hsl1.h + w * hue_difference(hsl1.h, hsl2.h)),
      weighted_mix(hsl1.s, hsl2.s, w),
      weighted_mix(hsl1.l, hsl2.l, w),
      weighted_mix(hsl1.a, hsl2.a, w),
      :hsl
    )
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :hsv) do
    {:ok, hsv1} = into(col1, :hsv)
    {:ok, hsv2} = into(col2, :hsv)

    new(
      maybe_correct_hue(hsv1.h + w * hue_difference(hsv1.h, hsv2.h)),
      weighted_mix(hsv1.s, hsv2.s, w),
      weighted_mix(hsv1.v, hsv2.v, w),
      weighted_mix(hsv1.a, hsv2.a, w),
      :hcl
    )
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :lab) do
    {:ok, lab1} = into(col1, :lab)
    {:ok, lab2} = into(col2, :lab)

    [lab1, lab2]
    # extract components from each
    |> Enum.map(&[&1.l_, &1.a_, &1.b_, &1.a])
    # pair channels
    |> Enum.zip()
    # mix each channel
    |> Enum.map(fn {c1, c2} -> weighted_mix(c1, c2, w) end)
    # create a new color from the mixed channels
    |> then(fn [l, a, b, alpha] -> new(l, a, b, alpha, :lab) end)
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :oklab) do
    {:ok, lab1} = into(col1, :oklab)
    {:ok, lab2} = into(col2, :oklab)

    [lab1, lab2]
    # extract components from each
    |> Enum.map(&[&1.l_, &1.a_, &1.b_, &1.a])
    # pair channels
    |> Enum.zip()
    # mix each channel
    |> Enum.map(fn {c1, c2} -> weighted_mix(c1, c2, w) end)
    # create a new color from the mixed channels
    |> then(fn [l, a, b, alpha] -> new(l, a, b, alpha, :oklab) end)
  end

  def mix(%Color{} = c1, %Color{} = c2, w, :lch), do: mix(c1, c2, w, :hcl)

  def mix(%Color{} = col1, %Color{} = col2, w, :hcl) do
    {:ok, hcl1} = into(col1, :hcl)
    {:ok, hcl2} = into(col2, :hcl)

    new(
      maybe_correct_hue(hcl1.h + w * hue_difference(hcl1.h, hcl2.h)),
      weighted_mix(hcl1.c, hcl2.c, w),
      weighted_mix(hcl1.l, hcl2.l, w),
      weighted_mix(hcl1.a, hcl2.a, w),
      :hcl
    )
  end

  def mix(%Color{} = col1, %Color{} = col2, w, :oklch) do
    {:ok, oklch1} = into(col1, :oklch)
    {:ok, oklch2} = into(col2, :oklch)

    new(
      weighted_mix(oklch1.l, oklch2.l, w),
      weighted_mix(oklch1.c, oklch2.c, w),
      maybe_correct_hue(oklch1.h + w * hue_difference(oklch1.h, oklch2.h)),
      weighted_mix(oklch1.a, oklch2.a, w),
      :oklch
    )
  end

  def mix(color1, color2, w, mode) do
    case {new(color1), new(color2)} do
      {{:ok, c1}, {:ok, c2}} -> mix(c1, c2, w, mode)
      {{:ok, _c1}, _} -> {:error, "#{color2} is not a valid color"}
      {_, {:ok, _c2}} -> {:error, "#{color1} is not a valid color"}
      _ -> {:error, "#{color1} and #{color2} are not valid colors"}
    end
  end

  defp weighted_mix(v1, v2, w), do: v1 + w * (v2 - v1)

  defp hue_difference(hue1, hue2) when hue2 > hue1 and hue2 - hue1 > 180 do
    hue2 - (hue1 + 360)
  end

  defp hue_difference(hue1, hue2) when hue2 < hue1 and hue1 - hue2 > 180 do
    hue2 + 360 - hue1
  end

  defp hue_difference(hue1, hue2), do: hue2 - hue1

  defp maybe_correct_hue(h) when h < 0, do: maybe_correct_hue(h + 360)
  defp maybe_correct_hue(h) when h > 360, do: maybe_correct_hue(h - 360)
  defp maybe_correct_hue(h), do: h

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

  # shorthand to deconstruct {:ok, result} structs
  defp ok!({:ok, result}), do: result
  defp ok!(other) do
    raise "expected a structure like {:ok, result}, got: #{inspect(other)}"
  end
end

defimpl String.Chars, for: Ultraviolet.Color do
  def to_string(color), do: Ultraviolet.Color.hex(color)
end
