defmodule Goal.Syntax do
  @moduledoc """
  Goal.Syntax provides the `defschema` macro to define schemas.

  ## Usage

  ```elixir
  import Goal.Syntax
  ```
  """

  @doc """
  Transforms the schema into a validation schema.

  ```elixir
  import Goal.Syntax

  defp schema do
    defschema do
      required :id, :string, format: :uuid
      required :name, :string
      optional :age, :integer, min: 0, max: 120
      optional :gender, :enum, values: ["female", "male", "non-binary"]
    end
  end
  ```
  """
  @spec defschema(do: {:__block__, any, any}) :: any
  defmacro defschema(do: block) do
    block
    |> generate_schema()
    |> Macro.escape()
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
end
