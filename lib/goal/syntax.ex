defmodule Goal.Syntax do
  @moduledoc """
  Goal.Syntax provides the `defschema` macro for defining validation schemas.

  ## Usage

  ```elixir
  import Goal.Syntax
  ```
  """

  @doc """
  A macro for defining validation schemas that are generated at compile-time.

  ```elixir
  import Goal.Syntax

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
