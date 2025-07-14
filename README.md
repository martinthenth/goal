# A maintained fork of [Goal](https://github.com/martinthenth/goal) with extra functionality

[![CI](https://github.com/mtanca/goal/actions/workflows/elixir.yml/badge.svg)](https://github.com/mtanca/goal/actions/workflows/elixir.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/m_goal)](https://hex.pm/packages/m_goal)
[![Hex.pm](https://img.shields.io/hexpm/dt/m_goal)](https://hex.pm/packages/m_goal)
[![Hex.pm](https://img.shields.io/hexpm/l/m_goal)](https://github.com/mtanca/m_goal/blob/main/LICENSE)

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

Add `m_goal` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:m_goal, "~> 1.2.2"}]
end
```

## Examples

Goal can be used with LiveViews and JSON and HTML controllers.

### Example with JSON and HTTP controllers

With JSON and HTML-based APIs, Goal takes the `params` from a controller action, validates those
against a validation schema using `validate/3`, and returns an atom-based map or an error
changeset.

```elixir
defmodule AppWeb.SomeController do
  use AppWeb, :controller
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
    optional :hobbies, {:array, :string}, max: 3, rules: [trim: true, min: 1]

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
defmodule AppWeb.SomeLiveView do
  use AppWeb, :live_view
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
    optional :hobbies, {:array, :string}, max: 3, rules: [trim: true, min: 1]

    optional :data, :map do
      required :color, :string
      optional :money, :decimal
      optional :height, :float
    end
  end
end
```

### Example with GraphQL resolvers

With GraphQL, you may want to validate input fields without marking them as `non-null` to enhance
backward compatibility. You can use Goal inside GraphQL resolvers to validate the input fields:

```elixir
defmodule AppWeb.MyResolver do
  use Goal

  defparams(:create_user) do
    required(:id, :uuid)
    required(:input, :map) do
      required(:first_name, :string)
      required(:last_name, :string)
    end
  end

  def create_user(args, info) do
    with {:ok, attrs} <- validate(:create_user) do
      ...
    end
  end
end
```

### Example with isolated schemas

Validation schemas can be defined in a separate namespace, for example `AppWeb.MySchema`:

```elixir
defmodule AppWeb.MySchema do
  use Goal

  defparams :show do
    required :id, :string, format: :uuid
    optional :query, :string
  end
end

defmodule AppWeb.SomeController do
  use AppWeb, :controller

  alias AppWeb.MySchema

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

### Presence checks

Sometimes all you need is to check if a parameter is present:

```elixir
use Goal

defparams :show do
  required :id
  optional :query
end
```

### Deeply nested maps

Goal efficiently builds error changesets for nested maps, and has support for lists of nested
maps. There is no limitation on depth.

```elixir
use Goal

defparams :show do
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

iex(1)> validate(:show, params)
{:ok, %{nested_map: %{inner_map: %{map: %{id: 123, list: [1, 2, 3]}}}}}
```

### Powerful array validations

If you need expressive validations for arrays types, look no further!

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

defmodule AppWeb.UserJSON do
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

### Flexible key aliases

Goal allows you to map the value of an aliased key within a payload to a given field:

```elixir
use Goal

defparams :message_confirmation_webhook do
  required(:message_provider_id, :string, key_aliases: ["twilio_id", "podium_id", "sengrid_id"])
  required(:delivered_at, :string, key_aliases: ["sent_at", "timestamp", "confirmed_at"])
end

iex(1)> MySchema.validate(:message_confirmation_webhook, %{"sengrid_id" => "1234", "timestamp" => "2024-11-01T14:00:00Z"})
{:ok, %{message_provider_id: "1234", delivered_at: "2024-11-01T14:00:00Z"}}
```

### Available options

The field types and available options are:

| Field type             | Validations                 | Description                                                                                          |
| ---------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------- |
| `:uuid`                | `:equals`                   | string value                                                                                         |
| `:string`              | `:equals`                   | string value                                                                                         |
|                        | `:is`                       | exact string length                                                                                  |
|                        | `:min`                      | minimum string length                                                                                |
|                        | `:max`                      | maximum string length                                                                                |
|                        | `:trim`                     | boolean to remove leading and trailing spaces                                                        |
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
| Custom validations     | `:custom`                   | expects a function taking a field name, params map, and a changeset, returning a changeset           |
| Key aliases            | `:key_aliases`              | maps the value of any aliased key in a payload to a given field. expects a list of aliases           |

All field types, excluding `:map` and `{:array, :map}`, can use `:equals`, `:subset`,
`:included`, `:excluded` validations.



## Credits

This library is based on [Ecto](https://github.com/elixir-ecto/ecto) and I had to copy and adapt
`Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
