defmodule Ultraviolet.M3x3 do
  @moduledoc false
  # 3x3 Matrix implementation, used for certain color space translations.
  # This is generally for internal use only and 

  defstruct [:m00, :m01, :m02, :m10, :m11, :m12, :m20, :m21, :m22]

  alias Decimal, as: D
  alias __MODULE__

  @doc """
  Generates a new 3x3 matrix
  """
  def new([[m00, m01, m02], [m10, m11, m12], [m20, m21, m22]]) do
    %M3x3{
      m00: D.new(m00), m01: D.new(m01), m02: D.new(m02),
      m10: D.new(m10), m11: D.new(m11), m12: D.new(m12),
      m20: D.new(m20), m21: D.new(m21), m22: D.new(m22),
    }
  end

  @doc """
  Multiply matrix `m` by a 3x1 column vector consisting of `[x, y, z]`.

  Returns a vector with the result of multiplication; technically, it's a 3x1
  column vector, but we just return the flat list.
  """
  def mult(%M3x3{} = m, [x, y, z]) do
    a =
      D.mult(x, m.m00)
      |> D.add(D.mult(y, m.m10))
      |> D.add(D.mult(z, m.m20))

    b =
      D.mult(x, m.m01)
      |> D.add(D.mult(y, m.m11))
      |> D.add(D.mult(z, m.m21))

    c =
      D.mult(x, m.m02)
      |> D.add(D.mult(y, m.m12))
      |> D.add(D.mult(z, m.m22))

    [a, b, c]
  end
end
