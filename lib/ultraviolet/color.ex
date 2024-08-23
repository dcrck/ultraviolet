defmodule Ultraviolet.Color do
  @moduledoc """
  functions related to parsing and generating Color structs for use elsewhere
  in Ultraviolet.

  ## Color Spaces

  Colors, by default, are stored in RGBA representation, but supports other
  color spaces as input to `new/4` and `new/5`, where the last parameter is the
  color space to translate from.

  ### Available Spaces

  - RGB (the default): `:rgb`
  - HSL: `:hsl`

  """
  import Bitwise, only: [bsr: 2, band: 2]

  alias Ultraviolet.Color.HSL
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
      iex>Ultraviolet.Color.new(330, 0.0, 1, :hsl)
      {:ok, %Ultraviolet.Color{r: 255, g: 255, b: 255, a: 1.0}}

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

  # RGB values
  def new(r, g, b), do: new(r, g, b, :rgb)

  def new(r, g, b, :rgb) when is_byte(r) and is_byte(g) and is_byte(b) do
    {:ok, struct(@me, r: r, g: g, b: b)}
  end

  def new(h, s, l, :hsl) do
    case HSL.new(h, s, l) do
      {:ok, hsl} -> HSL.to_rgb(hsl)
      error -> error
    end
  end

  def new(r, g, b, a) when is_normalized(a) and is_byte(r) and is_byte(g) and is_byte(b) do
    {:ok, struct(@me, r: r, g: g, b: b, a: a)}
  end

  def new(_, _, _, _), do: {:error, :invalid}

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

      iex>{:ok, color} = Ultraviolet.Color.new("#ff3399")
      {:ok, %Ultraviolet.Color{r: 255, g: 51, b: 153, a: 1.0}}
      iex> Ultraviolet.Color.into(color, :hsl)
      {:ok, %Ultraviolet.Color.HSL{h: 330, s: 1.0, l: 0.6, a: 1.0}}
  """
  def into(%Color{} = color, :hsl), do: HSL.from_rgb(color)

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
