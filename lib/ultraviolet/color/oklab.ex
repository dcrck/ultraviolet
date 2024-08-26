defmodule Ultraviolet.Color.OKLab do
  @moduledoc """
  Functions for working with the
  [OKLab](https://bottosson.github.io/posts/oklab/) color space.

  Uses the `:d65` reference illuminant.
  """
  defstruct l: 0, a_star: 0, b_star: 0, a: 1.0

  alias Decimal, as: D

  alias Ultraviolet.M3x3
  alias Ultraviolet.Color
  alias Ultraviolet.Color.XYZ
  alias __MODULE__

  @xyz2lms M3x3.new([
    [D.new("0.819022437996703"), D.new("0.3619062600528904"), D.new("-0.1288737815209879")],
    [D.new("0.0329836539323885"), D.new("0.9292868615863434"), D.new("0.0361446663506424")],
    [D.new("0.0481771893596242"), D.new("0.2642395317527308"), D.new("0.6335478284694309")]
  ])

  @lms2oklab M3x3.new([
    [D.new("0.210454268309314"), D.new("0.7936177747023054"), D.new("-0.0040720430116193")],
    [D.new("1.9779985324311684"), D.new("-2.4285922420485799"), D.new("0.450593709617411")],
    [D.new("0.0259040424655478"), D.new("0.7827717124575296"), D.new("-0.8086757549230774")]
  ])

  @lms2xyz M3x3.new([
    [D.new("1.2268798758459243"), D.new("-0.5578149944602171"), D.new("0.2813910456659647")],
    [D.new("-0.0405757452148008"), D.new("1.112286803280317"), D.new("-0.0717110580655164")],
    [D.new("-0.0763729366746601"), D.new("-0.4214933324022432"), D.new("1.5869240198367816")]
  ])

  @oklab2lms M3x3.new([
    [D.new(1), D.new("0.3963377773761749"), D.new("0.2158037573099136")],
    [D.new(1), D.new("-0.1055613458156586"), D.new("-0.0638541728258133")],
    [D.new(1), D.new("-0.0894841775298119"), D.new("-1.2914855480194092")]
  ])

  defguardp is_normalized(n) when is_number(n) and n >= 0 and n <= 1
  defguardp is_ok(n) when is_number(n) and n >= -1.00001 and n <= 1.00001
  @doc"""
  Generates a new OKLab color
  """
  def new(l, a_star, b_star), do: new(l, a_star, b_star, 1.0)

  def new(l, a_star, b_star, a)
  when is_normalized(a) and is_ok(l) and is_ok(a_star) and is_ok(b_star) do
    {:ok, struct(OKLab, l: l, a_star: a_star, b_star: b_star, a: a)}
  end

  @doc """
  Converts from OKLab to sRGB.

  ## Options

    - `:round`: an integer if rounding r, g, and b channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `0`
  """
  def to_rgb(%OKLab{} = oklab, options \\ []) when is_list(options) do
    round = Keyword.get(options, :round, 0)

    [oklab.l, oklab.a_star, oklab.b_star]
    # convert to decimal
    |> Enum.map(&D.new(to_string(&1)))
    # OKLab to LMS
    |> M3x3.mult(M3x3.t(@oklab2lms))
    # cube
    |> Enum.map(&D.mult(D.mult(&1, &1), &1))
    # LMS to XYZ
    |> M3x3.mult(M3x3.t(@lms2xyz))
    # create XYZ struct
    |> XYZ.new()
    # XYZ to RGB
    |> case do
      {:ok, xyz} ->
        xyz
        |> XYZ.to_rgb()
        # un-normalize
        |> Enum.map(&(&1 * 255))
        # clamp to the color space
        |> Enum.map(&clamp_to_byte/1)
        # maybe round each value
        |> Enum.map(&maybe_round(&1, round))
        |> then(fn [r, g, b] -> {:ok, %Color{r: r, g: g, b: b, a: oklab.a}} end)

      other ->
        other
    end
  end

  @doc """
  Converts from sRGB to OKLab.
  
  ## Options

    - `:round`: an integer if rounding L, a*, and b* channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `2`
  """
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    round = Keyword.get(options, :round, 2)
    {:ok, xyz} = XYZ.from_rgb(color)

    [xyz.x, xyz.y, xyz.z]
    # XYZ to LMS
    |> M3x3.mult(M3x3.t(@xyz2lms))
    # cube root
    |> Enum.map(fn d -> D.from_float(Float.pow(D.to_float(d), 1/3)) end)
    # LMS to OKLab
    |> M3x3.mult(M3x3.t(@lms2oklab))
    # create OKLab struct
    |> Enum.map(&maybe_round(D.to_float(&1), round))
    |> then(fn [l, a, b] ->
      {:ok, %OKLab{l: l, a_star: a, b_star: b, a: color.a}}
    end)
  end

  defp clamp_to_byte(n), do: min(max(n, 0), 255)

  defp maybe_round(channel, 0), do: round(channel)
  defp maybe_round(channel, digits) when is_integer(digits) and is_float(channel) do
    Float.round(channel, digits)
  end

  defp maybe_round(channel, _), do: channel
end

