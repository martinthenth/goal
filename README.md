# Goal

A library for parsing and validating parameters. It takes the `params` received from an Phoenix controller action, validates them, and returns the params as an atom-based map. It's based on `ecto` (https://github.com/elixir-ecto/ecto), so every validation that you have for database fields can be applied in validating parameters.

> This library is in active development. You're free to use it, but for a stable version you should wait until it is published on Hex.pm.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `goal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:goal, "~> 0.1.0"}
  ]
end
```

## Usage

There are multiple patterns you can choose to validate parameters using `goal`.

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

`goal` has sensible defaults for string format validation. If you'd like to use your own regex, e.g. for validating email addresses or passwords, you can add your own regex in the configuration.

```elixir
# TODO: Example config
```

### Deeply nested maps

`goal` efficiently builds error changesets for nested maps. The only limitation on depth is your imagination (and computing resources).

```elixir
# TODO: Example with nested map
```

### Readable error messages

Use `Goal.Changeset.traverse_errors/2` to build readable errors. Ecto and Phoenix by default use `Ecto.Changeset.traverse_errors/2`. This works for embedded Ecto schemas, but not for nested maps.

```elixir
def translate_errors(changeset) do
  Goal.Changeset.traverse_errors(changeset, &translate_error/1)
end
```

### Available validations

Every validation that you have for database fields when using `ecto` can be applied in validating parameters.

- `required` fields
- `string` length validations (`min`, `max`, `is`)
- `string` format validations (`uuid`, `email`, `password`)
- `integer` value validations (`less_than`, `greater_than`, etc.)
- `list` validations
- `nested list` validations
- `map` validations
- `nested map` validations
- `enum` validations

## Roadmap

- [ ] Bring your own regex
- [ ] Convert incoming params from `camelCase` to `snake_case`
- [ ] ExDoc documentation
- [ ] Release v0.1.0 on Hex.pm

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/goal>.

## Credits

This library is based on `ecto` (https://github.com/elixir-ecto/ecto) and I had to copy and adapt `Ecto.Changeset.traverse_errors/2`. Thanks for making such an awesome library! 🙇
