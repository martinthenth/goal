# Goal ⚽

A library for parsing and validating parameters. It takes the `params` (e.g. from an Phoenix controller action), validates them, and returns an atom-based map or an error changeset. It's based on [Ecto](https://github.com/elixir-ecto/ecto), so every validation that you have for database fields can be applied in validating parameters.

Goal is different from other validation libraries because of its syntax, it being Ecto-based, and it validates data using pure functions instead of building embedded `Ecto.Schema` in the background.

Goal allows you to configure your own regexes. This is helpful in case of backward compatibility, where Goal's defaults might not match your production system's regexes.

## Installation

Add `goal` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:goal, "~> 0.1.0"}
  ]
end
```

## Usage

There are several patterns you can choose to validate parameters using Goal.

### Using module attributes

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

### Using private functions

```elixir
defmodule MyApp.SomeController do
  import Goal

  def create(conn, params) do
    with {:ok, attrs} <- validate_params(params, schema()) do
      ...
    end
  end

  defp schema do
    %{
      id: [format: :uuid, required: true],
      name: [min: 3, max: 20, required: true]
    }
  end
end
```

### Using the defschema Macro

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
      optional :age, :integer
    end
  end
end
```

## Features

### Defining validations

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

### Bring your own regex

Goal has sensible defaults for string format validation. If you'd like to use your own regex, e.g. for validating email addresses or passwords, you can add your own regex in the configuration.

```elixir
config :goal,
  uuid_regex: ~r/^[[:alpha:]]+$/,
  email_regex: ~r/^[[:alpha:]]+$/,
  password_regex: ~r/^[[:alpha:]]+$/,
  url_regex: ~r/^[[:alpha:]]+$/
```

### Deeply nested maps

Goal efficiently builds error changesets for nested maps. There is no limitation on depth. If the schema is becoming too verbose, you could consider splitting up the schema into reusable components.

```elixir
data = %{
  "nested_map" => %{
    "map" => %{
      "inner_map" => %{
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
              list: [type: {:array, :integer}]
            }
          ]
        }
      ]
    }
  ]
}

iex(1)> data = %{...}
iex(2)> schema = %{...}
iex(3)> Goal.validate_params(data, schema)
{:ok, %{nested_map: %{inner_map: %{map: %{list: [1, 2, 3]}}}}}
```

### Human-readable error messages

Use `Goal.traverse_errors/2` to build readable errors. Ecto and Phoenix by default use `Ecto.Changeset.traverse_errors/2`, which works for embedded Ecto schemas but not for the plain nested maps used by Goal.

```elixir
def translate_errors(changeset) do
  Goal.traverse_errors(changeset, &translate_error/1)
end
```

## Roadmap

- [x] Bring your own regex
- [x] ExDoc documentation
- [x] Basic syntax optimizations
- [ ] Macro for generating schemas using `optional` and `required` (like https://dry-rb.org/gems/dry-schema/1.10/)
- [ ] Release v0.1.0 on Hex.pm
- [ ] Convert incoming params from `camelCase` to `snake_case`

## Credits

This library is based on [Ecto](https://github.com/elixir-ecto/ecto) and I had to copy and adapt `Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
