defmodule Goal.String do
  @moduledoc """
  Defines string operations.
  """

  @doc """
  Returns a string where all leading, trailing, and multiple inner Unicode whitespaces have been removed.

  ## Examples

      iex> squish(" banana  man ")
      "banana man"

  """
  @spec squish(binary) :: binary
  def squish(string) do
    string
    |> String.split()
    |> Enum.join(" ")
  end
end
