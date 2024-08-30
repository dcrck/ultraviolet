defmodule Ultraviolet.ColorBrewer do
  @moduledoc """
  ColorBrewer colors for Ultraviolet.

  This module requires the optional `:json` dependency. If you don't include it,
  any call to `colors/2` will return `{:error, :not_found}`.

  ## License

  ```
  Copyright (c) 2002 Cynthia Brewer, Mark Harrower, and The Pennsylvania State
  University.

  Licensed under the Apache License, Version 2.0 (the "License"); you may not
  use this file except in compliance with the License. You may obtain a copy of
  the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
  License for the specific language governing permissions and limitations under
  the License.
  ```
  """
  import Ultraviolet.Helpers

  @external_resource colorbrewer_path = Path.join([__DIR__, "colorbrewer.json"])

  @doc """
  Retrieves the colorbrewer colors associated with the given name.

    iex>Ultraviolet.ColorBrewer.colors("Spectral")
    {:ok,
     [
       %Ultraviolet.Color{r: 213, g: 62, b: 79, a: 1.0},
       %Ultraviolet.Color{r: 244, g: 109, b: 67, a: 1.0},
       %Ultraviolet.Color{r: 253, g: 174, b: 97, a: 1.0},
       %Ultraviolet.Color{r: 254, g: 224, b: 139, a: 1.0},
       %Ultraviolet.Color{r: 255, g: 255, b: 191, a: 1.0},
       %Ultraviolet.Color{r: 230, g: 245, b: 152, a: 1.0},
       %Ultraviolet.Color{r: 171, g: 221, b: 164, a: 1.0},
       %Ultraviolet.Color{r: 102, g: 194, b: 165, a: 1.0},
       %Ultraviolet.Color{r: 50, g: 136, b: 189, a: 1.0}
     ]}

  You can also pass in an optional second argument to return a set number of
  colors for a given colorbrewer palette:

    iex>Ultraviolet.ColorBrewer.colors("Spectral", 3)
    {:ok,
     [
       %Ultraviolet.Color{r: 252, g: 141, b: 89, a: 1.0},
       %Ultraviolet.Color{r: 255, g: 255, b: 191, a: 1.0},
       %Ultraviolet.Color{r: 153, g: 213, b: 148, a: 1.0}
     ]}

  Unknown color palettes, or if you pass in an invalid color count for a given
  palette, will return an error tuple.

    iex>Ultraviolet.ColorBrewer.colors("Accent", 9)
    {:error, :not_found}
    iex>Ultraviolet.ColorBrewer.colors("Set3", -1)
    {:error, :not_found}
    iex>Ultraviolet.ColorBrewer.colors("UnknownPalette", 5)
    {:error, :not_found}

  **Note**: This function requires the `:jason` optional dependency to use. If
  `Jason` is not installed, all calls to `colors/1` or `colors/2` will return
  an error tuple.
  """
  def colors(name, count \\ 9)

  if Code.ensure_loaded?(Jason) do
    with {:ok, body} <- File.read(colorbrewer_path),
         {:ok, json} <- Jason.decode(body) do
      for {name, color_groups} <- json do
        for {count_str, colors} <- color_groups do
          with {len, ""} <- Integer.parse(count_str),
               {:ok, colors} <- validate_all(colors, &parse_css_color/1) do
            escaped = Macro.escape(colors)
            def colors(unquote(name), unquote(len)), do: {:ok, unquote(escaped)}
          else
            {:error, _} = error ->
              len = String.to_integer(count_str)
              def colors(unquote(name), unquote(len)), do: unquote(error)

            # there are other, non-integer keys in the JSON object, so we'll
            # ignore those
            :error ->
              :noop
          end
        end
      end
    end
  end

  def colors(_, _), do: {:error, :not_found}
end
