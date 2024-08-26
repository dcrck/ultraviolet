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
  defguardp is_byte(n) when is_integer(n) and n >= 0 and n <= 255
  defguardp is_normalized(n) when (is_float(n) and n >= 0 and n <= 1) or n == 0 or n == 1

  # source of named colors
  @external_resource named_colors_path = Path.join([__DIR__, "named-colors.txt"])

  @doc"""
  The first step to get your color into Ultraviolet is to create a
  Color struct. This can be done through `new/1` or `Ultraviolet.color/1`.

  ## Examples

  This function supports a wide variety of inputs:

  ### Named colors

  All named colors as defined by the
  [W3CX11 specification](https://en.wikipedia.org/wiki/X11_color_names) are
  supported:

      iex>Ultraviolet.Color.new("hotpink")
      {:ok, %Ultraviolet.Color{r: 255, g: 105, b: 180, a: 1.0}}

  ### Hexadecimal Strings

  If there's no matching named color, check for a hexidecimal string.
  It ignores case, the `#` sign is optional, and it can recognize the
  shorter 3-letter format.

      iex>Ultraviolet.Color.new("#ff3399")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.Color.new("F39")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}


  ### Hexadecimal Numbers

  Any number between `0` and `16_777_215` will be recognized as a Color:

      iex>Ultraviolet.Color.new(0xff3399)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
  
  ### Individual R, G, B

  You can also pass RGB values individually, Each parameter must be within
  `0..255`. You can pass the numbers as individual arguments or as an array.

      iex>Ultraviolet.Color.new(0xff, 0x33, 0x99)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.Color.new(255, 51, 153)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.Color.new([255, 51, 153])
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}

  ### Other Color Spaces

  You can construct colors from different color spaces as well by passing an
  atom identifying the color space as the last argument.

  #### HSL

      iex>Ultraviolet.Color.new(330, 1, 0.6, :hsl)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.Color.new(330, 0, 1, :hsl)
      {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}

  #### HSV

      iex>Ultraviolet.Color.new(330, 0.8, 1, :hsv)
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex>Ultraviolet.Color.new(330, 0, 1, :hsv)
      {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}

  #### Lab

      iex>Ultraviolet.Color.new(40, -20, 50, :lab)
      {:ok, %Ultraviolet.Color{r: 83, g: 102, b: 0, a: 1.0}}
      iex>Ultraviolet.Color.new(50, -20, 50, :lab)
      {:ok, %Ultraviolet.Color{r: 110, g: 127, b: 21, a: 1.0}}
      iex>Ultraviolet.Color.new(80, -20, 50, :lab)
      {:ok, %Ultraviolet.Color{r: 192, g: 207, b: 102, a: 1.0}}

  #### LCH / HCL

      iex>Ultraviolet.Color.new(80, 40, 130, :lch)
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}
      iex>Ultraviolet.Color.new(130, 40, 80, :hcl)
      {:ok, %Ultraviolet.Color{r: 170, g: 210, b: 140, a: 1.0}}

  #### OKLab

      iex>Ultraviolet.Color.new(0.4, -0.2, 0.5, :oklab)
      {:ok, %Ultraviolet.Color{r: 98, g: 68, b: 0, a: 1.0}}
      iex>Ultraviolet.Color.new(0.5, -0.2, 0.5, :oklab)
      {:ok, %Ultraviolet.Color{r: 128, g: 97, b: 0, a: 1.0}}
      iex>Ultraviolet.Color.new(0.8, -0.2, 0.5, :oklab)
      {:ok, %Ultraviolet.Color{r: 217, g: 197, b: 0, a: 1.0}}

  #### OKLCH

      iex>Ultraviolet.Color.new(0.5, 0.2, 240, :oklch)
      {:ok, %Ultraviolet.Color{r: 0, g: 105, b: 199, a: 1.0}}
      iex>Ultraviolet.Color.new(0.8, 0.12, 60, :oklch)
      {:ok, %Ultraviolet.Color{r: 246, g: 171, b: 107, a: 1.0}}

  """
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

  def new(_), do: {:error, :invalid}

  def new(p1, p2, p3, options \\ [])

  def new(p1, p2, p3, options) when is_list(options) do
    {mode, options} = Keyword.pop(options, :mode, :rgb)
    {a, options} = Keyword.pop(options, :alpha, 1.0)
    new(p1, p2, p3, a, mode, options)
  end
  def new(p1, p2, p3, mode) when is_atom(mode), do: new(p1, p2, p3, mode: mode)
  def new(p1, p2, p3, a) when is_normalized(a), do: new(p1, p2, p3, alpha: a)

  def new(p1, p2, p3, a, mode) when is_atom(mode) and is_normalized(a) do
    new(p1, p2, p3, mode: mode, alpha: a)
  end

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
      {:ok, %Ultraviolet.Color.Lab{l: 65.49, a_star: 64.24, b_star: -10.65}}
      iex> Ultraviolet.Color.into(color, :lab, reference: :f2)
      {:ok, %Ultraviolet.Color.Lab{l: 66.28, a_star: 61.45, b_star: -8.62}}

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
      {:ok, %Ultraviolet.Color.OKLab{l: 0.81, a_star: -0.04, b_star: 0.17}}

  """
  def into(%Color{} = color, :hsl), do: HSL.from_rgb(color)
  def into(%Color{} = color, :hsv), do: HSV.from_rgb(color)

  def into(%Color{} = color, :lab), do: into(color, :lab, [])
  def into(%Color{} = color, :oklab), do: into(color, :oklab, [])
  def into(%Color{} = color, :hcl), do: into(color, :hcl, [])
  def into(%Color{} = color, :lch), do: into(color, :hcl, [])

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
  Converts a temperature into a color, based on the color temperature scale.

  ## Examples

      iex>Ultraviolet.Color.temperature(2000)
      {:ok, %Ultraviolet.Color{r: 255, g: 139, b: 20, a: 1.0}}
      iex>Ultraviolet.Color.temperature(3500)
      {:ok, %Ultraviolet.Color{r: 255, g: 195, b: 138, a: 1.0}}
      iex>Ultraviolet.Color.temperature(6500)
      {:ok, %Ultraviolet.Color{r: 255, g: 250, b: 254, a: 1.0}}
  """
  def temperature(kelvin), do: Temperature.to_rgb(kelvin)

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
end

defimpl String.Chars, for: Ultraviolet.Color do
  def to_string(color), do: Ultraviolet.Color.hex(color)
end
