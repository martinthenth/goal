defmodule Goal do
  @moduledoc """
  Documentation for `Goal`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Goal.hello()
      :world

  """
  def validate(params, schema) do
    data = %{}
    types = get_types(schema)

    changeset =
      {data, types}
      |> Ecto.Changeset.cast(params, Map.keys(types))

    case changeset do
      %Ecto.Changeset{valid?: false} = changeset -> {:error, changeset}
      %Ecto.Changeset{valid?: true, changes: changes} -> {:ok, changes}
    end
  end

  defp get_types(schema) do
    Enum.reduce(schema, %{}, fn {field, rules}, acc ->
      case Keyword.get(rules, :type, :string) do
        :enum ->
          values =
            rules
            |> Keyword.get(:values, [])
            |> Enum.map(&String.to_atom/1)

          Map.put(acc, field, {:parameterized, Ecto.Enum, Ecto.Enum.init(values: values)})

        :list ->
          Map.put(acc, field, {:array, Keyword.get(rules, :inner_type, :string)})

        type ->
          Map.put(acc, field, type)
      end
    end)
  end
end
