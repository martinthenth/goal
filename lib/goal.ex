defmodule Goal do
  @moduledoc """
  Documentation for `Goal`.
  """

  alias Ecto.Changeset

  @doc """
  TODO: Add docs
  """
  @spec validate(map, map) :: {:ok, map} | {:error, Changeset.t()}
  def validate(params, schema) do
    schema
    |> get_types()
    |> build_changeset(params, schema)
    |> case do
      %Ecto.Changeset{valid?: false} = changeset -> {:error, changeset}
      %Ecto.Changeset{valid?: true, changes: changes} -> {:ok, changes}
    end
  end

  defp build_changeset(types, params, schema) do
    {%{}, types}
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
    Enum.reduce(types, changeset, fn
      {field, :map}, acc ->
        inner_params = Map.get(changes, field)
        inner_rules = Map.get(schema, field)
        inner_schema = Keyword.get(inner_rules, :properties)

        if inner_schema do
          inner_schema
          |> get_types()
          |> build_changeset(inner_params, inner_schema)
          |> case do
            %Ecto.Changeset{valid?: true} ->
              acc

            %Ecto.Changeset{valid?: false} = inner_changeset ->
              acc
              |> put_in([Access.key(:changes), Access.key(field)], inner_changeset)
              |> Map.put(:valid?, false)
          end
        else
          acc
        end

      {_field, _type}, acc ->
        acc
    end)
  end
end
