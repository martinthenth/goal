defmodule Goal do
  @moduledoc """
  Documentation for `Goal`.
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @type data :: map()
  @type schema :: map()
  @type error :: {String.t(), Keyword.t()}

  @doc ~S"""
  Validates parameters against a schema.

  ## Examples

      iex> validate_params(%{"email" => "jane@example.com"}, %{email: [format: :email]})
      {:ok, %{email: "jane@example.com"}}

      iex> validate_params(%{"email" => "invalid"}, %{email: [format: :email]})
      {:error, %Ecto.Changeset{valid?: false, errors: [email: {"has invalid format", ...}]}}

  """
  @spec validate_params(data, schema) :: {:ok, map} | {:error, Changeset.t()}
  def validate_params(params, schema) do
    case build_changeset(params, schema) do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
      %Changeset{valid?: false} = changeset -> {:error, changeset}
    end
  end

  @doc ~S"""
  Traverses changeset errors and applies the given function to error messages.

  ## Examples

      iex> traverse_errors(changeset, fn {msg, opts} ->
      ...>   Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      ...>     opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      ...>   end)
      ...> end)
      %{title: ["should be at least 3 characters"]}

  """
  @spec traverse_errors(Changeset.t(), (error -> binary) | (Changeset.t(), atom, error -> binary)) ::
          %{atom => [term]}
  defdelegate traverse_errors(changeset, msg_func), to: Goal.Changeset

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
    |> validate_basic_fields(schema)
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

  defp validate_basic_fields(%Changeset{changes: changes} = changeset, schema) do
    Enum.reduce(changes, changeset, fn {field, _value}, changeset_acc ->
      schema
      |> Map.get(field, [])
      |> validate_fields(field, changeset_acc)
    end)
  end

  defp validate_fields(rules, field, changeset) do
    Enum.reduce(rules, changeset, fn
      {:equals, value}, inner_acc ->
        validate_inclusion(inner_acc, field, [value])

      {:excluded, values}, inner_acc ->
        validate_exclusion(inner_acc, field, values)

      {:included, values}, inner_acc ->
        validate_inclusion(inner_acc, field, values)

      {:subset, values}, inner_acc ->
        validate_subset(inner_acc, field, values)

      {:is, integer}, inner_acc ->
        change = get_in(inner_acc, [Access.key(:changes), Access.key(field)])

        if is_integer(change),
          do: validate_number(inner_acc, field, equal_to: integer),
          else: validate_length(inner_acc, field, is: integer)

      {:min, integer}, inner_acc ->
        change = get_in(inner_acc, [Access.key(:changes), Access.key(field)])

        if is_integer(change),
          do: validate_number(inner_acc, field, greater_than_or_equal_to: integer),
          else: validate_length(inner_acc, field, min: integer)

      {:max, integer}, inner_acc ->
        change = get_in(inner_acc, [Access.key(:changes), Access.key(field)])

        if is_integer(change),
          do: validate_number(inner_acc, field, less_than_or_equal_to: integer),
          else: validate_length(inner_acc, field, max: integer)

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
