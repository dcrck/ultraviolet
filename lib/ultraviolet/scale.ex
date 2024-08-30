defmodule Ultraviolet.Scale do
  @moduledoc """
  Function related to creating and using color scales.

  Color scales are essentually functions that map numbers to a color palette.
  """

  import Ultraviolet.Helpers

  alias Ultraviolet.Color
  alias __MODULE__

  defstruct [
    colors: [%Color{r: 255, g: 255, b: 255}, %Color{}],
    space: :rgb,
    domain: [0, 1],
    padding: {0, 0},
    gamma: 1,
    correct_lightness?: false,
    classes: 0,
    interpolation: :linear,
    positions: [],
  ]

  @doc """
  Creates a new color scale. See `Ultraviolet.scale/2` for details about
  creating scales.
  """
  def new(), do: {:ok, struct(Scale)}
  def new(colors, options \\ []) when is_list(colors) and is_list(options) do
    with nil <- Enum.find(colors, &!match?(%{__struct__: Color}, &1)),
         {:ok, opts} <- validate_and_add_options(options, colors) do
      struct(Scale, Map.put(opts, :colors, colors))
      |> add_color_positions()
      |> then(&{:ok, &1})
    else
      {:error, _} = error -> error
      other -> {:error, "#{inspect(other)} is not a Color"}
    end
  end

  defp validate_and_add_options(options, _colors) when is_list(options) do
    options
    |> Enum.into(%{})
    |> Map.take([:space, :domain, :padding, :gamma, :correct_lightness?, :classes, :interpolation])
    |> validate_interpolation()
    |> ok_if_no_error()
  end

  defp validate_interpolation(%{interpolation: :bezier, space: :lab} = options), do: options
  defp validate_interpolation(%{interpolation: :bezier, space: :oklab} = options), do: options

  defp validate_interpolation(%{interpolation: :bezier, space: _space}) do
    {:error, "bezier interpolation requires either Lab or OKLab colorspace"}
  end

  defp validate_interpolation(%{interpolation: :bezier} = options) do
    Map.put(options, :space, :lab)
  end

  defp validate_interpolation(options), do: options

  defp add_color_positions(scale) do
    %{scale | positions: color_positions(scale)}
  end

  defp color_positions(%{domain: [_min, _max], colors: colors}) do
    even_steps(0, 1, length(colors))
  end

  defp color_positions(%{domain: domain, colors: colors} = scale) do
    {min, max} = domain_bounds(scale)
    n = length(colors)
    cond do
      n == length(domain) && min != max ->
        Enum.map(domain, fn d -> (d - min) / (max - min) end)
      true ->
        even_steps(0, 1, n)
    end
  end

  defp ok_if_no_error({:error, _} = error), do: error
  defp ok_if_no_error(options), do: {:ok, options}

  @doc """
  Retrieves a single color from the `scale` at the given `value `in the domain.
  """
  def fetch(scale, value, bypass? \\ false)

  def fetch(%Scale{} = scale, value, bypass?) when is_number(value) do
    with {:ok, x} <- domain(scale, value, bypass?) do
      interpolate(scale, x)
    else
      error -> error
    end
  end

  def fetch(%Scale{}, _, _), do: {:error, :domain}

  defp domain(%Scale{} = scale, value, true) do
    apply_functions_or_error(
      scale,
      [&domain_map/2, &gamma/2, &pad/2, &limit/2],
      value
    )
  end

  defp domain(%Scale{} = scale, value, _no_bypass) do
    apply_functions_or_error(
      scale,
      [&classify/2, &domain_map/2, &lightness/2, &gamma/2, &pad/2, &limit/2],
      value
    )
  end

  defp classify(%{classes: n} = scale, x) when is_integer(n) and n > 2 do
    {min, max} = domain_bounds(scale)
    class = Enum.find_index(even_steps(min, max, n), &(x < &1)) - 1
    {:ok, class / (n - 2)}
  end

  defp classify(%{classes: [], domain: [min | rest]},  x) do
    {:ok, normalize_between(min, hd(Enum.reverse(rest)), x)}
  end

  defp classify(%{classes: [_c], domain: [min | rest]}, x) do
    {:ok, normalize_between(min, hd(Enum.reverse(rest)), x)}
  end

  defp classify(%{classes: [_c1, _c2], domain: [min | rest]}, x) do
    {:ok, normalize_between(min, hd(Enum.reverse(rest)), x)}
  end

  defp classify(%{classes: classes}, x) when is_list(classes) do
    class = Enum.find_index(classes, &(x < &1)) - 1
    {:ok, class / (length(classes) - 2)}
  end

  defp classify(%{domain: [min | rest]}, x) do
    {:ok, normalize_between(min, hd(Enum.reverse(rest)), x)}
  end

  defp normalize_between(min, max, _x) when max == min, do: 1
  defp normalize_between(min, max, x), do: (x - min) / (max - min)

  # don't make any changes if domain is 2 items or less (the normal case)
  defp domain_map(%{domain: []}, x), do: {:ok, x}
  defp domain_map(%{domain: [_x1]}, x), do: {:ok, x}
  defp domain_map(%{domain: [_d1, _d2]}, x), do: {:ok, x}

  defp domain_map(scale, x) do
    {min, max} = domain_bounds(scale)
    case length(scale.domain) do
      d_len when d_len != length(scale.colors) and min != max ->
        maybe_adjust_domain_map(
          Enum.map(scale.domain, fn d -> (d - min) / (max - min) end),
          even_steps(0, 1, d_len),
          x
        )
      _ ->
        {:ok, x}
    end
  end

  defp maybe_adjust_domain_map(_breaks, _out, x) when x >= 1, do: {:ok, 1}
  defp maybe_adjust_domain_map(_breaks, _out, x) when x <= 0, do: {:ok, 0}

  defp maybe_adjust_domain_map(breaks, out, x) when breaks != out do
    breaks
    |> Enum.zip(out)
    |> Enum.chunk_every(2, 1)
    |> Enum.reduce_while({:ok, x}, fn
      [{b0, o0}, {b1, o1}], {:ok, v} when v >= b0  and v < b1 ->
        f = (v - b0) / (b1 - b0)
        {:halt, {:ok, o0 + f * (o1 - o0)}}
      _, x ->
        {:cont, x}
    end)
  end

  defp maybe_adjust_domain_map(_, _, x), do: {:ok, x}

  defp lightness(%{correct_lightness?: false}, x), do: {:ok, x}

  defp lightness(scale, x) do
    {:ok, color0} = fetch(scale, 0, true)
    {:ok, color1} = fetch(scale, 1, true)
    {:ok, %{l_: l0}} = Color.into(color0, :lab)
    {:ok, %{l_: l1}} = Color.into(color1, :lab)

    target_lightness = l0 + (l1 - l0) * x
    {:ok, correct_lightness(scale, target_lightness, x, 0, 1, 20, l0 > l1)}
  end

  defp correct_lightness(_scale, _target, x, _x0, _x1, 0, _pol), do: x
  defp correct_lightness(scale, target, x, x0, x1, attempts, pol) do
    {:ok, color} = fetch(scale, x, true)
    {:ok, %{l_: actual}} = Color.into(color, :lab)
    diff = (actual - target) * diff_sign(pol)
    do_correct_lightness(scale, target, diff, x, x0, x1, attempts, pol)
  end

  defp diff_sign(true), do: -1
  defp diff_sign(_), do: 1

  defp do_correct_lightness(_scale, _target, diff, x, _x0, _x1, _n, _pol)
  when diff <= 0.01 and diff >= -0.01, do: x

  defp do_correct_lightness(scale, target, diff, x, _x0, x1, n, pol)
  when diff < 0 do
    correct_lightness(scale, target, x + (x1 - x) / 2, x, x1, n - 1, pol)
  end

  defp do_correct_lightness(scale, target, _diff, x, x0, _x1, n, pol) do
    correct_lightness(scale, target, x + (x0 - x) / 2, x0, x, n - 1, pol)
  end

  defp gamma(%{gamma: 1}, x), do: {:ok, x}
  defp gamma(%{gamma: g}, x), do: {:ok, :math.pow(x, g)}

  defp pad(%{padding: 0}, x), do: {:ok, x}
  defp pad(%{padding: {0, 0}}, x), do: {:ok, x}
  defp pad(%{padding: {l, r}}, x), do: {:ok, l + x * (1 - l - r)}

  defp pad(%{padding: padding}, x) when is_number(padding) do
    pad(%{padding: {padding, padding}}, x)
  end

  defp limit(_scale, x), do: {:ok, min(max(x, 0), 1)}

  defp apply_functions_or_error(scale, fns, initial_value) do
    Enum.reduce_while(
      fns,
      {:ok, initial_value},
      fn f, {:ok, x} ->
        case f.(scale, x) do
          {:error, _} = error -> {:halt, error}
          result -> {:cont, result}
        end
      end
    )
  end

  defp interpolate(%{interpolation: func}, x) when is_function(func, 1) do
    case func.(x) do
      {:ok, %Color{} = color} -> {:ok, color}
      %Color{} = color -> {:ok, color}
      other -> other
    end
  end

  defp interpolate(%{interpolation: :bezier, colors: [color]}, _x) do
    {:ok, color}
  end

  defp interpolate(%{interpolation: :bezier, colors: colors, space: space}, x)
  when space in [:lab, :oklab] do
    n = length(colors) - 1
    {:ok, labs} = validate_all(colors, &Color.into(&1, space))

    labs
    |> Enum.zip(pascal_row(n))
    |> Enum.with_index(fn {lab, coef}, index -> {index, lab, coef} end)
    |> Enum.reduce([0, 0, 0], fn {i, lab, coef}, sums ->
      [lab.l_, lab.a_, lab.b_]
      |> Enum.zip(sums)
      |> Enum.map(fn {ch, sum} ->
        sum + coef * :math.pow(1 - x, n - i) * :math.pow(x, i) * ch
      end)
    end)
    |> then(fn [l, a, b] -> Color.new(l, a, b, space) end)
  end

  defp interpolate(scale, x) do
    [scale.positions, scale.colors]
    |> Enum.zip()
    |> Enum.chunk_every(2, 1)
    |> Enum.reduce_while({:ok, x}, fn
      [{pos, color} | _], {:ok, x} when x <= pos ->
        {:halt, {:ok, color}}
      [{pos, color}], {:ok, x} when x >= pos ->
        {:halt, {:ok, color}}
      [{pos, color}, {next, target}], {:ok, x} when x > pos and x < next ->
        {:halt, Color.mix(color, target, (x - pos) / (next - pos), scale.space)}
      _, x ->
        {:cont, x}
    end)
  end

  # rows of pascals triangle
  defp pascal_row(n) do
    find_pascal_row([1, 1], n - 1)
  end

  defp find_pascal_row(row, 0), do: row
  defp find_pascal_row(row, n) do
    row
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [a, b] -> a + b end)
    |> then(&find_pascal_row(List.flatten([1, &1, 1]), n - 1))
  end

  @doc """
  Retrieves a single color from the scale at the given value in the domain.
  If the given value is invalid, returns the `default` color. If the given value
  is outside of the domain, returns the closest domain bound, i.e. the highest
  or lowest value in the domain.
  """
  def get(scale, x, default) do
    case fetch(scale, x) do
      {:ok, color} -> color
      _ -> default
    end
  end

  @doc """
  ### If `xs` is a list:

  Returns a map with all the number/color pairs in `scale` where the number is
  in `xs`. If `xs` contains values that are not within the `scale`'s domain,
  they are clipped to the domain maximum.

  ### If `xs` is a positive integer:

  Returns a list of `xs` equi-distant colors from the scale.
  """
  def take(scale, xs) when is_list(xs) do
    xs
    |> Enum.flat_map(fn x ->
      case get(scale, x, nil) do
        nil -> []
        color -> [color]
      end
    end)
  end

  def take(%Scale{} = scale, n) when is_integer(n) do
    {min, max} = domain_bounds(scale)
    take(scale, even_steps(min, max, n))
  end

  # n evenly spaced out values between `min` and `max`, inclusive
  defp even_steps(min, max, n) when n >= 2 do
    Enum.map(1..n, fn i -> min + (i - 1) * (max - min) / (n - 1) end)
  end
  defp even_steps(min, max, _n), do: [min, max]

  defp domain_bounds(%{domain: d}), do: {hd(d), hd(Enum.reverse(d))}
end
