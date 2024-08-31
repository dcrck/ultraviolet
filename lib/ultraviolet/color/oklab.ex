defmodule Ultraviolet.Color.OKLab do
  @moduledoc """
  Functions for working with the
  [OKLab](https://bottosson.github.io/posts/oklab/) color space.

  Uses the `:d65` reference illuminant.
  """
  defstruct l_: 0, a_: 0, b_: 0, a: 1.0
  @type t :: %{l_: number(), a_: number(), b_: number(), a: number()}

  alias Decimal, as: D

  alias Ultraviolet.M3x3
  alias Ultraviolet.Color
  alias Ultraviolet.Color.XYZ
  alias __MODULE__

  import Ultraviolet.Helpers,
    only: [is_unit_interval: 1, is_under_one: 1, maybe_round: 2, clamp_to_byte: 1]

  @xyz2lms M3x3.new([
             [
               D.new("0.819022437996703"),
               D.new("0.3619062600528904"),
               D.new("-0.1288737815209879")
             ],
             [
               D.new("0.0329836539323885"),
               D.new("0.9292868615863434"),
               D.new("0.0361446663506424")
             ],
             [
               D.new("0.0481771893596242"),
               D.new("0.2642395317527308"),
               D.new("0.6335478284694309")
             ]
           ])

  @lms2oklab M3x3.new([
               [
                 D.new("0.210454268309314"),
                 D.new("0.7936177747023054"),
                 D.new("-0.0040720430116193")
               ],
               [
                 D.new("1.9779985324311684"),
                 D.new("-2.4285922420485799"),
                 D.new("0.450593709617411")
               ],
               [
                 D.new("0.0259040424655478"),
                 D.new("0.7827717124575296"),
                 D.new("-0.8086757549230774")
               ]
             ])

  @lms2xyz M3x3.new([
             [
               D.new("1.2268798758459243"),
               D.new("-0.5578149944602171"),
               D.new("0.2813910456659647")
             ],
             [
               D.new("-0.0405757452148008"),
               D.new("1.112286803280317"),
               D.new("-0.0717110580655164")
             ],
             [
               D.new("-0.0763729366746601"),
               D.new("-0.4214933324022432"),
               D.new("1.5869240198367816")
             ]
           ])

  @oklab2lms M3x3.new([
               [D.new(1), D.new("0.3963377773761749"), D.new("0.2158037573099136")],
               [D.new(1), D.new("-0.1055613458156586"), D.new("-0.0638541728258133")],
               [D.new(1), D.new("-0.0894841775298119"), D.new("-1.2914855480194092")]
             ])

  @doc """
  Generates a new OKLab color

      iex>Ultraviolet.Color.OKLab.new({0.5, 0.0, 0.0})
      {:ok, %Ultraviolet.Color.OKLab{l_: 0.5, a_: 0.0, b_: 0.0}}

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
  Generates a new OKLab color

      iex>Ultraviolet.Color.OKLab.new(0.5, 0.0, 0.0)
      {:ok, %Ultraviolet.Color.OKLab{l_: 0.5, a_: 0.0, b_: 0.0}}

  """
  @spec new(number(), number(), number()) :: {:ok, t()}
  def new(l, a, b), do: new(l, a, b, 1.0)

  @doc """
  Generates a new OKLab color

      iex>Ultraviolet.Color.OKLab.new(0.5, 0.0, 0.0, 0.5)
      {:ok, %Ultraviolet.Color.OKLab{l_: 0.5, a_: 0.0, b_: 0.0, a: 0.5}}

  """
  @spec new(number(), number(), number(), number()) :: {:ok, t()}
  def new(l, a, b, a_)
      when is_unit_interval(a_) and is_under_one(l) and is_under_one(a) and is_under_one(b) do
    {:ok, struct(OKLab, l_: l, a_: a, b_: b, a: a_)}
  end

  @doc """
  Converts from OKLab to sRGB.

  ## Options

    - `:round`: an integer if rounding r, g, and b channel values to N decimal
      places is desired; if no rounding is desired, pass `false`. Default: `0`
  """
  @spec to_rgb(t()) :: {:ok, Color.t()}
  @spec to_rgb(t(), [...]) :: {:ok, Color.t()}
  def to_rgb(%OKLab{} = oklab, options \\ []) when is_list(options) do
    round = Keyword.get(options, :round, 0)

    [oklab.l_, oklab.a_, oklab.b_]
    |> Enum.map(&D.new(to_string(&1)))
    |> M3x3.mult(M3x3.t(@oklab2lms))
    |> Enum.map(&D.mult(D.mult(&1, &1), &1))
    |> M3x3.mult(M3x3.t(@lms2xyz))
    |> XYZ.new()
    |> case do
      {:ok, xyz} ->
        xyz
        |> XYZ.to_rgb()
        |> Enum.map(&(&1 * 255))
        |> Enum.map(&clamp_to_byte/1)
        |> Enum.map(&maybe_round(&1, round))
        |> then(&Color.new(&1 ++ [oklab.a]))

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
  @spec from_rgb(Color.t()) :: {:ok, t()}
  @spec from_rgb(Color.t(), [...]) :: {:ok, t()}
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    round = Keyword.get(options, :round, 2)
    {:ok, xyz} = XYZ.from_rgb(color)

    [xyz.x, xyz.y, xyz.z]
    |> M3x3.mult(M3x3.t(@xyz2lms))
    |> Enum.map(fn d -> D.from_float(Float.pow(D.to_float(d), 1 / 3)) end)
    |> M3x3.mult(M3x3.t(@lms2oklab))
    |> Enum.map(&maybe_round(D.to_float(&1), round))
    |> then(&new(&1 ++ [color.a]))
  end
end
