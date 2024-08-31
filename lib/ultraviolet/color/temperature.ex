defmodule Ultraviolet.Color.Temperature do
  @moduledoc """
  Functions for mapping temperatures to colors.

  Based on Neil Bartlett's
  [implementation](https://github.com/neilbartlett/color-temperature)

  See `Ultraviolet.temperature/1` for examples.
  """

  alias Ultraviolet.Color
  alias Decimal, as: D
  import Ultraviolet.Helpers, only: [clamp_to_byte: 1, maybe_round: 2]

  @doc """
  Converts a temperature to an approximate color.

  The effective temperature range goes from 0 to about 30,000K.
  """
  @spec to_rgb(number()) :: {:ok, Color.t()} | {:error, term()}
  @spec to_rgb(number(), [...]) :: {:ok, Color.t()} | {:error, term()}
  def to_rgb(kelvin, options \\ [])
      when is_number(kelvin) and kelvin >= 0 and kelvin <= 30_000 and is_list(options) do
    round = Keyword.get(options, :round, 0)

    kelvin
    |> temp_to_rgb()
    |> Enum.map(&maybe_round(&1, round))
    |> Color.new()
  end

  @doc """
  Converts a color into an approximate temperature.
  """
  @spec from_rgb(Color.t()) :: number()
  @spec from_rgb(Color.t(), [...]) :: number()
  def from_rgb(%Color{r: r, b: b}, options \\ []) when is_list(options) do
    maybe_round(
      find_temp(b / r, 1000, 40_000, 0.4, 0),
      Keyword.get(options, :round, 0)
    )
  end

  defp find_temp(_ratio, min, max, eps, temp) when max - min <= eps, do: temp

  defp find_temp(ratio, min, max, eps, _temp) do
    temp = (max + min) / 2
    [r, _g, b] = temp_to_rgb(temp)

    cond do
      b / r >= ratio -> find_temp(ratio, min, temp, eps, temp)
      true -> find_temp(ratio, temp, max, eps, temp)
    end
  end

  defp temp_to_rgb(k) do
    (k / 100)
    |> List.duplicate(3)
    |> Enum.zip([&red/1, &green/1, &blue/1])
    |> Enum.map(fn {temp, func} -> func.(temp) end)
  end

  defp red(temperature) when temperature < 66, do: 255

  defp red(temperature) do
    r = temperature - 55

    D.new("351.97690566805693")
    |> D.add(D.mult("0.114206453784165", to_string(r)))
    |> D.sub(D.mult("40.25366309332127", to_string(:math.log(r))))
    |> D.to_float()
    |> clamp_to_byte()
    |> round()
  end

  defp green(temperature) when temperature < 6, do: 0

  defp green(temperature) when temperature < 66 do
    g = temperature - 2

    D.new("-155.25485562709179")
    |> D.sub(D.mult("0.44596950469579133", to_string(g)))
    |> D.add(D.mult("104.49216199393888", to_string(:math.log(g))))
    |> D.to_float()
    |> clamp_to_byte()
    |> round()
  end

  defp green(temperature) do
    g = temperature - 50

    D.new("325.4494125711974")
    |> D.add(D.mult("0.07943456536662342", to_string(g)))
    |> D.sub(D.mult("28.0852963507957", to_string(:math.log(g))))
    |> D.to_float()
    |> clamp_to_byte()
    |> round()
  end

  defp blue(temperature) when temperature < 20, do: 0

  defp blue(temperature) when temperature < 66 do
    b = temperature - 10

    D.new("-254.76935184120902")
    |> D.add(D.mult("0.8274096064007395", to_string(b)))
    |> D.add(D.mult("115.67994401066147", to_string(:math.log(b))))
    |> D.to_float()
    |> clamp_to_byte()
    |> round()
  end

  defp blue(_temperature), do: 255
end
