defmodule Ultraviolet.Color.LCH do
  @moduledoc """
  Functions for working in the LCH / HCL colorspace.
  """
  defstruct l: 0, c: 0, h: 0, a: 1.0
  @type t :: %{l: number(), c: number(), h: number(), a: number()}

  alias Ultraviolet.Color
  alias Ultraviolet.Color.Lab
  alias __MODULE__

  @me __MODULE__

  import Ultraviolet.Helpers,
    only: [maybe_round: 2, is_angle: 1, is_unit_interval: 1]

  @doc """
  Generates a new LCH color

      iex>Ultraviolet.Color.LCH.new({0.5, 0.0, 60})
      {:ok, %Ultraviolet.Color.LCH{h: 60, c: 0.0, l: 0.5}}

  """
  @spec new(tuple() | [number()] | map() | [...]) :: {:ok, t()}
  def new({l, c, h}), do: new(l, c, h, 1.0)
  def new({l, c, h, a}), do: new(l, c, h, a)
  def new([l, c, h]) when is_number(l), do: new(l, c, h, 1.0)
  def new([l, c, h, a]) when is_number(l), do: new(l, c, h, a)

  # map of channel values
  def new(channels) when is_map(channels) do
    new([
      Map.get(channels, :l),
      Map.get(channels, :c),
      Map.get(channels, :h),
      Map.get(channels, :a, 1.0)
    ])
  end

  # keyword list of channel values
  def new([{k, _} | _rest] = channels) when is_list(channels) and is_atom(k) do
    new(Enum.into(channels, %{}))
  end

  @doc """
  Generates a new LCH color

      iex>Ultraviolet.Color.LCH.new(0.5, 0.0, 60)
      {:ok, %Ultraviolet.Color.LCH{h: 60, c: 0.0, l: 0.5}}

  """
  def new(l, c, h), do: new(l, c, h, 1.0)

  @doc """
  Generates a new LCH color

      iex>Ultraviolet.Color.LCH.new(0.5, 0.0, 60, 0.5)
      {:ok, %Ultraviolet.Color.LCH{h: 60, c: 0.0, l: 0.5, a: 0.5}}

  """
  def new(l, c, h, a)
      when is_angle(h) and is_number(l) and is_number(c) and is_unit_interval(a) do
    {:ok, struct(@me, h: h, c: c, l: l, a: a)}
  end

  @doc """
  Converts from LCH to an RGB Color struct

  ## Options

  - `:reference`: the CIE Lab white reference point. Default: `:d65`
  - `:round`: an integer if rounding r, g, and b channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `0`

  """
  @spec to_rgb(t()) :: {:ok, Color.t()}
  @spec to_rgb(t(), [...]) :: {:ok, Color.t()}
  def to_rgb(%LCH{} = lch, options \\ []) when is_list(options) do
    case lch_to_lab(lch) do
      {:ok, lab} -> Lab.to_rgb(lab, options)
      error -> error
    end
  end

  @doc """
  Converts from an RGB Color struct to a LCH struct.

  ## Options

  - `:reference`: the CIE Lab white reference point. Default: `:d65`
  - `:round`: an integer if rounding L, a*, and b* channel values to N decimal
    places is desired; if no rounding is desired, pass `false`. Default: `2`

  """
  @spec from_rgb(Color.t()) :: {:ok, t()}
  @spec from_rgb(Color.t(), [...]) :: {:ok, t()}
  def from_rgb(%Color{} = color, options \\ []) when is_list(options) do
    case Lab.from_rgb(color, Keyword.merge(options, round: false)) do
      {:ok, lab} -> lab_to_lch(lab, options)
      error -> error
    end
  end

  # degrees to radians
  defp deg_to_rad(n), do: n * :math.pi() / 180.0
  # radians to degrees
  defp rad_to_deg(n), do: n * 180.0 / :math.pi()

  defp lch_to_lab(%LCH{l: l, c: c, h: h, a: a}) do
    h
    |> deg_to_rad()
    |> then(&Lab.new(l, :math.cos(&1) * c, :math.sin(&1) * c, a))
  end

  defp lab_to_lch(%Lab{a_: a, b_: b} = lab, options) do
    round = Keyword.get(options, :round, 2)
    c = :math.sqrt(a * a + b * b)

    h =
      cond do
        round(c * 10000) == 0 -> 0
        true -> mod(rad_to_deg(:math.atan2(b, a)) + 360, 360)
      end

    [lab.l_, c, h]
    |> Enum.map(&maybe_round(&1, round))
    |> then(fn [l, c, h] -> new(l, c, h, lab.a) end)
  end

  # simple floating-point modulus
  defp mod(n, x) when n >= 0 and n < x, do: n
  defp mod(n, x) when n >= 0, do: mod(n - x, n)
end
