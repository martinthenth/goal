defmodule Goal do
  @moduledoc ~S"""
  Goal is a parameter validation library based on Ecto.

  It takes the parameters, e.g. from a Phoenix controller, validates them against a schema,
  and returns an atom-based map with the validated data. An `Ecto.Changeset` is returned if
  any of the parameters is invalid.

  Goal uses the validation rules from `Ecto.Changeset`, which means you can use any validation
  that is available for database fields for validating parameters with Goal.

  A common use-case is parsing and validating parameters from Phoenix controllers:

  ```elixir
  defmodule MyApp.SomeController do
    import Goal

    @schema %{
      id: [format: :uuid, required: true],
      name: [min: 3, max: 20, required: true]
    }

    def create(conn, params) do
      with {:ok, attrs} <- validate_params(params, @schema) do
        ...
      end
    end
  end
  ```

  With the `defschema` macro:

  ```elixir
  defmodule MyApp.SomeController do
    import Goal
    import Goal.Syntax

    def create(conn, params) do
      with {:ok, attrs} <- validate_params(params, schema()) do
        ...
      end
    end

    def schema do
      defschema do
        required :id, format: :uuid
        required :name, min: 3, max: 20
      end
    end
  end
  ```

  ## Defining validations

  Define field types with `:type`:

  - `:string`
  - `:integer`
  - `:boolean`
  - `:float`
  - `:decimal`
  - `:date`
  - `:time`
  - `:map`
  - `{:array, inner_type}`, where `inner_type` can be any of the field types
  - See [Ecto.Schema](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types) for the full list

  The default field type is `:string`. That means you don't have to define this field in the schema
  if the value will be a string.

  Define map fields with `:properties`.

  Define string validations:

  - `:equals`, string value
  - `:is`, string length
  - `:min`, minimum string length
  - `:max`, maximum string length
  - `:trim`, boolean to remove leading and trailing spaces
  - `:squish`, boolean to trim and collapse spaces
  - `:format`, atom to define the regex (available are: `:uuid`, `:email`, `:password`, `:url`)

  Define integer validations:

  - `:is`, integer value
  - `:min`, minimum integer value
  - `:max`, maximum integer value
  - `:greater_than`, minimum integer value
  - `:less_than`, maximum integer value
  - `:greater_than_or_equal_to`, minimum integer value
  - `:less_than_or_equal_to`, maximum integer value
  - `:equal_to`, integer value
  - `:not_equal_to`, integer value

  Define enum validations:

  - `:excluded`, list of disallowed values
  - `:included`, list of allowed values
  - `:subset`, list of values

  ## Bring your own regex

  Goal has sensible defaults for string format validation. If you'd like to use your own regex,
  e.g. for validating email addresses or passwords, you can configure your own regexes in your
  application configuration.

  ```elixir
  config :goal,
    uuid_regex: ~r/^[[:alpha:]]+$/,
    email_regex: ~r/^[[:alpha:]]+$/,
    password_regex: ~r/^[[:alpha:]]+$/,
    url_regex: ~r/^[[:alpha:]]+$/
  ```

  ## Deeply nested maps

  Goal efficiently builds error changesets for nested maps. There is no limitation on depth. If the
  schema is becoming too verbose, you could consider splitting up the schema into reusable components.

  ```elixir
  params = %{
    "nested_map" => %{
      "map" => %{
        "inner_map" => %{
          "id" => 123,
          "list" => [1, 2, 3]
        }
      }
    }
  }

  schema = %{
    nested_map: [
      type: :map,
      properties: %{
        inner_map: [
          type: :map,
          properties: %{
            map: [
              type: :map,
              properties: %{
                id: [type: :integer, required: true],
                list: [type: {:array, :integer}]
              }
            ]
          }
        ]
      }
    ]
  }

  iex(3)> Goal.validate_params(params, schema)
  {:ok, %{nested_map: %{inner_map: %{map: %{id: 123, list: [1, 2, 3]}}}}}
  ```

  ## Use defschema to reduce boilerplate

  Goal provides a macro called `Goal.Syntax.defschema/1` to build validation schemas without all
  the boilerplate code. The previous example of deeply nested maps can be rewritten as:

  ```elixir
  import Goal.Syntax

  params = %{...}

  schema =
    defschema do
      optional :nested_map, :map do
        optional :inner_map, :map do
          optional :map, :map do
            required :id, :integer
            optional :list, {:array, :integer}
          end
        end
      end
    end

  iex(3)> Goal.validate_params(params, schema)
  {:ok, %{nested_map: %{inner_map: %{map: %{id: 123, list: [1, 2, 3]}}}}}
  ```

  ## Human-readable error messages

  Use `Goal.traverse_errors/2` to build readable errors. Ecto and Phoenix by default
  use `Ecto.Changeset.traverse_errors/2`, which works for embedded Ecto schemas but not for the
  plain nested maps used by Goal.

  ```elixir
  def translate_errors(changeset) do
    Goal.traverse_errors(changeset, &translate_error/1)
  end
  ```

  ## Credits

  This library is based on [Ecto](https://github.com/elixir-ecto/ecto) and I had to copy and adapt
  `Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @type params :: map()
  @type schema :: map()
  @type error :: {String.t(), Keyword.t()}

  @doc ~S"""
  Validates the parameters against a schema.

  ## Examples

      iex> validate_params(%{"email" => "jane@example.com"}, %{email: [format: :email]})
      {:ok, %{email: "jane@example.com"}}

      iex> validate_params(%{"email" => "invalid"}, %{email: [format: :email]})
      {:error, %Ecto.Changeset{valid?: false, errors: [email: {"has invalid format", ...}]}}

  """
  @spec validate_params(params, schema) :: {:ok, map} | {:error, Changeset.t()}
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

  defp build_changeset(params, schema) do
    types = get_types(schema)

    {%{}, types}
    |> Changeset.cast(params, Map.keys(types))
    |> validate_required_fields(schema)
    |> validate_basic_fields(schema)
    |> validate_nested_fields(types, schema)
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

        type ->
          Map.put(acc, field, type)
      end
    end)
  end

  defp validate_required_fields(%Changeset{} = changeset, schema) do
    required_fields =
      Enum.reduce(schema, [], fn {field, rules}, acc ->
        if Keyword.get(rules, :required, false),
          do: [field | acc],
          else: acc
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

  defp validate_fields([], _field, changeset), do: changeset

  defp validate_fields(rules, field, changeset) do
    Enum.reduce(rules, changeset, fn
      {:equals, value}, acc ->
        validate_inclusion(acc, field, [value])

      {:excluded, values}, acc ->
        validate_exclusion(acc, field, values)

      {:included, values}, acc ->
        validate_inclusion(acc, field, values)

      {:subset, values}, acc ->
        validate_subset(acc, field, values)

      {:is, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_integer(change),
          do: validate_number(acc, field, equal_to: integer),
          else: validate_length(acc, field, is: integer)

      {:min, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_integer(change),
          do: validate_number(acc, field, greater_than_or_equal_to: integer),
          else: validate_length(acc, field, min: integer)

      {:max, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_integer(change),
          do: validate_number(acc, field, less_than_or_equal_to: integer),
          else: validate_length(acc, field, max: integer)

      {:trim, true}, acc ->
        update_change(acc, field, &String.trim/1)

      {:squish, true}, acc ->
        update_change(acc, field, &Goal.String.squish/1)

      {:format, :uuid}, acc ->
        validate_format(acc, field, Goal.Regex.uuid())

      {:format, :email}, acc ->
        validate_format(acc, field, Goal.Regex.email())

      {:format, :password}, acc ->
        validate_format(acc, field, Goal.Regex.password())

      {:format, :url}, acc ->
        validate_format(acc, field, Goal.Regex.url())

      {:less_than, integer}, acc ->
        validate_number(acc, field, less_than: integer)

      {:greater_than, integer}, acc ->
        validate_number(acc, field, greater_than: integer)

      {:less_than_or_equal_to, integer}, acc ->
        validate_number(acc, field, less_than_or_equal_to: integer)

      {:greater_than_or_equal_to, integer}, acc ->
        validate_number(acc, field, greater_than_or_equal_to: integer)

      {:equal_to, integer}, acc ->
        validate_number(acc, field, equal_to: integer)

      {:not_equal_to, integer}, acc ->
        validate_number(acc, field, not_equal_to: integer)

      {_name, _setting}, acc ->
        acc
    end)
  end

  defp validate_nested_fields(%Changeset{changes: changes} = changeset, types, schema) do
    Enum.reduce(types, changeset, fn
      {field, :map}, acc -> validate_map_field(changes, field, schema, acc)
      {field, {:array, :map}}, acc -> validate_array_field(changes, field, schema, acc)
      {_field, _type}, acc -> acc
    end)
  end

  defp validate_map_field(changes, field, schema, changeset) do
    params = Map.get(changes, field)
    rules = Map.get(schema, field)
    schema = Keyword.get(rules, :properties)

    if schema && params do
      params
      |> build_changeset(schema)
      |> case do
        %Changeset{valid?: true, changes: inner_changes} ->
          put_in(changeset, [Access.key(:changes), Access.key(field)], inner_changes)

        %Changeset{valid?: false} = inner_changeset ->
          changeset
          |> put_in([Access.key(:changes), Access.key(field)], inner_changeset)
          |> Map.put(:valid?, false)
      end
    else
      changeset
    end
  end

  defp validate_array_field(changes, field, schema, changeset) do
    params = Map.get(changes, field)
    rules = Map.get(schema, field)
    schema = Keyword.get(rules, :properties)

    if schema do
      {valid?, changesets} =
        Enum.reduce(params, {true, []}, fn params, {boolean, list} ->
          params
          |> build_changeset(schema)
          |> case do
            %Changeset{valid?: true, changes: inner_changes} ->
              {boolean, [inner_changes | list]}

            %Changeset{valid?: false} = inner_changeset ->
              {false, [inner_changeset | list]}
          end
        end)

      changeset
      |> put_in([Access.key(:changes), Access.key(field)], Enum.reverse(changesets))
      |> Map.put(:valid?, valid?)
    else
      changeset
    end
  end
end
