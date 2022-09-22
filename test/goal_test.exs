defmodule GoalTest do
  use ExUnit.Case

  describe "validate_params/2" do
    test "valid example" do
      data = %{
        "required" => "required",
        "id" => "1",
        "uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
        "string" => "Jane",
        "is_string" => "Joly",
        "min_string" => "John",
        "max_string" => "Joe",
        "trimmed_string" => " human ",
        "squished_string" => " homo  sapien ",
        "integer" => 29,
        "less_than_integer" => 5,
        "greater_than_integer" => 9,
        "list" => ["1", "2"],
        "integer_list" => [1, 2],
        "boolean_list" => [true, false],
        "boolean" => true,
        "map" => %{
          "key" => "value"
        },
        "nested_map" => %{
          "key" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
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
        required: [required: true],
        id: [type: :integer],
        uuid: [type: :string, format: :uuid],
        string: [type: :string],
        is_string: [type: :string, is: 4],
        min_string: [type: :string, min: 2],
        max_string: [type: :string, max: 5],
        trimmed_string: [type: :string, trim: true],
        squished_string: [type: :string, squish: true],
        integer: [type: :integer],
        less_than_integer: [type: :integer, less_than: 10],
        greater_than_integer: [type: :integer, greater_than: 3],
        list: [type: :list],
        integer_list: [type: :list, inner_type: :integer],
        boolean_list: [type: :list, inner_type: :boolean],
        boolean: [type: :boolean],
        map: [type: :map],
        nested_map: [
          type: :map,
          properties: %{
            key: [type: :string, format: :uuid],
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
                  required: "required",
                  id: 1,
                  uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
                  string: "Jane",
                  is_string: "Joly",
                  min_string: "John",
                  max_string: "Joe",
                  trimmed_string: "human",
                  squished_string: "homo sapien",
                  integer: 29,
                  less_than_integer: 5,
                  greater_than_integer: 9,
                  list: ["1", "2"],
                  integer_list: [1, 2],
                  boolean_list: [true, false],
                  boolean: true,
                  map: %{
                    "key" => "value"
                  },
                  nested_map: %{
                    key: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
                    map: %{
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

    test "required: true" do
      schema = %{field: [required: true]}

      data_1 = %{"field" => "yes"}
      data_2 = %{}

      assert Goal.validate_params(data_1, schema) == {:ok, %{field: "yes"}}

      assert {:error, %Ecto.Changeset{errors: [field: _]}} = Goal.validate_params(data_2, schema)
    end

    test "equals: value" do
      schema = %{option: [equals: "value"]}

      data_1 = %{"option" => "value"}
      data_2 = %{"option" => "notvalue"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{option: "value"}}
      assert {:error, %Ecto.Changeset{errors: [option: _]}} = Goal.validate_params(data_2, schema)
    end

    test "string, min: 4" do
      schema = %{name: [type: :string, is: 4]}

      data_1 = %{"name" => "Jane"}
      data_2 = %{"name" => "Joe"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{name: "Jane"}}
      assert {:error, %Ecto.Changeset{errors: [name: _]}} = Goal.validate_params(data_2, schema)
    end

    test "string, min: 5" do
      schema = %{name: [type: :string, min: 5]}

      data_1 = %{"name" => "Jonathan"}
      data_2 = %{"name" => "Jane"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{name: "Jonathan"}}
      assert {:error, %Ecto.Changeset{errors: [name: _]}} = Goal.validate_params(data_2, schema)
    end

    test "string, max: 5" do
      schema = %{name: [type: :string, max: 5]}

      data_1 = %{"name" => "Jane"}
      data_2 = %{"name" => "Jonathan"}

      assert Goal.validate_params(data_1, schema) == {:ok, %{name: "Jane"}}
      assert {:error, %Ecto.Changeset{errors: [name: _]}} = Goal.validate_params(data_2, schema)
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

    test "map" do
      data = %{
        "map" => %{
          "string" => "hello",
          "integer" => 5
        }
      }

      schema = %{
        map: [
          type: :map,
          properties: %{
            string: [type: :string],
            integer: [type: :integer]
          }
        ]
      }

      assert Goal.validate_params(data, schema) ==
               {:ok,
                %{
                  map: %{
                    string: "hello",
                    integer: 5
                  }
                }}
    end

    test "invalid nested map" do
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

      data = %{
        "key_1" => 1,
        "map_1" => %{
          "key_2" => 1,
          "map_2" => %{
            "key_3" => 2
          }
        }
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

    test "mixed nested map" do
      data = %{
        "string_1" => "hello",
        "map_1" => %{
          "uuid_1" => "123",
          "string_2" => 1,
          "map_2" => %{
            "string_3" => "world",
            "string_4" => 2
          }
        }
      }

      schema = %{
        string_1: [type: :string],
        map_1: [
          type: :map,
          properties: %{
            uuid_1: [format: :uuid],
            string_2: [type: :string],
            map_2: [
              type: :map,
              properties: %{
                string_3: [type: :string],
                string_4: [type: :string]
              }
            ]
          }
        ]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Goal.validate_params(data, schema)

      assert errors_on(changeset) == %{
               map_1: %{
                 uuid_1: ["has invalid format"],
                 string_2: ["is invalid"],
                 map_2: %{
                   string_4: ["is invalid"]
                 }
               }
             }
    end

    test "list" do
      data = %{
        "list" => [
          "one",
          "two",
          "three"
        ]
      }

      schema = %{
        list: [type: :list, inner_type: :string]
      }

      assert Goal.validate_params(data, schema) == {:ok, %{list: ["one", "two", "three"]}}
    end

    test "invalid list" do
      data = %{
        "list" => [
          "one",
          "two",
          "three"
        ]
      }

      schema = %{
        list: [type: :list, inner_type: :integer]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Goal.validate_params(data, schema)

      assert errors_on(changeset) == %{list: ["is invalid"]}
    end

    test "list of undefined maps" do
      data = %{
        "list" => [
          %{"string" => "hello"},
          %{"string" => "world"}
        ]
      }

      schema = %{
        list: [type: :list, inner_type: :map]
      }

      assert Goal.validate_params(data, schema) ==
               {:ok, %{list: [%{"string" => "hello"}, %{"string" => "world"}]}}
    end

    test "list of maps" do
      data = %{
        "list" => [
          %{"string" => "hello", "integer" => 1},
          %{"string" => "world", "integer" => 2}
        ]
      }

      schema = %{
        list: [
          type: :list,
          inner_type: :map,
          properties: %{
            string: [type: :string],
            integer: [type: :integer]
          }
        ]
      }

      assert Goal.validate_params(data, schema) ==
               {:ok,
                %{
                  list: [
                    %{string: "hello", integer: 1},
                    %{string: "world", integer: 2}
                  ]
                }}
    end

    test "list of invalid maps" do
      data = %{
        "list" => [
          %{"string" => 1, "integer" => "hello"},
          %{"string" => 2, "integer" => "world"}
        ]
      }

      schema = %{
        list: [
          type: :list,
          inner_type: :map,
          properties: %{
            string: [format: :uuid],
            integer: [type: :integer]
          }
        ]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Goal.validate_params(data, schema)

      assert errors_on(changeset) == %{
               list: [
                 %{
                   string: ["is invalid"],
                   integer: ["is invalid"]
                 },
                 %{
                   string: ["is invalid"],
                   integer: ["is invalid"]
                 }
               ]
             }
    end

    test "list of nested maps" do
      data = %{
        "list" => [
          %{
            "string" => "hello",
            "integer" => 1,
            "map" => %{
              "string1" => "banana",
              "string2" => "man"
            }
          },
          %{
            "string" => "world",
            "integer" => 2,
            "map" => %{
              "string1" => "banana",
              "string2" => "man"
            }
          }
        ]
      }

      schema = %{
        list: [
          type: :list,
          inner_type: :map,
          properties: %{
            string: [type: :string],
            integer: [type: :integer],
            map: [
              type: :map,
              properties: %{
                string1: [type: :string],
                string2: [type: :string]
              }
            ]
          }
        ]
      }

      assert Goal.validate_params(data, schema) ==
               {:ok,
                %{
                  list: [
                    %{
                      string: "hello",
                      integer: 1,
                      map: %{
                        string1: "banana",
                        string2: "man"
                      }
                    },
                    %{
                      string: "world",
                      integer: 2,
                      map: %{
                        string1: "banana",
                        string2: "man"
                      }
                    }
                  ]
                }}
    end

    test "missing schema rules" do
      data = %{
        "string_1" => "world",
        "string_2" => "",
        "map_1" => %{
          "string_3" => "banana"
        }
      }

      schema = %{
        string_1: [type: :string]
      }

      assert Goal.validate_params(data, schema) == {:ok, %{string_1: "world"}}
    end

    test "missing data" do
      data = %{
        "string_1" => "world"
      }

      schema = %{
        string_1: [type: :string],
        string_2: [type: :string]
      }

      assert Goal.validate_params(data, schema) == {:ok, %{string_1: "world"}}
    end

    test "missing maps in data" do
      data = %{
        "string_1" => "world"
      }

      schema = %{
        string_1: [type: :string],
        string_2: [type: :string],
        map_1: [
          type: :map,
          properties: %{
            string_3: [type: :string],
            string_4: [type: :string]
          }
        ]
      }

      assert Goal.validate_params(data, schema) == {:ok, %{string_1: "world"}}
    end

    test "missing required data" do
      data = %{
        "string_1" => "world"
      }

      schema = %{
        string_1: [type: :string, required: true],
        string_2: [type: :string, required: true]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Goal.validate_params(data, schema)

      assert errors_on(changeset) == %{
               string_2: ["can't be blank"]
             }
    end

    test "missing required maps in data" do
      data = %{
        "string_1" => "world"
      }

      schema = %{
        string_1: [type: :string, required: true],
        string_2: [type: :string, required: true],
        map_1: [
          type: :map,
          properties: %{
            string_3: [type: :string],
            string_4: [type: :string]
          },
          required: true
        ]
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Goal.validate_params(data, schema)

      assert errors_on(changeset) == %{
               string_2: ["can't be blank"],
               map_1: ["can't be blank"]
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
