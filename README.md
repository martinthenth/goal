# Goal ⚽

A library for parsing and validating parameters. Goal takes the `params` (e.g. from an Phoenix controller), validates them against a schema, and returns an atom-based map or an error changeset. It's based on [Ecto](https://github.com/elixir-ecto/ecto), so every validation that you have for database fields can be applied in validating parameters.

Goal is different from other validation libraries because of its syntax, being Ecto-based, and validating data using functions from `Ecto.Changeset` instead of building embedded `Ecto.Schema`s in the background.

Additionally, Goal allows you to configure your own regexes. This is helpful in case of backward compatibility, where Goal's defaults might not match your production system's behavior.

## Installation

Add `goal` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:goal, "~> 0.1.1"}
  ]
end
```

## Usage

Goal's entry point is `Goal.validate_params/2`, which receives the parameters and a validation schema. The parameters must be a map, and can be string-based or atom-based. Goal needs a validation schema (also a map) to parse and validate the parameters. You can build one with the `defschema` macro:

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

The `defschema` macro converts the given structure into a validation schema at compile-time. You can also use the basic syntax like in the example below. The basic syntax is what `defschema` compiles to.

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

Goal has sensible defaults for string format validation. If you'd like to use your own regex, e.g. for validating email addresses or passwords, then you can add your own regex in the configuration:

```elixir
config :goal,
  uuid_regex: ~r/^[[:alpha:]]+$/,
  email_regex: ~r/^[[:alpha:]]+$/,
  password_regex: ~r/^[[:alpha:]]+$/,
  url_regex: ~r/^[[:alpha:]]+$/
```

### Deeply nested maps

Goal efficiently builds error changesets for nested maps, and has support for lists of nested maps. There is no limitation on depth.

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

Use `Goal.traverse_errors/2` to build readable errors. Phoenix by default uses `Ecto.Changeset.traverse_errors/2`, which works for embedded Ecto schemas but not for the plain nested maps used by Goal. Goal's `traverse_errors/2` is compatible with (embedded) `Ecto.Schema`s, so you don't have to make any changes to your existing logic.

```elixir
def translate_errors(changeset) do
  Goal.traverse_errors(changeset, &translate_error/1)
end
```

### Available validations

The field types and available validations are:

| Field type             | Validations                 | Description                                                                                          |
| ---------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------- |
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

The default basic type is `:string`. You don't have to define this field if you are using the basic syntax.

All field types, exluding `:map` and `{:array, :map}`, can use `:equals`, `:subset`, `:included`, `:excluded` validations.

## Roadmap

- [x] Bring your own regex
- [x] ExDoc documentation
- [x] Basic syntax optimizations
- [x] Macro for generating schemas without boilerplate
- [x] Release v0.1.0 on Hex.pm
- [ ] Convert incoming params from `camelCase` to `snake_case`

## Credits

This library is based on [Ecto](https://github.com/elixir-ecto/ecto) and I had to copy and adapt `Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
