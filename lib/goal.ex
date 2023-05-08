defmodule Goal do
  @moduledoc ~S"""
  Goal is a parameter validation library based on [Ecto](https://github.com/elixir-ecto/ecto).
  It can be used with JSON APIs, HTML controllers and LiveViews.

  Goal builds a changeset from a validation schema and controller or LiveView parameters, and
  returns the validated parameters or an `Ecto.Changeset`, depending on the function you use.

  If your frontend and backend use different parameter cases, you can recase parameter keys with
  the `:recase_keys` option. `PascalCase`, `camelCase`, `kebab-case` and `snake_case` are
  supported.

  You can configure your own regexes for password, email, and URL format validations. This is
  helpful in case of backward compatibility, where Goal's defaults might not match your production
  system's behavior.

  ## Installation

  Add `goal` to the list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:goal, "~> 0.2"}
    ]
  end
  ```

  ## Examples

  Goal can be used with LiveViews and JSON and HTML controllers.

  ### Example with controllers

  With JSON and HTML-based APIs, Goal takes the `params` from a controller action, validates those
  against a validation schema using `validate/3`, and returns an atom-based map or an error
  changeset.

  ```elixir
  defmodule MyApp.SomeController do
    use MyApp, :controller
    use Goal

    def create(conn, params) do
      with {:ok, attrs} <- validate(:create, params)) do
        ...
      else
        {:error, changeset} -> {:error, changeset}
      end
    end

    defparams :create do
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
  ```

  ### Example with LiveViews

  With LiveViews, Goal builds a changeset in `mount/3` that is assigned in the socket, and then it
  takes the `params` from `handle_event/3`, validates those against a validation schema, and
  returns an atom-based map or an error changeset.

  ```elixir
  defmodule MyApp.SomeLiveView do
    use MyApp, :live_view
    use Goal

    def mount(params, _session, socket) do
      changeset = changeset(:new, %{})
      socket = assign(socket, :changeset, changeset)

      {:ok, socket}
    end

    def handle_event("validate", %{"some" => params}, socket) do
      changeset = changeset(:new, params)
      socket = assign(socket, :changeset, changeset)

      {:noreply, socket}
    end

    def handle_event("save", %{"some" => params}, socket) do
      with {:ok, attrs} <- validate(:new, params)) do
        ...
      else
        {:error, changeset} -> {:noreply, assign(socket, :changeset, changeset)}
      end
    end

    defparams :new do
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
  ```

  ### Example with isolated schemas

  Validation schemas can be defined in a separate namespace, for example `MyAppWeb.MySchema`:

  ```elixir
  defmodule MyAppWeb.MySchema do
    use Goal

    defparams :show do
      required :id, :string, format: :uuid
      optional :query, :string
    end
  end

  defmodule MyApp.SomeController do
    use MyApp, :controller

    alias MyAppWeb.MySchema

    def show(conn, params) do
      with {:ok, attrs} <- MySchema.validate(:show, params) do
        ...
      else
        {:error, changeset} -> {:error, changeset}
      end
    end
  end
  ```

  ## Features

  ### Deeply nested maps

  Goal efficiently builds error changesets for nested maps, and has support for lists of nested
  maps. There is no limitation on depth.

  ```elixir
  use Goal

  defparams do
    optional :nested_map, :map do
      required :id, :integer
      optional :inner_map, :map do
        required :id, :integer
        optional :map, :map do
          required :id, :integer
          optional :list, {:array, :integer}
        end
      end
    end
  end

  iex(1)> Goal.validate_params(schema(), params)
  {:ok, %{nested_map: %{inner_map: %{map: %{id: 123, list: [1, 2, 3]}}}}}
  ```

  ### Powerful array validations

  I you need expressive validations for arrays types, look no further!

  Arrays can be made optional/required or the number of items can be set via `min`, `max` and `is`.
  Additionally, `rules` allows specifying any validations that are available for the inner type.
  Of course, both can be combined:

  ```elixir
  use Goal

  defparams do
    required :my_list, {:array, :string}, max: 2, rules: [trim: true, min: 1]
  end

  iex(1)> Goal.validate_params(schema(), %{"my_list" => ["hello ", " world "]})
  {:ok, %{my_list: ["hello", "world"]}}
  ```

  ### Readable error messages

  Use `Goal.traverse_errors/2` to build readable errors. Phoenix by default uses
  `Ecto.Changeset.traverse_errors/2`, which works for embedded Ecto schemas but not for the plain
  nested maps used by Goal. Goal's `traverse_errors/2` is compatible with (embedded)
  `Ecto.Schema`, so you don't have to make any changes to your existing logic.

  ```elixir
  def translate_errors(changeset) do
    Goal.traverse_errors(changeset, &translate_error/1)
  end
  ```

  ### Recasing inbound keys

  By default, Goal will look for the keys defined in `defparams`. But sometimes frontend applications
  send parameters in a different format. For example, in `camelCase` but your backend uses
  `snake_case`. For this scenario, Goal has the `:recase_keys` option:

  ```elixir
  config :goal,
    recase_keys: [from: :camel_case]

  iex(1)> MySchema.validate(:show, %{"firstName" => "Jane"})
  {:ok, %{first_name: "Jane"}}
  ```

  ### Recasing outbound keys

  Use `recase_keys/2` to recase outbound keys. For example, in your views:

  ```elixir
  config :goal,
    recase_keys: [to: :camel_case]

  defmodule MyAppWeb.UserJSON do
    import Goal

    def show(%{user: user}) do
      recase_keys(%{data: %{first_name: user.first_name}})
    end

    def error(%{changeset: changeset}) do
      recase_keys(%{errors: Goal.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  iex(1)> UserJSON.show(%{user: %{first_name: "Jane"}})
  %{data: %{firstName: "Jane"}}
  iex(2)> UserJSON.error(%Ecto.Changeset{errors: [first_name: {"can't be blank", [validation: :required]}]})
  %{errors: %{firstName: ["can't be blank"]}}
  ```

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

  ### Available validations

  The field types and available validations are:

  | Field type             | Validations                 | Description                                                                                          |
  | ---------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------- |
  | `:uuid`                | `:equals`                   | string value                                                                                         |
  | `:string`              | `:equals`                   | string value                                                                                         |
  |                        | `:is`                       | exact string length                                                                                  |
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
  | `{:array, inner_type}` | `:rules`                    | `inner_type` can be any basic type. `rules` supported all validations available for `inner_type`     |
  |                        | `:min`                      | minimum array length                                                                                 |
  |                        | `:max`                      | maximum array length                                                                                 |
  |                        | `:is`                       | exact array length                                                                                   |
  | More basic types       |                             | See [Ecto.Schema](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types) for the full list |

  The default basic type is `:string`. You don't have to define this field if you are using the
  basic syntax.

  All field types, excluding `:map` and `{:array, :map}`, can use `:equals`, `:subset`,
  `:included`, `:excluded` validations.

  ## Credits

  This library is based on [Ecto](https://github.com/elixir-ecto/ecto) and I had to copy and adapt
  `Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
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
      import Goal, only: [defparams: 1, defparams: 2, build_changeset: 2, recase_keys: 3]

      @typedoc false
      @type name :: atom() | binary()

      @typedoc false
      @type params :: map()

      @typedoc false
      @type cases :: :camel_case | :snake_case | :pascal_case | :kebab_case

      @typedoc false
      @type opts :: [recase_keys: [from: cases()]]

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
      @spec validate(name(), params(), opts()) :: {:ok, params()} | {:error, changeset()}
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
  @spec validate_params(schema(), params(), opts()) :: {:ok, params()} | {:error, changeset()}
  def validate_params(schema, params, opts \\ []) do
    params = recase_keys(schema, params, opts)

    schema
    |> build_changeset(params)
    |> Map.put(:action, :validate)
    |> case do
      %Changeset{valid?: true, changes: changes} -> {:ok, changes}
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

    {%{}, types}
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
      changeset
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

  @placeholder :inner
  defp reduce_and_validate_array_basic_fields(schema, type, field, params) do
    schema = %{@placeholder => [{:type, type} | schema]}

    Enum.reduce(params, {:valid, []}, fn params, {status, acc} ->
      changeset = build_changeset(schema, %{@placeholder => params})

      case {status, changeset} do
        {:valid, %Changeset{valid?: true, changes: %{@placeholder => inner_changes}}} ->
          {:valid, [inner_changes | acc]}

        {:valid, %Changeset{valid?: false, errors: errors}} ->
          # The implementation is "all or nothing", so even if there where successful
          # changes before, we reset them now since the whole changeset isn't valid.
          {:invalid, errors}

        {:invalid, %Changeset{valid?: false, errors: errors}} ->
          {:invalid, errors ++ acc}

        {:invalid, %Changeset{valid?: true}} ->
          {:invalid, acc}
      end
    end)
    |> case do
      {:invalid, errors} ->
        errors =
          errors
          |> Enum.uniq()
          |> Enum.map(fn {@placeholder, {msg, opts}} -> {field, {"item " <> msg, opts}} end)

        {:invalid, errors}

      other ->
        other
    end
  end

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
