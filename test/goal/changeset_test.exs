defmodule Goal.ChangesetTest do
  use ExUnit.Case

  import Goal.Helpers

  alias Goal.DemoSchema

  describe "traverse_errors/2" do
    test "missing required fields, doesn't break embedded schemas" do
      data = %{}
      changeset = DemoSchema.changeset(data)

      assert errors_on(changeset) == %{
               age: ["can't be blank"],
               embedded_demo: ["can't be blank"],
               name: ["can't be blank"]
             }
    end

    test "missing required embedded fields, doesn't break embedded schemas" do
      data = %{name: "Name", age: 65, embedded_demo: %{}}

      changeset = DemoSchema.changeset(data)

      assert errors_on(changeset) == %{
               embedded_demo: %{
                 age: ["can't be blank"],
                 name: ["can't be blank"]
               }
             }
    end
  end
end
