defmodule Goal2 do
  @moduledoc """
  TODO: Add docs
  """

  import Ecto.Changeset

  alias Ecto.Changeset

  @typedoc false
  @type name :: atom() | binary()

  @typedoc false
  @type schema :: map()

  @typedoc false
  @type params :: map()

  @typedoc false
  @type changeset :: Changeset.t()

  @typedoc false
  @type block :: {:__block__, any, any}

  @typedoc false
  @type do_block :: [do: block()]

  @doc false
  @spec __using__(block()) :: any()
  defmacro __using__(_) do
    quote do
      import Goal2, only: [defparams: 1, defparams: 2, build_changeset: 2]

      @typedoc false
      @type name :: atom() | binary()

      @typedoc false
      @type params :: map()

      @typedoc false
      @type changeset :: Changeset.t()

      @doc """
      Builds a changeset from the schema and params.
      """
      @spec changeset(name(), params()) :: changeset()
      def changeset(name, params \\ %{}) do
        name
        |> schema()
        |> build_changeset(params)
      end

      @doc """
      Returns the validated parameters or an error changeset.
      """
      @spec validate(changeset()) :: {:ok, params()} | {:error, changeset()}
      def validate(%Changeset{valid?: true, changes: changes}), do: {:ok, changes}
      def validate(%Changeset{valid?: false} = changeset), do: {:error, changeset}

      @doc """
      Returns the validated parameters or an error changeset.
      Expects a schema to be defined with `defparams`.
      """
      @spec validate(name(), params()) :: {:ok, params()} | {:error, changeset()}
      def validate(name, params \\ %{}) do
        name
        |> changeset(params)
        |> validate()
      end
    end
  end

  @doc """
  A macro for defining validation schemas. Can be assigned to a variable.

  ```elixir
  import Goal

  defp schema do
    defschema do
      required :id, :string, format: :uuid
      required :name, :string
      optional :age, :integer, min: 0, max: 120
      optional :gender, :enum, values: ["female", "male", "non-binary"]

      required :data, :map do
        required :city, :string
        optional :birthday, :date
      end
    end
  end
  ```
  """
  @spec defschema(do_block()) :: any
  defmacro defschema(do: block) do
    block
    |> generate_schema()
    |> Macro.escape()
  end

  @doc """
  A macro for defining validation schemas encapsulated in a `schema` function with arity 0.

  ```elixir
  defmodule UserSchema do
    use Goal

    defparams :index do
      required :id, :string, format: :uuid
    end
  end

  iex(1)> schema()
  %{id: [type: :integer, required: true]}]
  """
  @spec defparams(do_block()) :: any
  defmacro defparams(do: block) do
    quote do
      def schema do
        unquote(block |> generate_schema() |> Macro.escape())
      end
    end
  end

  @doc """
  A macro for defining validation schemas encapsulated in a `schema` function with arity 1.
  The argument can be an atom or a binary.

  ```elixir
  defmodule UserSchema do
    use Goal

    defparams :index do
      required :id, :string, format: :uuid
    end
  end

  iex(1)> UserSchema.schema(:index)
  %{id: [type: :integer, required: true]}]
  iex(2)> UserSchema.changeset(:index, %{id: 12})
  %Ecto.Changeset{valid?: true, changes: %{id: 12}}
  iex(3)> UserSchema.validate(:index, %{id: 12})
  {:ok, %{id: 12}}
  """
  @spec defparams(name(), do_block()) :: any
  defmacro defparams(name, do: block) do
    quote do
      def schema(unquote(name)) do
        unquote(block |> generate_schema() |> Macro.escape())
      end
    end
  end

  @doc ~S"""
  Validates parameters against a validation schema.

  ## Examples

      iex> validate_params(%{email: [format: :email]}, %{"email" => "jane@example.com"})
      {:ok, %{email: "jane@example.com"}}

      iex> validate_params(%{email: [format: :email]}, %{"email" => "invalid"})
      {:error, %Ecto.Changeset{valid?: false, errors: [email: {"has invalid format", ...}]}}

  """
  @spec validate_params(schema(), params()) :: {:ok, params()} | {:error, changeset()}
  def validate_params(schema, params) do
    case build_changeset(params, schema) do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
      %Changeset{valid?: false} = changeset -> {:error, changeset}
    end
  end

  @doc ~S"""
  Builds an `Ecto.Changeset` using the parameters and a validation schema.

  ## Examples

      iex> build_changeset(%{"email" => "jane@example.com"}, %{email: [format: :email]})
      %Ecto.Changeset{valid?: true, changes: %{email: "jane@example.com"}}

      iex> build_changeset(%{"email" => "invalid"}, %{email: [format: :email]})
      %Ecto.Changeset{valid?: false, errors: [email: {"has invalid format", ...}]}

  """
  @spec build_changeset(schema(), params()) :: Changeset.t()
  def build_changeset(schema, params) do
    types = get_types(schema)

    {%{}, types}
    |> Changeset.cast(params, Map.keys(types))
    |> validate_required_fields(schema)
    |> validate_basic_fields(schema)
    |> validate_nested_fields(types, schema)
    |> Map.put(:action, :validate)
  end

  defp generate_schema({:__block__, _lines, contents}) do
    Enum.reduce(contents, %{}, fn function, acc ->
      Map.merge(acc, generate_schema(function))
    end)
  end

  defp generate_schema({:optional, _lines, [field, type]}) do
    %{field => [{:type, type}]}
  end

  defp generate_schema({:optional, _lines, [field, type, options]}) do
    if block_or_function = Keyword.get(options, :do) do
      properties = generate_schema(block_or_function)
      clean_options = Keyword.delete(options, :do)

      %{field => [{:type, type} | [{:properties, properties} | clean_options]]}
    else
      %{field => [{:type, type} | options]}
    end
  end

  defp generate_schema({:required, _lines, [field, type]}) do
    %{field => [{:type, type}, {:required, true}]}
  end

  defp generate_schema({:required, _lines, [field, type, options]}) do
    if block_or_function = Keyword.get(options, :do) do
      properties = generate_schema(block_or_function)
      clean_options = Keyword.delete(options, :do)

      %{
        field => [
          {:type, type} | [{:required, true} | [{:properties, properties} | clean_options]]
        ]
      }
    else
      %{field => [{:type, type} | [{:required, true} | options]]}
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
