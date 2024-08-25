defmodule Ultraviolet.Color.Lab do

  @moduledoc """
  Functions for working in the CIE Lab color space.

  To calculate the lightness value of a color (`L`), the CIE Lab color space
  uses a reference white point. This reference white point defines what is
  considered to be "white" in the color space. By default Ultraviolet uses the
  D65 reference point.

  Possible reference points are:

  - `:d50`: Represents the color temperature of daylight at 5000K.
  - `:d55`: Represents mid-morning or mid-afternoon daylight at 5500K.
  - `:d65`: Represents average daylight at 6500K.
  - `:a`: Represents the color temperature of a typical incandescent light bulb at approximately 2856K.
  - `:b`: Represents noon daylight with a color temperature of approximately 4874K.
  - `:c`: Represents average or north sky daylight; it's a theoretical construct, not often used in practical applications.
  - `:f2`: Represents cool white fluorescent light.
  - `:f7`: This is a broad-band fluorescent light source with a color temperature of approximately 6500K.
  - `:f11`: This is a narrow tri-band fluorescent light source with a color temperature of approximately 4000K.
  - `:e`: Represents an equal energy white point, where all wavelengths in the visible spectrum are equally represented.
  - `:icc`

  """
  defstruct l: 0, a_star: 0, b_star: 0, a: 1.0

  alias Decimal, as: D
  alias Ultraviolet.M3x3
  alias Ultraviolet.Color
  alias __MODULE__

  @me __MODULE__

  @constants %{
    "Kn" => D.new("18"),
    "Yn" => D.new("1.0"),
    "kE" => D.div(D.new("216"), D.new("24389")),
    "kKE" => D.new("8"),
    "kK" => D.div(D.new("24389"), D.new("27")),
    # sRGB x, y, z points
    "white" => [D.new("0.95047"), D.new("1.0"), D.new("1.08883")],
    # conversion matrices
    "rgb2xyz" => M3x3.new([
      ["0.4124564390896922", "0.21267285140562253", "0.0193338955823293"],
      ["0.357576077643909", "0.715152155287818", "0.11919202588130297"],
      ["0.18043748326639894", "0.07217499330655958", "0.9503040785363679"],
    ]),
    "xyz2rgb" => M3x3.new([
      ["3.2404541621141045", "-0.9692660305051868", "0.055643430959114726"],
      ["-1.5371385127977166", "1.8760108454466942", "-0.2040259135167538"],
      ["-0.498531409556016", "0.041556017530349834", "1.0572251882231791"],
    ]),
    # used in Lab.rgb_to_xyz
    "a_s" => D.new("0.9414285350000001"),
    "b_s" => D.new("1.040417467"),
    "c_s" => D.new("1.089532651"),

    # name taken from chroma.js
    "AdaptMa" => M3x3.new([
      ["0.8951", "-0.7502", "0.0389"],
      ["0.2664", "1.7135", "-0.0685"],
      ["-0.1614", "0.0367", "1.0296"],
    ]),

    # name taken from chroma.js
    "AdaptMaI" => M3x3.new([
      ["0.9869929054667123", "0.43230526972339456", "-0.008528664575177328"],
      ["-0.14705425642099013", "0.5183602715367776", "0.04004282165408487"],
      ["0.15996265166373125", "0.0492912282128556", "0.9684866957875502"],
    ])
  }

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
    # ICC
    icc: {D.new("0.96422"), D.new("0.82521")},
  }

  defguardp is_normalized(n) when (is_float(n) and n >= 0 and n <= 1) or n == 0 or n == 1

  @doc"""
  Generates a new CIE Lab color object
  """
  def new(l, a_star, b_star), do: new(l, a_star, b_star, 1.0)

  def new(l, a_star, b_star, a) when is_normalized(a) do
    {:ok, struct(@me, l: l, a_star: a_star, b_star: b_star, a: a)}
  end

  @doc """
  Converts from CIE Lab to an RGB Color struct
  
  ## Options

    - `:reference`: the CIE Lab white reference point. Default: `:d65`
    - `:round`: an integer if rounding r, g, and b channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `0`
  """
  def to_rgb(%Lab{} = lab, options \\ []) when is_list(options) do
    reference = Keyword.get(options, :reference, :d65)
    round = Keyword.get(options, :round, 0)
    with {:ok, {x_n, z_n}} <- Map.fetch(@illuminants, reference),
         [x, y, z] <- lab_to_xyz(lab, {x_n, z_n}),
         rgb_list <- xyz_to_rgb(x, y, z, {x_n, z_n}) do
      rgb_list
      |> Enum.map(&(&1 * 255))
      |> Enum.map(&clamp_to_byte/1)
      |> Enum.map(&maybe_round(&1, round))
      |> then(fn [r, g, b] -> {:ok, %Color{r: r, g: g, b: b, a: lab.a}} end)
    else
      _error -> {:error, "invalid reference"}
    end
  end

  @doc """
  Converts from an RGB Color struct to a Lab struct.
  
  ## Options

    - `:reference`: the CIE Lab white reference point. Default: `:d65`
    - `:round`: an integer if rounding L, a*, and b* channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `2`
  """
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    reference = Keyword.get(options, :reference, :d65)
    round = Keyword.get(options, :round, 2)
    with {:ok, {x_n, z_n}} <- Map.fetch(@illuminants, reference),
         [x, y, z] <- rgb_to_xyz(color, {x_n, z_n}),
         lab <- xyz_to_lab(x, y, z, {x_n, z_n}) do
      lab
      |> Enum.map(&maybe_round(&1, round))
      |> then(fn [l, a, b] -> {:ok, %Lab{l: l, a_star: a, b_star: b, a: color.a}} end)
    end
  end

  defp maybe_round(channel, 0), do: round(channel)
  defp maybe_round(channel, digits) when is_integer(digits) and is_float(channel) do
    Float.round(channel, digits)
  end

  defp maybe_round(channel, _), do: channel

  defp clamp_to_byte(n), do: min(max(n, 0), 255)

  defp lab_to_xyz(%Lab{} = lab, {x_n, z_n}) do
    constants = Map.take(@constants, ["kE", "kK", "kKE", "Yn"])
    l = D.new(to_string(lab.l))
    a = D.new(to_string(lab.a_star))
    b = D.new(to_string(lab.b_star))

    fy = D.div(D.add(l, D.new(16)), D.new(116))
    fx = D.add(D.mult(D.new("0.002"), a), fy)
    fz = D.sub(fy, D.mult(D.new("0.005"), b))

    fx3 = fx |> D.mult(fx) |> D.mult(fx)
    fz3 = fz |> D.mult(fz) |> D.mult(fz)

    [
      D.mult(xr(constants, fx3, fx), x_n),
      D.mult(yr(constants, l), Map.fetch!(constants, "Yn")),
      D.mult(zr(constants, fz3, fz), z_n)
    ]
  end

  defp xr(%{"kE" => kE, "kK" => kK}, fx3, fx) do
    cond do
      D.gt?(fx3, kE) -> fx3
      true -> fx |> D.mult(116) |> D.sub(16) |> D.div(kK)
    end
  end

  defp yr(%{"kKE" => kKE, "kK" => kK}, l) do
    cond do
      D.gt?(l, kKE) ->
        term = l |> D.add(16) |> D.div(116)
        term |> D.mult(term) |> D.mult(term)
      true ->
        D.div(l, kK)
    end
  end

  defp zr(%{"kE" => kE, "kK" => kK}, fz3, fz) do
    cond do
      D.gt?(fz3, kE) -> fz3
      true -> fz |> D.mult(116) |> D.sub(16) |> D.div(kK)
    end
  end

  defp rgb_to_xyz(%Color{} = color, {x_n, z_n}) do
    # normalize and gamma adjust
    r = gamma_adjust(D.div(D.new(color.r), 255))
    g = gamma_adjust(D.div(D.new(color.g), 255))
    b = gamma_adjust(D.div(D.new(color.b), 255))

    [x2, y2, z2] = M3x3.mult(Map.fetch!(@constants, "rgb2xyz"), [r, g, b])

    ma = Map.fetch!(@constants, "AdaptMa")
    y_n = Map.fetch!(@constants, "Yn")

    [a_d, b_d, c_d] = M3x3.mult(ma, [x_n, y_n, z_n])
    
    %{"a_s" => a_s, "b_s" => b_s, "c_s" => c_s} =
      Map.take(@constants, ["a_s", "b_s", "c_s"])

    [x1, y1, z1] = M3x3.mult(ma, [x2, y2, z2]) 

    M3x3.mult(
      Map.fetch!(@constants, "AdaptMaI"),
      [
        D.mult(x1, D.div(a_d, a_s)),
        D.mult(y1, D.div(b_d, b_s)),
        D.mult(z1, D.div(c_d, c_s))
      ]
    )
  end

  defp xyz_to_rgb(x, y, z, {x_n, z_n}) do
    ma = Map.fetch!(@constants, "AdaptMa")
    y_n = Map.fetch!(@constants, "Yn")

    [a_s, b_s, c_s] = M3x3.mult(ma, [x_n, y_n, z_n]) 
    [a_d, b_d, c_d] = M3x3.mult(ma, Map.fetch!(@constants, "white"))
    [x1, y1, z1] = M3x3.mult(ma, [x, y, z])
    [x2, y2, z2] = M3x3.mult(
      Map.fetch!(@constants, "AdaptMaI"),
      [
        D.mult(x1, D.div(a_d, a_s)),
        D.mult(y1, D.div(b_d, b_s)),
        D.mult(z1, D.div(c_d, c_s)),
      ]
    )
    Enum.map(
      M3x3.mult(Map.fetch!(@constants, "xyz2rgb"), [x2, y2, z2]),
      &compand/1
    )
  end

  defp xyz_to_lab(x, y, z, {x_n, z_n}) do
    %{"kK" => kK, "kE" => kE, "Yn" => y_n} = Map.take(@constants, ["kK", "kE", "Yn"])
    xr = D.div(x, x_n)
    yr = D.div(y, y_n)
    zr = D.div(z, z_n)

    fx = r_inv(xr, kK, kE)
    fy = r_inv(yr, kK, kE)
    fz = r_inv(zr, kK, kE)

    [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)]
  end

  defp r_inv(r, kK, kE) do
    cond do
      D.gt?(r, kE) -> r |> D.to_float() |> Float.pow(1/3)
      true -> r |> D.mult(kK) |> D.add(16) |> D.div(116) |> D.to_float()
    end
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

  defp gamma_adjust(channel) do
    sign = channel.sign
    channel = D.abs(channel)
    linear = cond do
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
end
