defmodule TemperatureTest do
  use ExUnit.Case

  alias Ultraviolet.Color
  alias Ultraviolet.Color.Temperature

  doctest Temperature

  cases = %{
    "100" => {{255, 0, 0, 1.0}, 100},
    "1k" => {{255, 58, 0, 1.0}, 1000},
    "4k" => {{255, 208, 164, 1.0}, 4000},
    "5k" => {{255, 228, 205, 1.0}, 5000},
    "7k" => {{245, 243, 255, 1.0}, 7000},
    "10k" => {{204, 220, 255, 1.0}, 10000},
    "20k" => {{168, 197, 255, 1.0}, 20000},
    "30k" => {{159, 190, 255, 1.0}, 30000},
  }

  for {name, {{r, g, b, a}, kelvin}} <- cases do
    test "parses simple kelvin colors for #{name}" do
      assert {:ok, color} = Color.new(unquote(r), unquote(g), unquote(b), unquote(a))
      assert {:ok, ^color} = Temperature.to_rgb(unquote(kelvin))
    end
  end
end
