defmodule Goal do
  @moduledoc ~S"""
  Goal is a parameter validation library based on Ecto.

  Goal takes the `params` (e.g. from an Phoenix controller), validates them against a schema,
  and returns an atom-based map or an error changeset. It's based on
  [Ecto](https://github.com/elixir-ecto/ecto), so every validation that you have for database
  fields can be applied in validating parameters.

  Goal is different from other validation libraries because of its syntax, being Ecto-based,
  and validating data using functions from `Ecto.Changeset` instead of building embedded
  `Ecto.Schema`s in the background.

  Additionally, Goal allows you to configure your own regexes. This is helpful in case of backward
  compatibility, where Goal's defaults might not match your production system's behavior.

  ## Usage

  Goal's entry point is `Goal.validate_params/2`, which receives the parameters and a validation
  schema. The parameters must be a map, and can be string-based or atom-based. Goal needs a
  validation schema (also a map) to parse and validate the parameters. You can build one with
  the `defschema` macro:

  ```elixir
  defmodule MyApp.SomeController do
    import Goal
    import Goal.Syntax

    def create(conn, params) do
      with {:ok, attrs} <- validate_params(params, schema()) do
        ...
      end
    end

    defp schema do
      defschema do
        required :uuid, :string, format: :uuid
        required :name, :string, min: 3, max: 3
        optional :age, :integer, min: 0, max: 120
        optional :gender, :enum, values: ["female", "male", "non-binary"]

        optional :data, :map do
          required :color, :string
          optional :money, :decimal
          optional :height, :float
        end
      end
    end
  end
  ```

  The `defschema` macro converts the given structure into a validation schema at compile-time.
  You can also use the basic syntax like in the example below. The basic syntax is what
  `defschema` compiles to.

  ```elixir
  defmodule MyApp.SomeController do
    import Goal

    @schema %{
      id: [format: :uuid, required: true],
      name: [min: 3, max: 20, required: true],
      age: [type: :integer, min: 0, max: 120],
      gender: [type: :enum, values: ["female", "male", "non-binary"]],
      data: [
        type: :map,
        properties: %{
          color: [required: true],
          money: [type: :decimal],
          height: [type: :float]
        }
      ]
    }

    def create(conn, params) do
      with {:ok, attrs} <- validate_params(params, @schema) do
        ...
      end
    end
  end
  ```

  ## Features

  ### Bring your own regex

  Goal has sensible defaults for string format validation. If you'd like to use your own regex,
  e.g. for validating email addresses or passwords, then you can add your own regex in the
  configuration:

  ```elixir
  config :goal,
    uuid_regex: ~r/^[[:alpha:]]+$/,
    email_regex: ~r/^[[:alpha:]]+$/,
    password_regex: ~r/^[[:alpha:]]+$/,
    url_regex: ~r/^[[:alpha:]]+$/
  ```

  ### Deeply nested maps

  Goal efficiently builds error changesets for nested maps, and has support for lists of nested
  maps. There is no limitation on depth.

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

  ### Use defschema to reduce boilerplate

  Goal provides a macro called `Goal.Syntax.defschema/1` to build validation schemas without all
  the boilerplate code. The previous example of deeply nested maps can be rewritten to:

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

  ### Readable error messages

  Use `Goal.traverse_errors/2` to build readable errors. Phoenix by default uses
  `Ecto.Changeset.traverse_errors/2`, which works for embedded Ecto schemas but not for the plain
  nested maps used by Goal. Goal's `traverse_errors/2` is compatible with (embedded)
  `Ecto.Schema`s, so you don't have to make any changes to your existing logic.

  ```elixir
  def translate_errors(changeset) do
    Goal.traverse_errors(changeset, &translate_error/1)
  end
  ```

  ### Available validations

  The field types and available validations are:

  | Field type             | Validations                 | Description                                                                                          |
  | ---------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------- |
  | `:uuid`                | `:equals`                   | string value                                                                                         |
  | `:string`              | `:equals`                   | string value                                                                                         |
  |                        | `:is`                       | string length                                                                                        |
  |                        | `:min`                      | minimum string length                                                                                |
  |                        | `:max`                      | maximum string length                                                                                |
  |                        | `:trim`                     | oolean to remove leading and trailing spaces                                                         |
  |                        | `:squish`                   | boolean to trim and collapse spaces                                                                  |
  |                        | `:format`                   | `:uuid`, `:email`, `:password`, `:url`                                                               |
  |                        | `:subset`                   | list of required strings                                                                             |
  |                        | `:included`                 | list of allowed strings                                                                              |
  |                        | `:excluded`                 | list of disallowed strings                                                                           |
  | `:integer`             | `:equals`                   | integer value                                                                                        |
  |                        | `:is`                       | integer value                                                                                        |
  |                        | `:min`                      | minimum integer value                                                                                |
  |                        | `:max`                      | maximum integer value                                                                                |
  |                        | `:greater_than`             | minimum integer value                                                                                |
  |                        | `:less_than`                | maximum integer value                                                                                |
  |                        | `:greater_than_or_equal_to` | minimum integer value                                                                                |
  |                        | `:less_than_or_equal_to`    | maximum integer value                                                                                |
  |                        | `:equal_to`                 | integer value                                                                                        |
  |                        | `:not_equal_to`             | integer value                                                                                        |
  |                        | `:subset`                   | list of required integers                                                                            |
  |                        | `:included`                 | list of allowed integers                                                                             |
  |                        | `:excluded`                 | list of disallowed integers                                                                          |
  | `:float`               |                             | all of the integer validations                                                                       |
  | `:decimal`             |                             | all of the integer validations                                                                       |
  | `:boolean`             | `:equals`                   | boolean value                                                                                        |
  | `:date`                | `:equals`                   | date value                                                                                           |
  | `:time`                | `:equals`                   | time value                                                                                           |
  | `:enum`                | `:values`                   | list of allowed values                                                                               |
  | `:map`                 | `:properties`               | use `:properties` to define the fields                                                               |
  | `{:array, :map}`       | `:properties`               | use `:properties` to define the fields                                                               |
  | `{:array, inner_type}` |                             | `inner_type` can be any of the basic types                                                           |
  | More basic types       |                             | See [Ecto.Schema](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types) for the full list |

  The default basic type is `:string`. You don't have to define this field if you are using the
  basic syntax.

  All field types, exluding `:map` and `{:array, :map}`, can use `:equals`, `:subset`,
  `:included`, `:excluded` validations.

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
  Validates parameters against a schema.

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

        :uuid ->
          Map.put(acc, field, Ecto.UUID)

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

        if is_binary(change),
          do: validate_length(acc, field, is: integer),
          else: validate_number(acc, field, equal_to: integer)

      {:min, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_binary(change),
          do: validate_length(acc, field, min: integer),
          else: validate_number(acc, field, greater_than_or_equal_to: integer)

      {:max, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_binary(change),
          do: validate_length(acc, field, max: integer),
          else: validate_number(acc, field, less_than_or_equal_to: integer)

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
