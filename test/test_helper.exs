ExUnit.start()

defmodule Goal.Helpers do
  def changes_on(%Ecto.Changeset{valid?: true} = changeset), do: changeset.changes

  def errors_on(%Ecto.Changeset{valid?: false} = changeset) do
    Goal.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _map, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

defmodule Goal.DemoSchema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Goal.EmbeddedDemoSchema

  schema "demo" do
    field(:name, :string)
    field(:age, :integer)

    embeds_one(:embedded_demo, EmbeddedDemoSchema)

    timestamps()
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name, :age])
    |> cast_embed(:embedded_demo)
    |> validate_required([:name, :age, :embedded_demo])
  end
end

defmodule Goal.EmbeddedDemoSchema do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:name, :string)
    field(:age, :integer)

    timestamps()
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
  end
end
