# Goal ⚽

Goal is a parameter validation library based on [Ecto](https://github.com/elixir-ecto/ecto).
It can be used with JSON APIs, HTML controllers and LiveViews.

Goal builds a changeset from a validation schema and controller or LiveView parameters, and
returns the validated parameters or `Ecto.Changeset`, depending on the function you use.

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

### Example with isolated schema

Validation schemas can be defined in a separate namespace, for example `MyAppWeb.MySchema`:

```elixir
defmodule MyAppWeb.MySchema do
  use Goal

  defparams :show do
    required :id, :string, format: :uuid
    optional :query, :string
  end
end

iex(1)> MySchema.validate(:show, %{"id" => "f86b1460-c2dc-4b7f-a28b-e3f21f3ebe7b"})
{:ok, %{id: "f86b1460-c2dc-4b7f-a28b-e3f21f3ebe7b"}}
iex(2)> MySchema.changeset(:show, %{id: "f86b1460-c2dc-4b7f-a28b-e3f21f3ebe7b"})
%Ecto.Changeset{valid?: true, changes: %{id: "f86b1460-c2dc-4b7f-a28b-e3f21f3ebe7b"}}
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
    %{data: %{first_name: user.first_name}}
    |> recase_keys()
  end

  def error(%{changeset: changeset}) do
    errors =
      changeset
      |> Goal.Changeset.traverse_errors(&translate_error/1)
      |> recase_keys()

    %{errors: errors}
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
