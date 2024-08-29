defmodule Ultraviolet.Scale do
  @moduledoc """
  Function related to creating and using color scales.

  Color scales are essentually functions that map numbers to a color palette.
  """

  alias Ultraviolet.Color
  alias __MODULE__

  defstruct [
    colors: [%Color{r: 255, g: 255, b: 255}, %Color{}],
    space: :rgb,
    domain: [0, 1],
    padding: [0, 0],
    gamma: 1,
    correct_lightness?: false,
    classes: 0,
    interpolation: :linear,
  ]

  @doc """
  Creates a new color scale. See `Ultraviolet.scale/2` for details about
  creating scales.
  """
  def new(), do: {:ok, struct(Scale)}
  def new(colors, options \\ []) when is_list(colors) and is_list(options) do
    with nil <- Enum.find(colors, &!match?(%{__struct__: Color}, &1)),
         {:ok, opts} <- validate_scale_options(options, colors) do
      {:ok, struct(Scale, Map.put(opts, :colors, colors))}
    else
      {:error, _} = error -> error
      other -> {:error, "#{inspect(other)} is not a Color"}
    end
  end

  @doc """
  merges the `options` with given `Scale` and returns the new `Scale`.
  """
  def with_options(%Scale{} = scale, options) when is_list(options) do
    case validate_scale_options(options, scale.colors) do
      {:ok, opts} -> Map.merge(scale, opts)
      _ -> scale
    end
  end

  defp validate_scale_options(options, _colors) when is_list(options) do
    options
    |> Enum.into(%{})
    |> Map.take([:space, :domain, :padding, :gamma, :correct_lightness?, :classes, :interpolation])
    # TODO add more validations here
    |> ok_if_no_error()
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
      # TODO write these functions
      [&domain_map/2, &gamma/2, &pad/2, &limit/2],
      value,
    )
  end

  defp domain(%Scale{} = scale, value, _no_bypass) do
    apply_functions_or_error(
      scale,
      [&classify/2, &domain_map/2, &lightness/2, &gamma/2, &pad/2, &limit/2],
      value,
    )
  end

  # TODO figure out classification
  defp classify(_scale, x), do: {:ok, x}

  # TODO maybe support domain/color mismatch
  defp domain_map(_scale, x), do: {:ok, x}

  defp lightness(%{correct_lightness?: false}, x), do: {:ok, x}
  # TODO figure this out
  defp lightness(_scale, x) do
    {:ok, x}
  end

  defp gamma(%{gamma: 1}, x), do: {:ok, x}
  defp gamma(%{gamma: g}, x), do: {:ok, :math.pow(x, g)}

  defp pad(%{padding: 0}, x), do: {:ok, x}
  defp pad(%{padding: [0, 0]}, x), do: {:ok, x}
  defp pad(%{padding: [l, r]}, x), do: {:ok, l + x * (1 - l - r)}

  defp pad(%{padding: padding}, x) when is_number(padding) do
    pad(%{padding: [padding, padding]}, x)
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

  defp interpolate(_scale, x) do
    # TODO interpolate based on interpolation method (linear, custom, bezier, etc.)
    Color.new("black")
  end

  @doc """
  Retrieves a single color from the scale at the given value in the domain.
  If the given value is outside of the domain or otherwise invalid, returns the
  `default` color.
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
  they are simply ignored.

  ### If `xs` is a positive integer:

  Returns a list of `xs` equi-distant colors from the scale.
  """
  def take(scale, xs) when is_list(xs) do
    xs
    |> Enum.flat_map(xs, fn x ->
      case get(scale, x, nil) do
        nil -> []
        color -> [{x, color}]
    end)
    |> Enum.into(%{})
  end

  def take(%{domain: d} = scale, n) when is_integer(n) and n > 0 do
    max = hd(Enum.reverse(d))
    min = hd(d)
    take(scale, Enum.map(0..n-1, fn i -> i * (max - min) / (n - 1) end))
  end
end
