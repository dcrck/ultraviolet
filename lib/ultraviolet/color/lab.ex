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
  alias Ultraviolet.Color
  alias __MODULE__

  @me __MODULE__

  @constants %{
    "Kn" => D.new("18"),
    "Yn" => D.new("1.0"),
    "t0" => D.new("0.137931034"), # 4 / 29
    "t1" => D.new("0.206896552"), # 6 / 29
    "t2" => D.new("0.12841855"), # 3 * t1 ^ 2
    "t3" => D.new("0.008856452"), # t1 ^ 3
    "kE" => D.div(D.new("216"), D.new("24389")),
    "kKE" => D.new("8"),
    "kK" => D.div(D.new("24389"), D.new("27")),

    "RefWhiteRGB" => %{
      # sRGB
      "x" => D.new("0.95047"),
      "y" => D.new("1.0"),
      "z" => D.new("1.08883")
    },

    "MtxRGB2XYZ" => %{
      "m00" => D.new("0.4124564390896922"),
      "m01" => D.new("0.21267285140562253"),
      "m02" => D.new("0.0193338955823293"),
      "m10" => D.new("0.357576077643909"),
      "m11" => D.new("0.715152155287818"),
      "m12" => D.new("0.11919202588130297"),
      "m20" => D.new("0.18043748326639894"),
      "m21" => D.new("0.07217499330655958"),
      "m22" => D.new("0.9503040785363679"),
    },

    "MtxXYZ2RGB" => %{
      "m00" => D.new("3.2404541621141045"),
      "m01" => D.new("-0.9692660305051868"),
      "m02" => D.new("0.055643430959114726"),
      "m10" => D.new("-1.5371385127977166"),
      "m11" => D.new("1.8760108454466942"),
      "m12" => D.new("-0.2040259135167538"),
      "m20" => D.new("-0.498531409556016"),
      "m21" => D.new("0.041556017530349834"),
      "m22" => D.new("1.0572251882231791"),
    },

    # used in Lab.rgb_to_xyz
    "As" => D.new("0.9414285350000001"),
    "Bs" => D.new("1.040417467"),
    "Cs" => D.new("1.089532651"),

    "MtxAdaptMa" => %{
      "m00" => D.new("0.8951"),
      "m01" => D.new("-0.7502"),
      "m02" => D.new("0.0389"),
      "m10" => D.new("0.2664"),
      "m11" => D.new("1.7135"),
      "m12" => D.new("-0.0685"),
      "m20" => D.new("-0.1614"),
      "m21" => D.new("0.0367"),
      "m22" => D.new("1.0296"),
    },

    "MtxAdaptMaI" => %{
      "m00" => D.new("0.9869929054667123"),
      "m01" => D.new("0.43230526972339456"),
      "m02" => D.new("-0.008528664575177328"),
      "m10" => D.new("-0.14705425642099013"),
      "m11" => D.new("0.5183602715367776"),
      "m12" => D.new("0.04004282165408487"),
      "m20" => D.new("0.15996265166373125"),
      "m21" => D.new("0.0492912282128556"),
      "m22" => D.new("0.9684866957875502"),
    }
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
  Converts from CIE Lab to an RGB Color object.
  
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
  defp maybe_round(channel, digits) when is_integer(digits) do
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

    rgb2xyz = Map.fetch!(@constants, "MtxRGB2XYZ")

    x2 =
      D.mult(r, rgb2xyz["m00"])
      |> D.add(D.mult(g, rgb2xyz["m10"]))
      |> D.add(D.mult(b, rgb2xyz["m20"]))

    y2 =
      D.mult(r, rgb2xyz["m01"])
      |> D.add(D.mult(g, rgb2xyz["m11"]))
      |> D.add(D.mult(b, rgb2xyz["m21"]))

    z2 =
      D.mult(r, rgb2xyz["m02"])
      |> D.add(D.mult(g, rgb2xyz["m12"]))
      |> D.add(D.mult(b, rgb2xyz["m22"]))

    ma = Map.fetch!(@constants, "MtxAdaptMa")
    y_n = Map.fetch!(@constants, "Yn")
    
    ad =
      D.mult(x_n, ma["m00"])
      |> D.add(D.mult(y_n, ma["m10"]))
      |> D.add(D.mult(z_n, ma["m20"]))

    bd =
      D.mult(x_n, ma["m01"])
      |> D.add(D.mult(y_n, ma["m11"]))
      |> D.add(D.mult(z_n, ma["m21"]))

    cd =
      D.mult(x_n, ma["m02"])
      |> D.add(D.mult(y_n, ma["m12"]))
      |> D.add(D.mult(z_n, ma["m22"]))

    %{"As" => as, "Bs" => bs, "Cs" => cs} =
      Map.take(@constants, ["As", "Bs", "Cs"])

    x1 =
      D.mult(x2, ma["m00"])
      |> D.add(D.mult(y2, ma["m10"]))
      |> D.add(D.mult(z2, ma["m20"]))
      |> D.mult(D.div(ad, as))

    y1 =
      D.mult(x2, ma["m01"])
      |> D.add(D.mult(y2, ma["m11"]))
      |> D.add(D.mult(z2, ma["m21"]))
      |> D.mult(D.div(bd, bs))

    z1 =
      D.mult(x2, ma["m02"])
      |> D.add(D.mult(y2, ma["m12"]))
      |> D.add(D.mult(z2, ma["m22"]))
      |> D.mult(D.div(cd, cs))

    mai = Map.fetch!(@constants, "MtxAdaptMaI")

    x =
      D.mult(x1, mai["m00"])
      |> D.add(D.mult(y1, mai["m10"]))
      |> D.add(D.mult(z1, mai["m20"]))

    y =
      D.mult(x1, mai["m01"])
      |> D.add(D.mult(y1, mai["m11"]))
      |> D.add(D.mult(z1, mai["m21"]))

    z =
      D.mult(x1, mai["m02"])
      |> D.add(D.mult(y1, mai["m12"]))
      |> D.add(D.mult(z1, mai["m22"]))

    [x, y, z]
  end

  defp xyz_to_rgb(x, y, z, {x_n, z_n}) do
    ma = Map.fetch!(@constants, "MtxAdaptMa")
    y_n = Map.fetch!(@constants, "Yn")

    # can probably be simplified with dot product at some point...
    as =
      D.mult(x_n, ma["m00"])
      |> D.add(D.mult(y_n, ma["m10"]))
      |> D.add(D.mult(z_n, ma["m20"]))

    bs =
      D.mult(x_n, ma["m01"])
      |> D.add(D.mult(y_n, ma["m11"]))
      |> D.add(D.mult(z_n, ma["m21"]))

    cs =
      D.mult(x_n, ma["m02"])
      |> D.add(D.mult(y_n, ma["m12"]))
      |> D.add(D.mult(z_n, ma["m22"]))

    white = Map.fetch!(@constants, "RefWhiteRGB")

    ad =
      D.mult(white["x"], ma["m00"])
      |> D.add(D.mult(white["y"], ma["m10"]))
      |> D.add(D.mult(white["z"], ma["m20"]))

    bd =
      D.mult(white["x"], ma["m01"])
      |> D.add(D.mult(white["y"], ma["m11"]))
      |> D.add(D.mult(white["z"], ma["m21"]))

    cd =
      D.mult(white["x"], ma["m02"])
      |> D.add(D.mult(white["y"], ma["m12"]))
      |> D.add(D.mult(white["z"], ma["m22"]))

    x1 =
      D.mult(x, ma["m00"])
      |> D.add(D.mult(y, ma["m10"]))
      |> D.add(D.mult(z, ma["m20"]))
      |> D.mult(D.div(ad, as))

    y1 =
      D.mult(x, ma["m01"])
      |> D.add(D.mult(y, ma["m11"]))
      |> D.add(D.mult(z, ma["m21"]))
      |> D.mult(D.div(bd, bs))

    z1 =
      D.mult(x, ma["m02"])
      |> D.add(D.mult(y, ma["m12"]))
      |> D.add(D.mult(z, ma["m22"]))
      |> D.mult(D.div(cd, cs))

    mai = Map.fetch!(@constants, "MtxAdaptMaI")

    x2 =
      D.mult(x1, mai["m00"])
      |> D.add(D.mult(y1, mai["m10"]))
      |> D.add(D.mult(z1, mai["m20"]))

    y2 =
      D.mult(x1, mai["m01"])
      |> D.add(D.mult(y1, mai["m11"]))
      |> D.add(D.mult(z1, mai["m21"]))

    z2 =
      D.mult(x1, mai["m02"])
      |> D.add(D.mult(y1, mai["m12"]))
      |> D.add(D.mult(z1, mai["m22"]))

    xyz2rgb = Map.fetch!(@constants, "MtxXYZ2RGB")

    r = compand(
      D.mult(x2, xyz2rgb["m00"])
      |> D.add(D.mult(y2, xyz2rgb["m10"]))
      |> D.add(D.mult(z2, xyz2rgb["m20"]))
    )
    g = compand(
      D.mult(x2, xyz2rgb["m01"])
      |> D.add(D.mult(y2, xyz2rgb["m11"]))
      |> D.add(D.mult(z2, xyz2rgb["m21"]))
    )
    b = compand(
      D.mult(x2, xyz2rgb["m02"])
      |> D.add(D.mult(y2, xyz2rgb["m12"]))
      |> D.add(D.mult(z2, xyz2rgb["m22"]))
    )

    [r, g, b]
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
