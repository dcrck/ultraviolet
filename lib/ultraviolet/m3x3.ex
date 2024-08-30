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
      m00: D.new(m00),
      m01: D.new(m01),
      m02: D.new(m02),
      m10: D.new(m10),
      m11: D.new(m11),
      m12: D.new(m12),
      m20: D.new(m20),
      m21: D.new(m21),
      m22: D.new(m22)
    }
  end

  @doc """
  Transposes matrix `m`
  """
  def t(%M3x3{} = m) do
    %M3x3{
      m00: m.m00,
      m01: m.m10,
      m02: m.m20,
      m10: m.m01,
      m11: m.m11,
      m12: m.m21,
      m20: m.m02,
      m21: m.m12,
      m22: m.m22
    }
  end

  @doc """
  Multiply a 1x3 row vector `[x, y, z]` by matrix `m`

  ```
              | m00 m01 m02 |
  [x, y, z] * | m10 m11 m12 | = [a, b, c]
              | m20 m21 m22 |

  a = x * m00 + y * m10 + z * m20
  b = x * m01 + y * m11 + z * m21
  c = x * m02 + y * m12 + z * m22
  ```

  returns the result, i.e. `[a, b, c]`
  """
  def mult([x, y, z], %M3x3{} = m) do
    [
      D.mult(x, m.m00)
      |> D.add(D.mult(y, m.m10))
      |> D.add(D.mult(z, m.m20)),
      D.mult(x, m.m01)
      |> D.add(D.mult(y, m.m11))
      |> D.add(D.mult(z, m.m21)),
      D.mult(x, m.m02)
      |> D.add(D.mult(y, m.m12))
      |> D.add(D.mult(z, m.m22))
    ]
  end
end
