defmodule GoalTest do
  use ExUnit.Case

  describe "validate_params/2" do
    test "valid example" do
      data = %{
        "id" => "1",
        "uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
        "string" => "Jane",
        "trimmed_string" => " human ",
        "squished_string" => " homo  sapien ",
        "integer" => 29,
        "min_integer" => 5,
        "max_integer" => 9,
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
        "email" => "jane.doe@example.com",
        "password" => "password123",
        "url" => "https://www.example.com",
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
        min_integer: [type: :integer, min: 3],
        max_integer: [type: :integer, min: 10],
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
        url: [type: :string, format: :url],
        enum: [type: :enum, values: ["male", "female", "non-binary"]]
      }

      assert Goal.validate_params(data, schema) ==
               {:ok,
                %{
                  id: 1,
                  uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
                  string: "Jane",
                  trimmed_string: "human",
                  squished_string: "homo sapien",
                  integer: 29,
                  max_integer: 9,
                  min_integer: 5,
                  list: ["1", "2"],
                  integer_list: [1, 2],
                  boolean_list: [true, false],
                  boolean: true,
                  map: %{
                    "key" => "value"
                  },
                  nested_map: %{
                    "key" => "value",
                    "map" => %{
                      "key" => "value"
                    }
                  },
                  float: 60.5,
                  decimal: Decimal.from_float(100.04),
                  email: "jane.doe@example.com",
                  password: "password123",
                  url: "https://www.example.com",
                  enum: :female
                }}
    end

    test "string, trim: true" do
      schema = %{name: [type: :string, trim: true]}

      data_1 = %{"name" => " quantum physics "}
      data_2 = %{"name" => " quantum  physics "}

      assert Goal.validate_params(data_1, schema) == {:ok, %{name: "quantum physics"}}
      assert Goal.validate_params(data_2, schema) == {:ok, %{name: "quantum  physics"}}
    end

    test "string, trim: false" do
      schema = %{name: [type: :string, trim: false]}

      data_1 = %{"name" => " quantum physics "}
      data_2 = %{"name" => " quantum  physics "}

      assert Goal.validate_params(data_1, schema) == {:ok, %{name: " quantum physics "}}
      assert Goal.validate_params(data_2, schema) == {:ok, %{name: " quantum  physics "}}
    end

    test "string, squish: true" do
      schema = %{name: [type: :string, squish: true]}

      data = %{"name" => " banana   man "}

      assert Goal.validate_params(data, schema) == {:ok, %{name: "banana man"}}
    end

    test "string, squish: false" do
      schema = %{name: [type: :string, squish: false]}

      data = %{"name" => " banana   man "}

      assert Goal.validate_params(data, schema) == {:ok, %{name: " banana   man "}}
    end

    test "string, format: :uuid" do
      schema = %{uuid: [type: :string, format: :uuid]}

      data_1 = %{"uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e"}
      data_2 = %{"uuid" => "notuuid"}

      assert Goal.validate_params(data_1, schema) ==
               {:ok, %{uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e"}}

      assert {:error, %Ecto.Changeset{errors: [uuid: _]}} = Goal.validate_params(data_2, schema)
    end

    test "string, format: :email" do
      schema = %{email: [type: :string, format: :email]}

      data_1 = %{"email" => "jane.doe@example.com"}
      data_2 = %{"email" => "notemail"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{email: "jane.doe@example.com"}}

      assert {:error, %Ecto.Changeset{errors: [email: _]}} = Goal.validate_params(data_2, schema)
    end

    test "string, format: :password" do
      schema = %{password: [type: :string, format: :password]}

      data_1 = %{"password" => "password123"}
      data_2 = %{"password" => "pass"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{password: "password123"}}

      assert {:error, %Ecto.Changeset{errors: [password: _]}} =
               Goal.validate_params(data_2, schema)
    end

    test "string, format: :url" do
      schema = %{url: [type: :string, format: :url]}

      data_1 = %{"url" => "https://www.example.com"}
      data_2 = %{"url" => "website"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{url: "https://www.example.com"}}

      assert {:error, %Ecto.Changeset{errors: [url: _]}} = Goal.validate_params(data_2, schema)
    end

    test "integer, less_than: 10" do
      schema = %{age: [type: :integer, less_than: 11]}

      data_1 = %{"age" => 9}
      data_2 = %{"age" => 11}

      assert Goal.validate_params(data_1, schema) == {:ok, %{age: 9}}

      assert {:error, %Ecto.Changeset{errors: [age: _]}} = Goal.validate_params(data_2, schema)
    end

    test "integer, greater_than: 5" do
      schema = %{age: [type: :integer, greater_than: 5]}

      data_1 = %{"age" => 6}
      data_2 = %{"age" => 4}

      assert Goal.validate_params(data_1, schema) == {:ok, %{age: 6}}

      assert {:error, %Ecto.Changeset{errors: [age: _]}} = Goal.validate_params(data_2, schema)
    end

    test "integer, less_than_or_equal_to: 5" do
      schema = %{age: [type: :integer, less_than_or_equal_to: 5]}

      data_1 = %{"age" => 5}
      data_2 = %{"age" => 4}
      data_3 = %{"age" => 6}

      assert Goal.validate_params(data_1, schema) == {:ok, %{age: 5}}
      assert Goal.validate_params(data_2, schema) == {:ok, %{age: 4}}
      assert {:error, %Ecto.Changeset{errors: [age: _]}} = Goal.validate_params(data_3, schema)
    end

    test "integer, greater_than_or_equal_to: 10" do
      schema = %{age: [type: :integer, greater_than_or_equal_to: 11]}

      data_1 = %{"age" => 11}
      data_2 = %{"age" => 12}
      data_3 = %{"age" => 9}

      assert Goal.validate_params(data_1, schema) == {:ok, %{age: 11}}
      assert Goal.validate_params(data_2, schema) == {:ok, %{age: 12}}
      assert {:error, %Ecto.Changeset{errors: [age: _]}} = Goal.validate_params(data_3, schema)
    end

    test "integer, equal_to: 5" do
      schema = %{age: [type: :integer, equal_to: 5]}

      data_1 = %{"age" => 5}
      data_2 = %{"age" => 4}

      assert Goal.validate_params(data_1, schema) == {:ok, %{age: 5}}

      assert {:error, %Ecto.Changeset{errors: [age: _]}} = Goal.validate_params(data_2, schema)
    end

    test "integer, not_equal_to: 10" do
      schema = %{age: [type: :integer, not_equal_to: 11]}

      data_1 = %{"age" => 9}
      data_2 = %{"age" => 11}

      assert Goal.validate_params(data_1, schema) == {:ok, %{age: 9}}

      assert {:error, %Ecto.Changeset{errors: [age: _]}} = Goal.validate_params(data_2, schema)
    end

    test "invalid nested map" do
      data = %{
        "key_1" => 1,
        "map_1" => %{
          "key_2" => 1,
          "map_2" => %{
            "key_3" => 2
          }
        }
      }

      schema = %{
        key_1: [type: :string],
        map_1: [
          type: :map,
          properties: %{
            key_2: [type: :string],
            map_2: [
              type: :map,
              properties: %{
                key_3: [type: :string]
              }
            ]
          }
        ]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Goal.validate_params(data, schema)

      assert errors_on(changeset) == %{
               key_1: ["is invalid"],
               map_1: %{
                 key_2: ["is invalid"],
                 map_2: %{
                   key_3: ["is invalid"]
                 }
               }
             }
    end
  end

  defp errors_on(changeset) do
    Goal.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _map, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
