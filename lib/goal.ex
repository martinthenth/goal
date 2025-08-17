defmodule Goal do
  @moduledoc File.read!("README.md") |> String.split("\n\n") |> tl() |> tl() |> Enum.join("\n\n")

  import Ecto.Changeset

  alias Ecto.Changeset

  @typedoc false
  @type name :: atom() | binary()

  @typedoc false
  @type schema :: map()

  @typedoc false
  @type params :: map()

  @typedoc false
  @type cases :: :camel_case | :snake_case | :pascal_case | :kebab_case

  @typedoc false
  @type opts :: [recase_keys: [from: cases(), to: cases()]]

  @typedoc false
  @type error :: {String.t(), Keyword.t()}

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
      import Goal,
        only: [
          defparams: 1,
          defparams: 2,
          optional: 1,
          optional: 2,
          optional: 3,
          required: 1,
          required: 2,
          required: 3,
          build_changeset: 2,
          recase_keys: 3
        ]

      @doc """
      Builds a changeset from the schema and params.
      """
      @spec changeset(atom() | binary()) :: Ecto.Changeset.t()
      @spec changeset(atom() | binary(), map()) :: Ecto.Changeset.t()
      @spec changeset(atom() | binary(), map(),
              recase_keys: [from: :camel_case | :snake_case | :pascal_case | :kebab_case]
            ) :: Ecto.Changeset.t()
      def changeset(name, params \\ %{}, opts \\ []) do
        schema = schema(name)
        params = recase_keys(schema, params, opts)

        build_changeset(schema, params)
      end

      @doc """
      Returns the validated parameters or an error changeset.
      """
      @spec validate(Ecto.Changeset.t()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
      def validate(%Changeset{valid?: true} = changeset),
        do: {:ok, Changeset.apply_changes(changeset)}

      def validate(%Changeset{valid?: false} = changeset), do: {:error, changeset}

      @doc """
      Returns the validated parameters or an error changeset.
      Expects a schema to be defined with `defparams`.
      """
      @spec validate(atom() | binary()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
      @spec validate(atom() | binary(), map()) :: {:ok, map()} | {:error, Ecto.Changeset.t()}
      @spec validate(atom() | binary(), map(),
              recase_keys: [from: :camel_case | :snake_case | :pascal_case | :kebab_case]
            ) ::
              {:ok, map()}
              | {:error, Ecto.Changeset.t()}
      def validate(name, params \\ %{}, opts \\ []) do
        schema = schema(name)
        params = recase_keys(schema, params, opts)

        schema
        |> build_changeset(params)
        |> Map.put(:action, :validate)
        |> validate()
      end
    end
  end

  @doc """
  A macro for defining validation schemas encapsulated in a `schema` function with arity 0.

  ```elixir
  defmodule MySchema do
    use Goal

    defparams do
      required :id, :string, format: :uuid
    end
  end

  iex(1)> schema()
  %{id: [type: :integer, required: true]}]
  ```
  """
  @spec defparams(do_block()) :: any
  defmacro defparams(do: block) do
    fields =
      case block do
        {:__block__, _, contents} -> contents
        {_, _, _} -> [block]
      end

    quote do
      def schema do
        Enum.reduce(unquote(fields), %{}, fn item, acc ->
          Map.merge(acc, item)
        end)
      end
    end
  end

  @doc """
  A macro for defining validation schemas encapsulated in a `schema` function with arity 1.
  The argument can be an atom or a binary.

  ```elixir
  defmodule MySchema do
    use Goal

    defparams :index do
      required :id, :string, format: :uuid
    end
  end

  iex(1)> MySchema.schema(:index)
  %{id: [type: :integer, required: true]}]
  iex(2)> MySchema.changeset(:index, %{id: 12})
  %Ecto.Changeset{valid?: true, changes: %{id: 12}}
  iex(3)> MySchema.validate(:index, %{id: 12})
  {:ok, %{id: 12}}
  ```
  """
  @spec defparams(name(), do_block()) :: any
  defmacro defparams(name, do: block) do
    fields =
      case block do
        {:__block__, _, contents} -> contents
        {_, _, _} -> [block]
      end

    quote do
      def schema(unquote(name)) do
        Enum.reduce(unquote(fields), %{}, fn item, acc ->
          Map.merge(acc, item)
        end)
      end
    end
  end

  @doc """
  Defines an optional field in the schema.
  """
  @spec optional(atom()) :: Macro.t()
  @spec optional(atom(), atom()) :: Macro.t()
  @spec optional(atom(), atom(), opts()) :: Macro.t()
  defmacro optional(name, type \\ :any, opts \\ [])

  defmacro optional(name, type, opts) when type in [:map, {:array, :map}] do
    children = get_field_children(opts)
    field_opts = get_field_options(opts)

    quote do
      properties = Enum.reduce(unquote(children), %{}, &Map.merge(&2, &1))

      if properties == %{} do
        %{unquote(name) => [{:type, unquote(type)} | unquote(field_opts)]}
      else
        %{
          unquote(name) => [
            {:type, unquote(type)} | [{:properties, properties} | unquote(field_opts)]
          ]
        }
      end
    end
  end

  defmacro optional(name, type, opts) do
    quote do
      %{unquote(name) => [{:type, unquote(type)} | unquote(opts)]}
    end
  end

  @doc """
  Defines a required field in the schema.
  """
  @spec required(atom()) :: Macro.t()
  @spec required(atom(), atom()) :: Macro.t()
  @spec required(atom(), atom(), opts()) :: Macro.t()
  defmacro required(name, type \\ :any, opts \\ [])

  defmacro required(name, type, opts) when type in [:map, {:array, :map}] do
    children = get_field_children(opts)
    field_opts = get_field_options(opts)

    quote do
      properties = Enum.reduce(unquote(children), %{}, &Map.merge(&2, &1))

      if properties == %{} do
        %{unquote(name) => [{:type, unquote(type)} | [{:required, true} | unquote(field_opts)]]}
      else
        %{
          unquote(name) => [
            {:type, unquote(type)}
            | [{:required, true} | [{:properties, properties} | unquote(field_opts)]]
          ]
        }
      end
    end
  end

  defmacro required(name, type, opts) do
    quote do
      %{unquote(name) => [{:type, unquote(type)} | [{:required, true} | unquote(opts)]]}
    end
  end

  defp get_field_children(opts) do
    case block_or_tuple = Keyword.get(opts, :do) do
      {:__block__, _, contents} -> contents
      {_, _, _} -> [block_or_tuple]
      _ -> []
    end
  end

  defp get_field_options(opts) do
    if Keyword.has_key?(opts, :do) do
      []
    else
      opts
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
  @spec validate_params(schema(), params(), opts()) :: {:ok, params()} | {:error, changeset()}
  def validate_params(schema, params, opts \\ []) do
    params = recase_keys(schema, params, opts)

    schema
    |> build_changeset(params)
    |> Map.put(:action, :validate)
    |> case do
      %Changeset{valid?: true} = changes -> {:ok, Changeset.apply_changes(changes)}
      %Changeset{valid?: false} = changeset -> {:error, changeset}
    end
  end

  @doc ~S"""
  Builds an `Ecto.Changeset` using the parameters and a validation schema.

  ## Examples

      iex> build_changeset(%{email: [format: :email]}, %{"email" => "jane@example.com"})
      %Ecto.Changeset{valid?: true, changes: %{email: "jane@example.com"}}

      iex> build_changeset(%{email: [format: :email]}, %{"email" => "invalid"})
      %Ecto.Changeset{valid?: false, errors: [email: {"has invalid format", ...}]}

  """
  @spec build_changeset(schema(), params()) :: Changeset.t()
  def build_changeset(schema, params) do
    types = get_types(schema)
    defaults = build_defaults(schema)

    {defaults, types}
    |> Changeset.cast(params, Map.keys(types), force_changes: true)
    |> validate_required_fields(schema)
    |> validate_basic_fields(schema)
    |> validate_nested_fields(types, schema)
  end

  @doc """
  Recases parameter keys.

  Use only when you have full control of the data. For example, to render JSON responses.

  ## Examples

      iex> recase_keys(%{"first_name" => "Jane"}, recase_keys: [to: :camel_case])
      %{firstName: "Jane"}

  Supported are `:camel_case`, `:pascal_case`, `:kebab_case` and `:snake_case`.
  """
  @spec recase_keys(params()) :: params()
  @spec recase_keys(params(), opts()) :: params()
  def recase_keys(params, opts \\ []) do
    settings = Keyword.get(opts, :recase_keys) || Application.get_env(:goal, :recase_keys)

    if settings do
      to_case = Keyword.get(settings, :to)
      is_atom_map = is_atom_map?(params)

      recase_outbound_keys(params, to_case, is_atom_map)
    else
      params
    end
  end

  @doc """
  Recases parameter keys that are present in the schema.

  Use this instead of `recase_keys/2` for incoming parameters. For example, for user requests.

  ## Examples

      iex> recase_keys(%{first_name: [type: :string]}, %{"firstName" => "Jane"}, recase_keys: [from: :camel_case])
      %{first_name: "Jane"}

  Supported are `:camel_case`, `:pascal_case`, `:kebab_case` and `:snake_case`.
  """
  @spec recase_keys(schema(), params(), opts()) :: params()
  def recase_keys(schema, params, opts) do
    settings = Keyword.get(opts, :recase_keys) || Application.get_env(:goal, :recase_keys)

    if settings do
      from_case = Keyword.get(settings, :from)
      is_atom_map = is_atom_map?(params)

      recase_inbound_keys(schema, params, from_case, is_atom_map)
    else
      params
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
  @spec traverse_errors(
          changeset(),
          (error() -> binary()) | (changeset(), atom(), error() -> binary())
        ) :: %{atom() => [term()]}
  defdelegate traverse_errors(changeset, msg_func), to: Goal.Changeset

  defp get_types(schema) do
    Enum.reduce(schema, %{}, fn {field, rules}, acc ->
      case Keyword.get(rules, :type, :any) do
        {:array, :enum} ->
          values =
            rules
            |> Keyword.get(:rules, [])
            |> Keyword.get(:values, [])
            |> Enum.map(&atomize/1)

          Map.put(
            acc,
            field,
            {:array, {:parameterized, {Ecto.Enum, Ecto.Enum.init(values: values)}}}
          )

        :enum ->
          values =
            rules
            |> Keyword.get(:values, [])
            |> Enum.map(&atomize/1)

          Map.put(acc, field, {:parameterized, {Ecto.Enum, Ecto.Enum.init(values: values)}})

        :uuid ->
          Map.put(acc, field, Ecto.UUID)

        type ->
          Map.put(acc, field, type)
      end
    end)
  end

  defp build_defaults(schema) do
    Enum.reduce(schema, %{}, fn {field, rules}, acc ->
      case Keyword.get(rules, :default) do
        nil -> acc
        default -> Map.put_new(acc, field, default)
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

        if is_binary(change) || is_list(change),
          do: validate_length(acc, field, is: integer),
          else: validate_number(acc, field, equal_to: integer)

      {:min, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_binary(change) || is_list(change),
          do: validate_length(acc, field, min: integer),
          else: validate_number(acc, field, greater_than_or_equal_to: integer)

      {:max, integer}, acc ->
        change = get_in(acc, [Access.key(:changes), Access.key(field)])

        if is_binary(change) || is_list(change),
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

      {:format, %Regex{} = regex}, acc ->
        validate_format(acc, field, regex)

      {:format, key}, acc when is_atom(key) ->
        validate_format(acc, field, Goal.Regex.custom(key))

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
      {field, :map}, acc ->
        validate_map_field(changes, field, schema, acc)

      {field, {:array, :map}}, acc ->
        validate_array_map_field(changes, field, schema, acc)

      {field, {:array, type}}, acc
      when type in [:string, :integer, :decimal, :float, :boolean, :date, :time] ->
        validate_array_basic_field(changes, field, schema, type, acc)

      {field, {:array, {:parameterized, _}}}, acc ->
        validate_array_enum_field(field, schema, acc)

      {_field, _type}, acc ->
        acc
    end)
  end

  defp validate_map_field(changes, field, schema, changeset) do
    params = Map.get(changes, field)
    rules = Map.get(schema, field)
    schema = Keyword.get(rules, :properties)

    if schema && params do
      schema
      |> build_changeset(params)
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

  defp validate_array_map_field(changes, field, schema, changeset) do
    params = Map.get(changes, field)
    rules = Map.get(schema, field)
    schema = Keyword.get(rules, :properties)

    if schema && is_list(params) do
      {valid?, changesets} = reduce_and_validate_array_map_fields(schema, params)

      changeset
      |> put_in([Access.key(:changes), Access.key(field)], Enum.reverse(changesets))
      |> Map.update!(:valid?, &Kernel.&&(&1, valid?))
    else
      item_rules = Keyword.get(rules, :rules)

      if item_rules do
        validate_fields(item_rules, field, changeset)
      else
        changeset
      end
    end
  end

  defp reduce_and_validate_array_map_fields(schema, params) do
    Enum.reduce(params, {true, []}, fn params, {boolean, list} ->
      schema
      |> build_changeset(params)
      |> case do
        %Changeset{valid?: true, changes: inner_changes} ->
          {boolean, [inner_changes | list]}

        %Changeset{valid?: false} = inner_changeset ->
          {false, [inner_changeset | list]}
      end
    end)
  end

  defp validate_array_basic_field(changes, field, schema, type, changeset) do
    params = Map.get(changes, field)
    rules = Map.get(schema, field)
    item_rules = Keyword.get(rules, :rules)

    if item_rules && is_list(params) do
      case reduce_and_validate_array_basic_fields(item_rules, type, field, params) do
        {:valid, changes} ->
          changeset
          |> put_in([Access.key(:changes), Access.key(field)], Enum.reverse(changes))
          |> Map.update!(:valid?, &Kernel.&&(&1, true))

        {:invalid, errors} ->
          changeset
          |> Map.update!(:errors, &(errors ++ &1))
          |> Map.put(:valid?, false)
      end
    else
      changeset
    end
  end

  defp reduce_and_validate_array_basic_fields(schema, type, field, params) do
    schema = %{:inner_schema => [{:type, type} | schema]}

    result =
      Enum.reduce(params, {:valid, []}, fn params, {status, acc} ->
        changeset = build_changeset(schema, %{:inner_schema => params})

        case {status, changeset} do
          {:valid, %Changeset{valid?: true, changes: %{:inner_schema => inner_changes}}} ->
            {:valid, [inner_changes | acc]}

          {:valid, %Changeset{valid?: false, errors: errors}} ->
            # The implementation is "all or nothing", so even if there where successful
            # changes before, we reset them now since the whole changeset isn't valid.
            {:invalid, MapSet.new(errors)}

          {:invalid, %Changeset{valid?: false, errors: errors}} ->
            {:invalid, MapSet.new(errors) |> MapSet.union(acc)}

          {:invalid, %Changeset{valid?: true}} ->
            {:invalid, acc}
        end
      end)

    case result do
      {:invalid, errors} ->
        errors = for {:inner_schema, {msg, opts}} <- errors, do: {field, {"item " <> msg, opts}}
        {:invalid, errors}

      {:valid, changeset} ->
        {:valid, changeset}
    end
  end

  defp validate_array_enum_field(field, schema, changeset) do
    item_rules =
      schema
      |> Map.get(field)
      |> Keyword.get(:rules, [])
      |> Keyword.delete(:values)

    validate_fields(item_rules, field, changeset)
  end

  defp atomize(atom) when is_atom(atom), do: atom
  defp atomize(string) when is_binary(string), do: String.to_atom(string)

  defp is_atom_map?(map) when is_map(map) do
    Enum.reduce_while(map, false, fn {key, _value}, _acc -> {:halt, is_atom(key)} end)
  end

  defp recase_inbound_keys(_schema, value, _from_case, _is_atom_map) when is_struct(value),
    do: value

  defp recase_inbound_keys(schema, params, from_case, is_atom_map) when is_map(params) do
    Enum.reduce(schema, %{}, fn {field, rules}, acc ->
      recased_field =
        field
        |> Atom.to_string()
        |> recase_key(from_case)

      recased_field = if is_atom_map, do: String.to_atom(recased_field), else: recased_field
      fallback_field = if is_atom_map, do: field, else: Atom.to_string(field)

      cond do
        Map.has_key?(params, recased_field) ->
          Map.put(acc, field, get_value(rules, params, recased_field, from_case, is_atom_map))

        Map.has_key?(params, fallback_field) ->
          Map.put(acc, field, get_value(rules, params, fallback_field, from_case, is_atom_map))

        true ->
          acc
      end
    end)
  end

  defp recase_inbound_keys(schema, value, from_case, is_atom_map) when is_list(value) do
    Enum.map(value, &recase_inbound_keys(schema, &1, from_case, is_atom_map))
  end

  defp recase_inbound_keys(_schema, value, _from_case, _is_atom_map), do: value

  defp get_value(rules, params, field, from_case, is_atom_map) do
    value = Map.get(params, field)
    schema = Keyword.get(rules, :properties)

    if (is_map(value) || is_list(value)) && schema do
      rules
      |> Keyword.get(:properties)
      |> recase_inbound_keys(value, from_case, is_atom_map)
    else
      value
    end
  end

  defp recase_outbound_keys(struct, _to_case, _is_atom_map) when is_struct(struct), do: struct

  defp recase_outbound_keys(params, to_case, is_atom_map) when is_map(params) do
    Enum.reduce(params, %{}, fn {key, value}, acc ->
      value = recase_outbound_keys(value, to_case, is_atom_map)

      key = if is_atom(key), do: Atom.to_string(key), else: key
      key = recase_key(key, to_case)
      key = if is_atom_map, do: String.to_atom(key), else: key

      Map.put(acc, key, value)
    end)
  end

  defp recase_outbound_keys(value, to_case, is_atom_map) when is_list(value) do
    Enum.map(value, &recase_outbound_keys(&1, to_case, is_atom_map))
  end

  defp recase_outbound_keys(value, _to_case, _is_atom_map), do: value

  defp recase_key(string, :camel_case), do: Recase.to_camel(string)
  defp recase_key(string, :snake_case), do: Recase.to_snake(string)
  defp recase_key(string, :kebab_case), do: Recase.to_kebab(string)
  defp recase_key(string, :pascal_case), do: Recase.to_pascal(string)
end
