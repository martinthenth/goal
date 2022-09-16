defmodule Goal do
  @moduledoc """
  Documentation for `Goal`.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @doc """
  Validates the given parameters against the given schema.

  ## Examples

      iex> validate_params(%{"email" => "jane@example.com"}, %{email: [type: :string, format: :email]})
      {:ok, %{email: "jane@example.com"}}

      iex> validate_params(%{"email" => "invalid"}, %{email: [type: :string, format: :email]})
      {:error, %Ecto.Changeset{}}

  """
  @spec validate_params(map, map) :: {:ok, map} | {:error, Changeset.t()}
  def validate_params(params, schema) do
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
    |> validate_simple_fields(schema)
    |> validate_nested_fields(types, schema)
  end

  defp validate_simple_fields(%Ecto.Changeset{changes: changes} = changeset, schema) do
    Enum.reduce(changes, changeset, fn {field, _value}, changeset_acc ->
      schema
      |> Map.get(field, [])
      |> Enum.reduce(changeset_acc, fn
        {:trim, true}, inner_acc ->
          update_change(inner_acc, field, &String.trim/1)

        {:squish, true}, inner_acc ->
          update_change(inner_acc, field, &Goal.String.squish/1)

        {:format, :uuid}, inner_acc ->
          validate_format(inner_acc, field, Goal.Regex.uuid())

        {:format, :email}, inner_acc ->
          validate_format(inner_acc, field, Goal.Regex.email())

        {:format, :password}, inner_acc ->
          validate_format(inner_acc, field, Goal.Regex.password())

        {:format, :url}, inner_acc ->
          validate_format(inner_acc, field, Goal.Regex.url())

        {:less_than, integer}, inner_acc ->
          validate_number(inner_acc, field, less_than: integer)

        {:greater_than, integer}, inner_acc ->
          validate_number(inner_acc, field, greater_than: integer)

        {:less_than_or_equal_to, integer}, inner_acc ->
          validate_number(inner_acc, field, less_than_or_equal_to: integer)

        {:greater_than_or_equal_to, integer}, inner_acc ->
          validate_number(inner_acc, field, greater_than_or_equal_to: integer)

        {:equal_to, integer}, inner_acc ->
          validate_number(inner_acc, field, equal_to: integer)

        {:not_equal_to, integer}, inner_acc ->
          validate_number(inner_acc, field, not_equal_to: integer)

        {_name, _setting}, inner_acc ->
          inner_acc
      end)
    end)
  end

  defp validate_nested_fields(%Ecto.Changeset{changes: changes} = changeset, types, schema) do
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
