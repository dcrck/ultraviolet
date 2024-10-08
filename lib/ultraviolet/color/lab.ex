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
  - `:d65`: Represents average daylight at 6500K (*default*)
  - `:a`: Represents the color temperature of a typical incandescent light bulb at approximately 2856K.
  - `:b`: Represents noon daylight with a color temperature of approximately 4874K.
  - `:c`: Represents average or north sky daylight; it's a theoretical construct, not often used in practical applications.
  - `:f2`: Represents cool white fluorescent light.
  - `:f7`: This is a broad-band fluorescent light source with a color temperature of approximately 6500K.
  - `:f11`: This is a narrow tri-band fluorescent light source with a color temperature of approximately 4000K.
  - `:e`: Represents an equal energy white point, where all wavelengths in the visible spectrum are equally represented.
  - `:icc`

  """
  defstruct l_: 0, a_: 0, b_: 0, a: 1.0

  @typedoc """
  Defines the channels in a Lab color.
  """
  @type t :: %{l_: number(), a_: number(), b_: number(), a: number()}
  @type white_point :: :d50 | :d55 | :d65 | :a | :b | :c | :f2 | :f7 | :f11 | :e | :icc

  alias Decimal, as: D
  alias Ultraviolet.Color
  alias Ultraviolet.Color.XYZ
  alias __MODULE__

  import Ultraviolet.Helpers,
    only: [is_unit_interval: 1, maybe_round: 2, clamp_to_byte: 1]

  @me __MODULE__

  @constants %{
    "Kn" => D.new("18"),
    "kE" => D.div(D.new("216"), D.new("24389")),
    "kKE" => D.new("8"),
    "kK" => D.div(D.new("24389"), D.new("27"))
  }

  @doc """
  Generates a new CIE Lab color.

      iex>Ultraviolet.Color.Lab.new({65.49, 64.24, -10.65})
      {:ok, %Ultraviolet.Color.Lab{l_: 65.49, a_: 64.24, b_: -10.65}}

  """
  @spec new(tuple() | [number()] | map() | [...]) :: {:ok, t()}
  def new({l, a, b}), do: new(l, a, b, 1.0)
  def new({l, a, b, a_}), do: new(l, a, b, a_)
  def new([l, a, b]) when is_number(l), do: new(l, a, b, 1.0)
  def new([l, a, b, a_]) when is_number(l), do: new(l, a, b, a_)

  # map of channel values
  def new(channels) when is_map(channels) do
    new([
      Map.get(channels, :l_),
      Map.get(channels, :a_),
      Map.get(channels, :b_),
      Map.get(channels, :a, 1.0)
    ])
  end

  # keyword list of channel values
  def new([{k, _} | _rest] = channels) when is_list(channels) and is_atom(k) do
    new(Enum.into(channels, %{}))
  end

  @doc """
  Generates a new CIE Lab color.

      iex>Ultraviolet.Color.Lab.new(65.49, 64.24, -10.65)
      {:ok, %Ultraviolet.Color.Lab{l_: 65.49, a_: 64.24, b_: -10.65}}

  """
  @spec new(number(), number(), number()) :: {:ok, t()}
  def new(l, a, b), do: new(l, a, b, 1.0)

  @doc """
  Generates a new CIE Lab color.

      iex>Ultraviolet.Color.Lab.new(65.49, 64.24, -10.65, 0.5)
      {:ok, %Ultraviolet.Color.Lab{l_: 65.49, a_: 64.24, b_: -10.65, a: 0.5}}

  """
  @spec new(number(), number(), number(), number()) :: {:ok, t()}
  def new(l, a, b, a_) when is_unit_interval(a_) do
    {:ok, struct(@me, l_: l, a_: a, b_: b, a: a_)}
  end

  @doc """
  Converts from CIE Lab to sRGB

  ## Options

  - `:reference`: the CIE Lab [white reference point](`t:white_point/0`). Default: `:d65`
  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`
  """
  @spec to_rgb(t()) :: {:ok, Color.t()}
  @spec to_rgb(t(), [...]) :: {:ok, Color.t()}
  def to_rgb(%Lab{} = lab, options \\ []) when is_list(options) do
    reference = Keyword.get(options, :reference, :d65)
    round = Keyword.get(options, :round, 0)

    case XYZ.whitepoint(reference) do
      {:ok, whitepoint} ->
        lab
        |> lab_to_xyz(Tuple.to_list(whitepoint))
        |> then(fn {:ok, xyz} -> XYZ.to_rgb(xyz, reference) end)
        |> Enum.map(&(&1 * 255))
        |> Enum.map(&clamp_to_byte/1)
        |> Enum.map(&maybe_round(&1, round))
        |> then(&Color.new(&1 ++ [lab.a]))

      error ->
        error
    end
  end

  @doc """
  Converts from an RGB Color struct to a Lab struct.

  ## Options

    - `:reference`: the CIE Lab white reference point. Default: `:d65`
    - `:round`: an integer if rounding L, a*, and b* channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `2`
  """
  @spec from_rgb(Color.t()) :: {:ok, t()}
  @spec from_rgb(Color.t(), [...]) :: {:ok, t()}
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    reference = Keyword.get(options, :reference, :d65)
    round = Keyword.get(options, :round, 2)
    {:ok, xyz} = XYZ.from_rgb(color, reference)
    {:ok, whitepoint} = XYZ.whitepoint(reference)

    xyz
    |> xyz_to_lab(Tuple.to_list(whitepoint))
    |> Enum.map(&maybe_round(&1, round))
    |> then(&new(&1 ++ [color.a]))
  end

  defp lab_to_xyz(%Lab{} = lab, [x, y, z]) do
    l = D.new(to_string(lab.l_))
    a = D.new(to_string(lab.a_))
    b = D.new(to_string(lab.b_))

    fy = D.div(D.add(l, D.new(16)), D.new(116))
    fx = D.add(D.mult(D.new("0.002"), a), fy)
    fz = D.sub(fy, D.mult(D.new("0.005"), b))

    fx3 = fx |> D.mult(fx) |> D.mult(fx)
    fz3 = fz |> D.mult(fz) |> D.mult(fz)

    XYZ.new(
      D.mult(xr(@constants, fx3, fx), x),
      D.mult(yr(@constants, l), y),
      D.mult(zr(@constants, fz3, fz), z)
    )
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

  defp xyz_to_lab(%XYZ{} = xyz, reference_point) do
    kK = Map.get(@constants, "kK")
    kE = Map.get(@constants, "kE")

    [xyz.x, xyz.y, xyz.z]
    |> Enum.zip(reference_point)
    |> Enum.map(fn {i, i_n} -> r_inv(D.div(i, i_n), kK, kE) end)
    |> then(fn [fx, fy, fz] ->
      [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)]
    end)
  end

  defp r_inv(r, kK, kE) do
    cond do
      D.gt?(r, kE) -> r |> D.to_float() |> Float.pow(1 / 3)
      true -> r |> D.mult(kK) |> D.add(16) |> D.div(116) |> D.to_float()
    end
  end
end
