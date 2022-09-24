# Goal ⚽

A library for parsing and validating parameters. It takes the `params` (e.g. from an Phoenix controller action), validates them, and returns an atom-based map or an error changeset. It's based on [Ecto](https://github.com/elixir-ecto/ecto), so every validation that you have for database fields can be applied in validating parameters.

Goal is different from other validation libraries because of its syntax, it being Ecto-based, and it validates data using pure functions instead of building embedded `Ecto.Schema` in the background.

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

## Features

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

Goal efficiently builds error changesets for nested maps. The only limitation on depth is your imagination (and computing resources). If the schema is becoming too verbose, you could consider splitting up the schema into reusable components.

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
              list: [type: :list, inner_type: :integer]
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

### Available validations

Every validation that you have for database fields when using Ecto can be applied in validating parameters.

- `required` fields
- `string` length validations (`min`, `max`, `is`)
- `string` format validations (`uuid`, `email`, `password`)
- `integer` value validations (`less_than`, `greater_than`, etc.)
- `list` validations
- `map` validations
- `nested map` validations
- `enum` validations (`included`, `excluded`, `subset`)

## Roadmap

- [x] Bring your own regex
- [x] ExDoc documentation
- [ ] Basic syntax optimizations
- [ ] Macro for generating schemas using `optional` and `required` (like https://dry-rb.org/gems/dry-schema/1.10/)
- [ ] Release v0.1.0 on Hex.pm
- [ ] Convert incoming params from `camelCase` to `snake_case`

## Credits

This library is based on [Ecto](https://github.com/elixir-ecto/ecto) and I had to copy and adapt `Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
