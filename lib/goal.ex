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
    types = get_types(schema)
    changeset = build_changeset(params, types, schema)

    case changeset do
      %Ecto.Changeset{valid?: false} = changeset -> {:error, changeset}
      %Ecto.Changeset{valid?: true, changes: changes} -> {:ok, changes}
    end
  end

  defp build_changeset(params, types, schema) do
    data = %{}

    {data, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> validate_complex_fields(types, schema)
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

  defp validate_complex_fields(%Ecto.Changeset{changes: changes} = changeset, types, schema) do
    Enum.reduce(types, changeset, fn {field, type}, acc ->
      case type do
        :map ->
          inner_params = Map.get(changes, field)
          inner_rules = Map.get(schema, field)
          inner_schema = Keyword.get(inner_rules, :properties)

          if inner_schema do
            inner_types = get_types(inner_schema)
            inner_changeset = build_changeset(inner_params, inner_types, inner_schema)

            case inner_changeset do
              %Ecto.Changeset{valid?: false} ->
                IO.inspect(acc.types)

                acc
                |> put_in([Access.key(:changes), Access.key(field)], inner_changeset)
                |> Map.put(:valid?, false)

              %Ecto.Changeset{valid?: true} ->
                acc
            end
          else
            acc
          end

        _any ->
          acc
      end
    end)
  end
end
