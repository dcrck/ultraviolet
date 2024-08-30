defmodule Ultraviolet.Color.XYZ do
  @moduledoc false
  # this module is only used for internal translations between other color
  # spaces, and should not be used on its own

  alias Ultraviolet.Color
  alias Ultraviolet.M3x3
  alias Decimal, as: D
  alias __MODULE__

  defstruct [:x, :y, :z]

  # taken from https://www.mathworks.com/help/images/ref/whitepoint.html
  @illuminants %{
    # STM E308-01
    a: {D.new("1.0985"), D.new("0.35585")},
    # Wyszecki & Stiles, p. 769
    b: {D.new("1.0985"), D.new("0.35585")},
    # C (ASTM E308-01)
    c: {D.new("0.98074"), D.new("1.18232")},
    # D50 (ASTM E308-01)
    d50: {D.new("0.96422"), D.new("0.82521")},
    # D55 (ASTM E308-01)
    d55: {D.new("0.95682"), D.new("0.92419")},
    # D65 (ASTM E308-01)
    d65: {D.new("0.95047"), D.new("1.08883")},
    # E (ASTM E308-01)
    e: {D.new("1.0"), D.new("1.0")},
    # F2 (ASTM E308-01)
    f2: {D.new("0.99186"), D.new("0.67393")},
    # F7 (ASTM E308-01)
    f7: {D.new("0.95041"), D.new("1.08747")},
    # F11 (ASTM E308-01)
    f11: {D.new("1.00962"), D.new("0.6435")},
    # default white reference illuminant
    icc: {D.new("0.96422"), D.new("0.82521")}
  }

  # conversion matrices
  @rgb2xyz M3x3.new([
             ["0.4124564390896922", "0.21267285140562253", "0.0193338955823293"],
             ["0.357576077643909", "0.715152155287818", "0.11919202588130297"],
             ["0.18043748326639894", "0.07217499330655958", "0.9503040785363679"]
           ])

  @xyz2rgb M3x3.new([
             ["3.2404541621141045", "-0.9692660305051868", "0.055643430959114726"],
             ["-1.5371385127977166", "1.8760108454466942", "-0.2040259135167538"],
             ["-0.498531409556016", "0.041556017530349834", "1.0572251882231791"]
           ])

  # other universal matrices
  @adapt_ma M3x3.new([
              ["0.8951", "-0.7502", "0.0389"],
              ["0.2664", "1.7135", "-0.0685"],
              ["-0.1614", "0.0367", "1.0296"]
            ])

  @adapt_ma_i M3x3.new([
                ["0.9869929054667123", "0.43230526972339456", "-0.008528664575177328"],
                ["-0.14705425642099013", "0.5183602715367776", "0.04004282165408487"],
                ["0.15996265166373125", "0.0492912282128556", "0.9684866957875502"]
              ])

  # used in rgb2xyz
  @abc [D.new("0.9414285350000001"), D.new("1.040417467"), D.new("1.089532651")]

  # sRGB x, y, z points
  @white [D.new("0.95047"), D.new("1.0"), D.new("1.08883")]

  def new(x, y, z) do
    {:ok, struct(XYZ, x: x, y: y, z: z)}
  end

  def new([x, y, z]), do: new(x, y, z)

  @doc """
  the XYZ color space representation of the given white reference illuminant
  """
  def whitepoint(reference) do
    case Map.fetch(@illuminants, reference) do
      # for now, y is always 1
      {:ok, {x, z}} -> {:ok, {x, D.new(1), z}}
      :error -> {:error, "undefined reference point"}
    end
  end

  @doc """
  Translates a sRGB color into XYZ space. `reference` is the desired
  white reference illuminant (default: `:d65`).
  """
  def from_rgb(%Color{} = color, reference \\ :d65) do
    case whitepoint(reference) do
      {:ok, {x_n, y_n, z_n}} -> rgb_to_xyz(color, [x_n, y_n, z_n])
      error -> error
    end
  end

  defp rgb_to_xyz(color, reference_point) do
    [color.r, color.g, color.b]
    # normalize and gamma adjust
    |> Enum.map(&gamma_adjust(D.div(D.new(to_string(&1)), 255)))
    # convert to xyz (stage 1)
    |> M3x3.mult(@rgb2xyz)
    # apply adaption matrix
    |> M3x3.mult(@adapt_ma)
    # account for reference point
    |> then(&[&1, M3x3.mult(reference_point, @adapt_ma), @abc])
    |> Enum.zip()
    |> Enum.map(fn {i, d, s} -> D.mult(i, D.div(d, s)) end)
    # apply second adaption matrix
    |> M3x3.mult(@adapt_ma_i)
    # put in struct
    |> new()
  end

  defp gamma_adjust(channel) do
    sign = channel.sign
    channel = D.abs(channel)

    linear =
      cond do
        D.gt?(channel, "0.04045") ->
          channel
          |> D.add("0.055")
          |> D.div("1.055")
          |> D.to_float()
          |> Float.pow(2.4)

        true ->
          channel
          |> D.div("12.92")
          |> D.to_float()
      end

    D.new(to_string(sign * linear))
  end

  @doc """
  Converts from XYZ to [r, g, b] array; `reference` is the desired white
  reference illuminant (default: `:d65`)
  """
  def to_rgb(%XYZ{} = xyz, reference \\ :d65) do
    case whitepoint(reference) do
      {:ok, {x_n, y_n, z_n}} -> xyz_to_rgb(xyz, [x_n, y_n, z_n])
      error -> error
    end
  end

  defp xyz_to_rgb(xyz, reference_point) do
    [xyz.x, xyz.y, xyz.z]
    # apply first adaption matrix
    |> M3x3.mult(@adapt_ma)
    # account for rerence point
    |> then(&[&1, M3x3.mult(reference_point, @adapt_ma), M3x3.mult(@white, @adapt_ma)])
    |> Enum.zip()
    |> Enum.map(fn {i, s, d} -> D.mult(i, D.div(d, s)) end)
    # apply second adaption matrix
    |> M3x3.mult(@adapt_ma_i)
    # convert to rgb
    |> M3x3.mult(@xyz2rgb)
    # apply companding
    |> Enum.map(&compand/1)
  end

  defp compand(linear) do
    sign = linear.sign
    linear = D.abs(linear)

    cond do
      D.gt?(linear, "0.0031308") ->
        sign * (1.055 * Float.pow(D.to_float(linear), 1.0 / 2.4) - 0.055)

      true ->
        sign * (linear |> D.mult("12.92") |> D.to_float())
    end
  end
end
