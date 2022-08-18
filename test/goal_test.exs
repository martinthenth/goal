defmodule GoalTest do
  use ExUnit.Case

  describe "validate/2" do
    test "example" do
      data = %{
        "id" => "1",
        "uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
        "string" => "Daisy",
        "trimmed_string" => " human ",
        "squished_string" => " homo  sapien ",
        "integer" => 29,
        "list" => ["1", "2"],
        "integer_list" => [1, 2],
        "boolean_list" => [true, false],
        "boolean" => true,
        "map" => %{
          "key" => "value"
        },
        "nested_map" => %{
          "key" => "value",
          "map" => %{
            "key" => "value"
          }
        },
        "float" => 60.5,
        "decimal" => 100.04,
        "email" => "daisy.doe@example.com",
        "password" => "password123",
        "enum" => "female",
        "other" => "not in schema"
      }

      schema = %{
        id: [type: :integer],
        uuid: [type: :string, format: :uuid],
        string: [type: :string],
        trimmed_string: [type: :string, trim: true],
        squished_string: [type: :string, squish: true],
        integer: [type: :integer],
        list: [type: :list],
        integer_list: [type: :list, inner_type: :integer],
        boolean_list: [type: :list, inner_type: :boolean],
        boolean: [type: :boolean],
        map: [type: :map],
        nested_map: [
          type: :map,
          properties: %{
            key: [type: :string],
            map: [type: :map]
          }
        ],
        float: [type: :float],
        decimal: [type: :decimal],
        email: [type: :string, format: :email],
        password: [type: :string, format: :password],
        enum: [type: :enum, values: ["male", "female", "non-binary"]]
      }

      assert Goal.validate(data, schema) ==
               {:ok,
                %{
                  id: 1,
                  uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
                  string: "Daisy",
                  trimmed_string: "human",
                  squished_string: "homo sapien",
                  integer: 29,
                  list: ["1", "2"],
                  integer_list: [1, 2],
                  boolean_list: [true, false],
                  boolean: true,
                  map: %{
                    "key" => "value"
                  },
                  nested_map: %{
                    key: "value",
                    map: %{
                      key: "value"
                    }
                  },
                  float: 60.5,
                  decimal: Decimal.from_float(100.04),
                  email: "daisy.doe@example.com",
                  password: "password123",
                  enum: :female
                }}
    end
  end
end
