defmodule Ultraviolet.Color.LCH do
  @moduledoc """
  Functions for working in the LCH / HCL colorspace.
  """
  defstruct l: 0, c: 0, h: 0, a: 1.0

  # alias Ultraviolet.Color
  # alias __MODULE__

  @me __MODULE__

  defguardp is_hue(h) when is_integer(h) and h >= 0 and h <= 360
  defguardp is_normalized(n) when is_number(n) and n >= 0 and n <= 1

  def new(l, c, h), do: new(l, c, h, 1.0)

  def new(l, c, h, a)
  when is_hue(h) and is_number(l) and is_number(c) and is_normalized(a) do
    {:ok, struct(@me, h: h, c: c, l: l, a: a)}
  end
end
