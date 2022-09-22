defmodule Goal do
  @moduledoc """
  Documentation for `Goal`.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @doc """
  Validates the parameters against the schema.

  ## Examples

      iex> validate_params(%{"email" => "jane@example.com"}, %{email: [format: :email]})
      {:ok, %{email: "jane@example.com"}}

      iex> validate_params(%{"email" => "invalid"}, %{email: [format: :email]})
      {:error, %Ecto.Changeset{}}

  """
  @spec validate_params(map, map) :: {:ok, map} | {:error, Changeset.t()}
  def validate_params(params, schema) do
    case build_changeset(params, schema) do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
      %Changeset{valid?: false} = changeset -> {:error, changeset}
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

  defp build_changeset(params, schema) do
    types = get_types(schema)

    {%{}, types}
    |> Changeset.cast(params, Map.keys(types))
    |> validate_required_fields(schema)
    |> validate_simple_fields(schema)
    |> validate_nested_fields(types, schema)
  end

  defp validate_required_fields(%Changeset{} = changeset, schema) do
    required_fields =
      Enum.reduce(schema, [], fn {field, rules}, acc ->
        if Keyword.get(rules, :required, false) do
          [field | acc]
        else
          acc
        end
      end)

    validate_required(changeset, required_fields)
  end

  defp validate_simple_fields(%Changeset{changes: changes} = changeset, schema) do
    Enum.reduce(changes, changeset, fn {field, _value}, changeset_acc ->
      schema
      |> Map.get(field, [])
      |> Enum.reduce(changeset_acc, fn
        {:equals, value}, inner_acc ->
          validate_inclusion(inner_acc, field, [value])

        {:is, integer}, inner_acc ->
          validate_length(inner_acc, field, is: integer)

        {:min, integer}, inner_acc ->
          validate_length(inner_acc, field, min: integer)

        {:max, integer}, inner_acc ->
          validate_length(inner_acc, field, max: integer)

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

  defp validate_nested_fields(%Changeset{changes: changes} = changeset, types, schema) do
    Enum.reduce(types, changeset, fn
      {field, :map}, acc ->
        inner_params = Map.get(changes, field)
        inner_rules = Map.get(schema, field)
        inner_schema = Keyword.get(inner_rules, :properties)

        if inner_schema && inner_params do
          inner_params
          |> build_changeset(inner_schema)
          |> case do
            %Changeset{valid?: true, changes: changes} ->
              put_in(acc, [Access.key(:changes), Access.key(field)], changes)

            %Changeset{valid?: false} = inner_changeset ->
              acc
              |> put_in([Access.key(:changes), Access.key(field)], inner_changeset)
              |> Map.put(:valid?, false)
          end
        else
          acc
        end

      {field, {:array, :map}}, acc ->
        inner_params = Map.get(changes, field)
        inner_rules = Map.get(schema, field)
        inner_schema = Keyword.get(inner_rules, :properties)

        if inner_schema do
          {valid?, changesets} =
            Enum.reduce(inner_params, {true, []}, fn params, {boolean, list} ->
              params
              |> build_changeset(inner_schema)
              |> case do
                %Changeset{valid?: true, changes: changes} ->
                  {boolean, append_to_list(list, changes)}

                %Changeset{valid?: false} = inner_changeset ->
                  {false, append_to_list(list, inner_changeset)}
              end
            end)

          acc
          |> put_in([Access.key(:changes), Access.key(field)], changesets)
          |> Map.put(:valid?, valid?)
        else
          acc
        end

      {_field, _type}, acc ->
        acc
    end)
  end

  defp append_to_list(list, value), do: Enum.reverse([value | Enum.reverse(list)])
end
