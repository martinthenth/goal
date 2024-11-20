defmodule GoalTest do
  use ExUnit.Case
  use Goal

  import Goal.Helpers

  @statuses [:draft, :pending, :done]

  defparams do
    required(:id, :integer)
  end

  defparams :show do
    required(:id, :integer)
    optional(:user_id, :integer)
    optional(:first_name, :string)
    optional(:last_name, :string)
    required(:any_1)
    optional(:any_2)
    optional(:fields1, :map)
    required(:fields2, :map)
    optional(:fields3, {:array, :map})
    required(:fields4, {:array, :map})
  end

  defparams :negatives do
    optional(:a, :integer, min: -1)
    required(:b, :integer, min: -5, max: -1)
    required(:c, :float, min: -14.0, max: 7)
    optional(:d, :decimal, min: Decimal.new(-3), max: Decimal.new(-1))
  end

  defparams :index do
    required(:id, :integer)
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string, squish: true)
    optional(:age, :integer, min: 0, max: 120)
    optional(:gender, :enum, values: ["female", "male", "non-binary"])
    optional(:status, :enum, values: @statuses)
    optional(:hash, :string, format: :hash)

    required :car, :map do
      optional(:name, :string, min: 3, max: 20)
      optional(:brand, :string, included: ["Mercedes", "GMC"])

      required :stats, :map do
        optional(:age, :integer)
        optional(:mileage, :float)
        optional(:color, :string, excluded: ["camo"])
      end

      optional(:deleted, :boolean)
    end

    required :dogs, {:array, :map} do
      optional(:name, :string)
      optional(:age, :integer)
      optional(:type, :string)

      required :data, :map do
        optional(:paws, :integer)
      end
    end
  end

  defparams :enums do
    optional(:status, :enum, values: @statuses)
  end

  describe "__using__/1" do
    test "schema/0" do
      assert schema() == %{id: [type: :integer, required: true]}
    end

    test "schema/1 negatives" do
      assert schema(:negatives) == %{
               a: [type: :integer, min: -1],
               b: [type: :integer, required: true, min: -5, max: -1],
               c: [type: :float, required: true, min: -14.0, max: 7],
               d: [type: :decimal, min: Decimal.new(-3), max: Decimal.new(-1)]
             }
    end

    test "schema/1 enums" do
      assert schema(:enums) == %{
               status: [type: :enum, values: [:draft, :pending, :done]]
             }
    end

    test "schema/1" do
      assert schema(:show) == %{
               id: [type: :integer, required: true],
               user_id: [type: :integer],
               first_name: [type: :string],
               last_name: [type: :string],
               any_1: [type: :any, required: true],
               any_2: [type: :any],
               fields1: [type: :map],
               fields2: [type: :map, required: true],
               fields3: [type: {:array, :map}],
               fields4: [type: {:array, :map}, required: true]
             }

      assert schema(:index) == %{
               id: [type: :integer, required: true],
               uuid: [type: :string, required: true, format: :uuid],
               name: [type: :string, required: true, min: 3, max: 20],
               type: [type: :string, squish: true],
               age: [type: :integer, min: 0, max: 120],
               gender: [type: :enum, values: ["female", "male", "non-binary"]],
               status: [type: :enum, values: [:draft, :pending, :done]],
               hash: [type: :string, format: :hash],
               car: [
                 type: :map,
                 required: true,
                 properties: %{
                   name: [type: :string, min: 3, max: 20],
                   brand: [type: :string, included: ["Mercedes", "GMC"]],
                   stats: [
                     type: :map,
                     required: true,
                     properties: %{
                       age: [type: :integer],
                       mileage: [type: :float],
                       color: [type: :string, excluded: ["camo"]]
                     }
                   ],
                   deleted: [type: :boolean]
                 }
               ],
               dogs: [
                 type: {:array, :map},
                 required: true,
                 properties: %{
                   name: [type: :string],
                   age: [type: :integer],
                   type: [type: :string],
                   data: [
                     type: :map,
                     required: true,
                     properties: %{
                       paws: [type: :integer]
                     }
                   ]
                 }
               ]
             }
    end

    test "changeset/1" do
      assert %Ecto.Changeset{
               action: nil,
               changes: %{},
               errors: [
                 fields4: {"can't be blank", [validation: :required]},
                 fields2: {"can't be blank", [validation: :required]},
                 any_1: {"can't be blank", [validation: :required]},
                 id: {"can't be blank", [validation: :required]}
               ],
               data: %{},
               valid?: false
             } = changeset(:show)
    end

    test "changeset/2" do
      assert %Ecto.Changeset{
               action: nil,
               changes: %{
                 id: 123,
                 any_1: 123,
                 fields2: %{"hello" => "world"},
                 fields4: [%{"bye" => "world"}]
               },
               errors: [],
               data: %{},
               valid?: true
             } =
               changeset(:show, %{
                 id: 123,
                 any_1: 123,
                 fields2: %{"hello" => "world"},
                 fields4: [%{"bye" => "world"}]
               })

      assert %Ecto.Changeset{
               action: nil,
               changes: %{},
               errors: [
                 fields4: {"can't be blank", [validation: :required]},
                 fields2: {"can't be blank", [validation: :required]},
                 any_1: {"can't be blank", [validation: :required]},
                 id: {"can't be blank", [validation: :required]}
               ],
               data: %{},
               valid?: false
             } = changeset(:show, %{})
    end

    test "changeset/3" do
      assert %Ecto.Changeset{
               action: nil,
               changes: %{},
               errors: [],
               data: %{},
               valid?: true
             } =
               changeset(
                 :show,
                 %{
                   id: 123,
                   any_1: 123,
                   firstName: "Joan",
                   lastName: "Of Arc",
                   fields2: %{"hello" => "world"},
                   fields4: [%{"bye" => "world"}]
                 },
                 recase_keys: [from: :camel_case]
               )
    end

    test "validate/3" do
      assert validate(:show, %{
               id: 123,
               any_1: 123,
               fields2: %{"hello" => "world"},
               fields4: [%{"bye" => "world"}]
             }) ==
               {:ok,
                %{
                  id: 123,
                  any_1: 123,
                  fields2: %{"hello" => "world"},
                  fields4: [%{"bye" => "world"}]
                }}

      assert {:error,
              %Ecto.Changeset{
                action: :validate,
                changes: %{},
                errors: [
                  fields4: {"can't be blank", [validation: :required]},
                  fields2: {"can't be blank", [validation: :required]},
                  any_1: {"can't be blank", [validation: :required]},
                  id: {"can't be blank", [validation: :required]}
                ],
                data: %{},
                valid?: false
              }} = validate(:show, %{})

      assert validate(
               :show,
               %{
                 id: 123,
                 firstName: "Jane",
                 lastName: "Doe",
                 any1: 123,
                 fields2: %{"hello" => "world"},
                 fields4: [%{"bye" => "world"}]
               },
               recase_keys: [from: :camel_case]
             ) ==
               {:ok,
                %{
                  id: 123,
                  first_name: "Jane",
                  last_name: "Doe",
                  any_1: 123,
                  fields2: %{"hello" => "world"},
                  fields4: [%{"bye" => "world"}]
                }}

      assert validate(
               :show,
               %{
                 id: 123,
                 user_id: 123,
                 any_1: 123,
                 fields2: %{"hello" => "world"},
                 fields4: [%{"bye" => "world"}]
               },
               recase_keys: [from: :camel_case]
             ) ==
               {:ok,
                %{
                  id: 123,
                  user_id: 123,
                  any_1: 123,
                  fields2: %{"hello" => "world"},
                  fields4: [%{"bye" => "world"}]
                }}
    end
  end

  describe "validate_params/3" do
    test "valid params" do
      schema = %{name: [type: :string, is: 4]}
      data = %{"name" => "Jane"}

      assert Goal.validate_params(schema, data) == {:ok, %{name: "Jane"}}
    end

    test "invalid params" do
      schema = %{name: [type: :string, is: 4]}
      data = %{"name" => "Joe"}

      assert {:error, changeset} = Goal.validate_params(schema, data)
      assert errors_on(changeset) == %{name: ["should be 4 character(s)"]}
    end

    test "recase params" do
      schema = %{first_name: [type: :string], last_name: [type: :string]}
      data = %{"firstName" => "Jane", "lastName" => "Doe"}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.validate_params(schema, data, opts) ==
               {:ok, %{first_name: "Jane", last_name: "Doe"}}
    end

    test "recase params falls back to defined keys" do
      schema = %{user_id: [type: :integer], first_name: [type: :string]}
      data = %{"user_id" => 123, "firstName" => "Jane"}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.validate_params(schema, data, opts) ==
               {:ok, %{user_id: 123, first_name: "Jane"}}
    end

    test "includes empty values when they were given" do
      schema = %{timestamp: [type: :utc_datetime]}
      params = %{"timestamp" => nil}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.validate_params(schema, params, opts) == {:ok, %{timestamp: nil}}
    end

    test "excludes empty values when they were not given" do
      schema = %{name: [type: :string]}
      params = %{}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.validate_params(schema, params, opts) == {:ok, %{}}
    end
  end

  describe "build_changeset/2" do
    test "valid example" do
      data = %{
        "required" => "required",
        "id" => "1",
        "uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
        "format_uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
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
        uuid: [type: :uuid],
        format_uuid: [type: :string, format: :uuid],
        string: [type: :string],
        is_string: [type: :string, is: 4],
        min_string: [type: :string, min: 2],
        max_string: [type: :string, max: 5],
        trimmed_string: [type: :string, trim: true],
        squished_string: [type: :string, squish: true],
        integer: [type: :integer],
        less_than_integer: [type: :integer, less_than: 10],
        greater_than_integer: [type: :integer, greater_than: 3],
        list: [type: {:array, :string}],
        integer_list: [type: {:array, :integer}],
        boolean_list: [type: {:array, :boolean}],
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

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
               required: "required",
               id: 1,
               uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
               format_uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
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
             }
    end

    test "required: true" do
      schema = %{field: [required: true]}

      data_1 = %{"field" => "yes"}
      data_2 = %{}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{field: "yes"}
      assert errors_on(changeset_2) == %{field: ["can't be blank"]}
    end

    test "equals: value" do
      schema = %{option: [equals: "value"]}

      data_1 = %{"option" => "value"}
      data_2 = %{"option" => "notvalue"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{option: "value"}
      assert errors_on(changeset_2) == %{option: ["is invalid"]}
    end

    test "excluded: values" do
      schema = %{car: [excluded: ["mercedes", "audi"]]}

      data_1 = %{"car" => "ford"}
      data_2 = %{"car" => "mercedes"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{car: "ford"}
      assert errors_on(changeset_2) == %{car: ["is reserved"]}
    end

    test "included: values" do
      schema = %{car: [included: ["mercedes", "audi"]]}

      data_1 = %{"car" => "mercedes"}
      data_2 = %{"car" => "ford"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{car: "mercedes"}
      assert errors_on(changeset_2) == %{car: ["is invalid"]}
    end

    test "subset: values" do
      schema = %{integers: [type: {:array, :integer}, subset: [1, 2, 3]]}

      data_1 = %{"integers" => [1, 2, 3]}
      data_2 = %{"integers" => [4, 5, 6]}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{integers: [1, 2, 3]}
      assert errors_on(changeset_2) == %{integers: ["has an invalid entry"]}
    end

    test "any" do
      schema = %{any: [type: :any]}

      params_1 = %{"any" => "hello-world"}
      params_2 = %{"any" => 123}

      changeset_1 = Goal.build_changeset(schema, params_1)
      changeset_2 = Goal.build_changeset(schema, params_2)

      assert changes_on(changeset_1) == %{any: "hello-world"}
      assert changes_on(changeset_2) == %{any: 123}
    end

    test "uuid" do
      schema = %{uuid: [type: :uuid]}

      data_1 = %{"uuid" => "9d98baf6-3cd0-4431-ae24-629689b535d4"}
      data_2 = %{"uuid" => "hello-world"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{uuid: "9d98baf6-3cd0-4431-ae24-629689b535d4"}
      assert errors_on(changeset_2) == %{uuid: ["is invalid"]}
    end

    test "uuid, equals: 9d98baf6-3cd0-4431-ae24-629689b535d4" do
      schema = %{uuid: [type: :uuid, equals: "9d98baf6-3cd0-4431-ae24-629689b535d4"]}

      data_1 = %{"uuid" => "9d98baf6-3cd0-4431-ae24-629689b535d4"}
      data_2 = %{"uuid" => "16acef25-3981-4cbd-ab99-26f8691c5bec"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{uuid: "9d98baf6-3cd0-4431-ae24-629689b535d4"}
      assert errors_on(changeset_2) == %{uuid: ["is invalid"]}
    end

    test "string, min: 4" do
      schema = %{name: [type: :string, is: 4]}

      data_1 = %{"name" => "Jane"}
      data_2 = %{"name" => "Joe"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{name: "Jane"}
      assert errors_on(changeset_2) == %{name: ["should be 4 character(s)"]}
    end

    test "string, min: 5" do
      schema = %{name: [type: :string, min: 5]}

      data_1 = %{"name" => "Jonathan"}
      data_2 = %{"name" => "Jane"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{name: "Jonathan"}
      assert errors_on(changeset_2) == %{name: ["should be at least 5 character(s)"]}
    end

    test "string, max: 5" do
      schema = %{name: [type: :string, max: 5]}

      data_1 = %{"name" => "Jane"}
      data_2 = %{"name" => "Jonathan"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{name: "Jane"}
      assert errors_on(changeset_2) == %{name: ["should be at most 5 character(s)"]}
    end

    test "string, trim: true" do
      schema = %{name: [type: :string, trim: true]}

      data_1 = %{"name" => " quantum physics "}
      data_2 = %{"name" => " quantum  physics "}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{name: "quantum physics"}
      assert changes_on(changeset_2) == %{name: "quantum  physics"}
    end

    test "string, trim: false" do
      schema = %{name: [type: :string, trim: false]}

      data_1 = %{"name" => " quantum physics "}
      data_2 = %{"name" => " quantum  physics "}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{name: " quantum physics "}
      assert changes_on(changeset_2) == %{name: " quantum  physics "}
    end

    test "string, squish: true" do
      schema = %{name: [type: :string, squish: true]}

      data = %{"name" => " banana   man "}

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{name: "banana man"}
    end

    test "string, squish: false" do
      schema = %{name: [type: :string, squish: false]}

      data = %{"name" => " banana   man "}

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{name: " banana   man "}
    end

    test "string, format: :uuid" do
      schema = %{uuid: [type: :string, format: :uuid]}

      data_1 = %{"uuid" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e"}
      data_2 = %{"uuid" => "notuuid"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{uuid: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e"}
      assert errors_on(changeset_2) == %{uuid: ["has invalid format"]}
    end

    test "string, format: :email" do
      schema = %{email: [type: :string, format: :email]}

      data_1 = %{"email" => "jane.doe@example.com"}
      data_2 = %{"email" => "notemail"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{email: "jane.doe@example.com"}
      assert errors_on(changeset_2) == %{email: ["has invalid format"]}
    end

    test "string, format: :password" do
      schema = %{password: [type: :string, format: :password]}

      data_1 = %{"password" => "password123"}
      data_2 = %{"password" => "pass"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{password: "password123"}
      assert errors_on(changeset_2) == %{password: ["has invalid format"]}
    end

    test "string, format: :url" do
      schema = %{url: [type: :string, format: :url]}

      data_1 = %{"url" => "https://www.example.com"}
      data_2 = %{"url" => "website"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{url: "https://www.example.com"}
      assert errors_on(changeset_2) == %{url: ["has invalid format"]}
    end

    test "string, format: %Regex{}" do
      schema = %{id: [type: :string, format: ~r/^[[:alnum:]]+$/]}

      data_1 = %{"id" => "ad41cb"}
      data_2 = %{"id" => "zu981ik&*^"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{id: "ad41cb"}
      assert errors_on(changeset_2) == %{id: ["has invalid format"]}
    end

    test "string, format: custom regex" do
      Application.put_env(:goal, :custom_regex, ~r/^[a-fA-F0-9]{40}$/)

      schema = %{hash: [type: :string, format: :custom]}

      hash = :crypto.hash(:sha, "test") |> Base.encode16()
      data_1 = %{"hash" => hash}
      data_2 = %{"hash" => "notahash"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{hash: hash}
      assert errors_on(changeset_2) == %{hash: ["has invalid format"]}

      Application.delete_env(:goal, :custom_regex)
    end

    test "integer, is: 5" do
      schema = %{age: [type: :integer, is: 5]}

      data_1 = %{"age" => 5}
      data_2 = %{"age" => 4}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 5}
      assert errors_on(changeset_2) == %{age: ["must be equal to 5"]}
    end

    test "integer, min: 5" do
      schema = %{age: [type: :integer, min: 5]}

      data_1 = %{"age" => 6}
      data_2 = %{"age" => 4}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 6}
      assert errors_on(changeset_2) == %{age: ["must be greater than or equal to 5"]}
    end

    test "integer, max: 10" do
      schema = %{age: [type: :integer, max: 11]}

      data_1 = %{"age" => 9}
      data_2 = %{"age" => 12}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 9}
      assert errors_on(changeset_2) == %{age: ["must be less than or equal to 11"]}
    end

    test "integer, less_than: 10" do
      schema = %{age: [type: :integer, less_than: 11]}

      data_1 = %{"age" => 9}
      data_2 = %{"age" => 11}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 9}
      assert errors_on(changeset_2) == %{age: ["must be less than 11"]}
    end

    test "integer, greater_than: 5" do
      schema = %{age: [type: :integer, greater_than: 5]}

      data_1 = %{"age" => 6}
      data_2 = %{"age" => 4}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 6}
      assert errors_on(changeset_2) == %{age: ["must be greater than 5"]}
    end

    test "integer, less_than_or_equal_to: 5" do
      schema = %{age: [type: :integer, less_than_or_equal_to: 5]}

      data_1 = %{"age" => 5}
      data_2 = %{"age" => 4}
      data_3 = %{"age" => 6}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)
      changeset_3 = Goal.build_changeset(schema, data_3)

      assert changes_on(changeset_1) == %{age: 5}
      assert changes_on(changeset_2) == %{age: 4}
      assert errors_on(changeset_3) == %{age: ["must be less than or equal to 5"]}
    end

    test "integer, greater_than_or_equal_to: 10" do
      schema = %{age: [type: :integer, greater_than_or_equal_to: 11]}

      data_1 = %{"age" => 11}
      data_2 = %{"age" => 12}
      data_3 = %{"age" => 9}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)
      changeset_3 = Goal.build_changeset(schema, data_3)

      assert changes_on(changeset_1) == %{age: 11}
      assert changes_on(changeset_2) == %{age: 12}
      assert errors_on(changeset_3) == %{age: ["must be greater than or equal to 11"]}
    end

    test "integer, equal_to: 5" do
      schema = %{age: [type: :integer, equal_to: 5]}

      data_1 = %{"age" => 5}
      data_2 = %{"age" => 4}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 5}
      assert errors_on(changeset_2) == %{age: ["must be equal to 5"]}
    end

    test "integer, not_equal_to: 10" do
      schema = %{age: [type: :integer, not_equal_to: 11]}

      data_1 = %{"age" => 9}
      data_2 = %{"age" => 11}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{age: 9}
      assert errors_on(changeset_2) == %{age: ["must be not equal to 11"]}
    end

    test "float, is: 5.01" do
      schema = %{height: [type: :float, is: 5.01]}

      data_1 = %{"height" => 5.01}
      data_2 = %{"height" => 4.01}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{height: 5.01}
      assert errors_on(changeset_2) == %{height: ["must be equal to 5.01"]}
    end

    test "float, min: 5.01" do
      schema = %{height: [type: :float, min: 5.01]}

      data_1 = %{"height" => 5.02}
      data_2 = %{"height" => 5.00}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{height: 5.02}
      assert errors_on(changeset_2) == %{height: ["must be greater than or equal to 5.01"]}
    end

    test "float, max: 5.01" do
      schema = %{height: [type: :float, max: 5.01]}

      data_1 = %{"height" => 4.99}
      data_2 = %{"height" => 5.02}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{height: 4.99}
      assert errors_on(changeset_2) == %{height: ["must be less than or equal to 5.01"]}
    end

    test "decimal, is: 5.01" do
      schema = %{money: [type: :decimal, is: 5.01]}

      data_1 = %{"money" => 5.01}
      data_2 = %{"money" => 4.01}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{money: Decimal.from_float(5.01)}
      assert errors_on(changeset_2) == %{money: ["must be equal to 5.01"]}
    end

    test "decimal, min: 5.01" do
      schema = %{money: [type: :decimal, min: 5.01]}

      data_1 = %{"money" => 5.02}
      data_2 = %{"money" => 5.00}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{money: Decimal.from_float(5.02)}
      assert errors_on(changeset_2) == %{money: ["must be greater than or equal to 5.01"]}
    end

    test "decimal, max: 5.01" do
      schema = %{money: [type: :decimal, max: 5.01]}

      data_1 = %{"money" => 4.99}
      data_2 = %{"money" => 5.02}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{money: Decimal.from_float(4.99)}
      assert errors_on(changeset_2) == %{money: ["must be less than or equal to 5.01"]}
    end

    test "enum, atom-based" do
      schema = %{status: [type: :enum, values: [:active, :inactive]]}

      data_1 = %{"status" => "active"}
      data_2 = %{"status" => "busy"}
      data_3 = %{"status" => :active}
      data_4 = %{"status" => :busy}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)
      changeset_3 = Goal.build_changeset(schema, data_3)
      changeset_4 = Goal.build_changeset(schema, data_4)

      assert changes_on(changeset_1) == %{status: :active}
      assert errors_on(changeset_2) == %{status: ["is invalid"]}
      assert changes_on(changeset_3) == %{status: :active}
      assert errors_on(changeset_4) == %{status: ["is invalid"]}
    end

    test "enum, string-based" do
      schema = %{status: [type: :enum, values: ["active", "inactive"]]}

      data_1 = %{"status" => "active"}
      data_2 = %{"status" => "busy"}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert changes_on(changeset_1) == %{status: :active}
      assert errors_on(changeset_2) == %{status: ["is invalid"]}
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

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
               map: %{
                 string: "hello",
                 integer: 5
               }
             }
    end

    test "unstructured map" do
      data = %{
        "map" => %{
          "string" => "hello",
          "integer" => 5
        }
      }

      schema = %{map: [type: :map]}

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
               map: %{
                 "string" => "hello",
                 "integer" => 5
               }
             }
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

      changeset = Goal.build_changeset(schema, data)

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

      changeset = Goal.build_changeset(schema, data)

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
        "list" => ["one", "two", "three"]
      }

      schema = %{
        list: [type: {:array, :string}]
      }

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{list: ["one", "two", "three"]}
    end

    test "invalid list" do
      data = %{
        "list" => ["one", "two", "three"]
      }

      schema = %{
        list: [type: {:array, :integer}]
      }

      changeset = Goal.build_changeset(schema, data)

      assert errors_on(changeset) == %{list: ["is invalid"]}
    end

    test "list of undefined maps" do
      data = %{
        "list" => [
          %{"string" => "hello"},
          %{"string" => "world"}
        ]
      }

      schema = %{list: [type: {:array, :map}]}

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{list: [%{"string" => "hello"}, %{"string" => "world"}]}
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
          type: {:array, :map},
          properties: %{
            string: [type: :string],
            integer: [type: :integer]
          }
        ]
      }

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
               list: [
                 %{string: "hello", integer: 1},
                 %{string: "world", integer: 2}
               ]
             }
    end

    test "list of maps, min and max" do
      schema = %{
        list: [
          type: {:array, :map},
          rules: [min: 1, max: 1]
        ]
      }

      data_1 = %{"list" => []}
      data_2 = %{"list" => [%{"hello" => "world"}, %{"hello" => "world"}]}

      changeset_1 = Goal.build_changeset(schema, data_1)
      changeset_2 = Goal.build_changeset(schema, data_2)

      assert errors_on(changeset_1) == %{list: ["should have at least 1 item(s)"]}
      assert errors_on(changeset_2) == %{list: ["should have at most 1 item(s)"]}
    end

    test "list of maps, invalid type given" do
      schema = %{
        list: [
          type: {:array, :map},
          properties: %{
            string: [type: :string]
          }
        ]
      }

      changeset = Goal.build_changeset(schema, %{"list" => "not a list"})

      assert errors_on(changeset) == %{list: ["is invalid"]}
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
          type: {:array, :map},
          properties: %{
            string: [type: :string, format: :uuid],
            integer: [type: :integer]
          }
        ]
      }

      changeset = Goal.build_changeset(schema, data)

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
          type: {:array, :map},
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

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
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
             }
    end

    test "list of primitive types" do
      data = %{
        "strings" => [" hello", "world "]
      }

      schema = %{
        strings: [
          type: {:array, :string},
          rules: [trim: true]
        ]
      }

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{strings: ["hello", "world"]}
    end

    test "list of strings with incorrect values" do
      data = %{
        "strings" => ["arrg", "arr", "ab", "a"]
      }

      schema = %{
        strings: [
          type: {:array, :string},
          rules: [trim: true, min: 2, max: 3]
        ]
      }

      changeset = Goal.build_changeset(schema, data)

      assert errors_on(changeset) == %{
               strings: [
                 "item should be at least 2 character(s)",
                 "item should be at most 3 character(s)"
               ]
             }
    end

    test "list of incorrect primitive types does not create duplicate errors" do
      data = %{
        "strings" => ["abc", "def"]
      }

      schema = %{
        strings: [
          type: {:array, :string},
          rules: [max: 2]
        ]
      }

      changeset = Goal.build_changeset(schema, data)

      assert errors_on(changeset) == %{
               strings: [
                 "item should be at most 2 character(s)"
               ]
             }
    end

    test "list of primitive type :trim, min: 2 and list min: 1" do
      schema = %{
        list: [
          type: {:array, :string},
          rules: [trim: true, min: 2],
          min: 1
        ]
      }

      works = %{"list" => [" hello "]}
      breaks1 = %{"list" => [" i "]}
      breaks2 = %{"list" => []}

      changeset1 = Goal.build_changeset(schema, works)
      changeset2 = Goal.build_changeset(schema, breaks1)
      changeset3 = Goal.build_changeset(schema, breaks2)

      assert changes_on(changeset1) == %{list: ["hello"]}
      assert errors_on(changeset2) == %{list: ["item should be at least 2 character(s)"]}
      assert errors_on(changeset3) == %{list: ["should have at least 1 item(s)"]}
    end

    test "optional list, min: 1" do
      schema = %{list: [type: {:array, :string}, min: 1]}

      changeset = Goal.build_changeset(schema, %{"list" => []})

      assert errors_on(changeset) == %{list: ["should have at least 1 item(s)"]}
    end

    test "list, min: 2" do
      schema = %{list: [type: {:array, :string}, min: 2]}

      works = %{"list" => ["a", "b"]}
      breaks = %{"list" => ["a"]}
      optional = %{}

      changeset1 = Goal.build_changeset(schema, works)
      changeset2 = Goal.build_changeset(schema, breaks)
      changeset3 = Goal.build_changeset(schema, optional)

      assert changes_on(changeset1) == %{list: ["a", "b"]}
      assert errors_on(changeset2) == %{list: ["should have at least 2 item(s)"]}
      assert changes_on(changeset3) == %{}
    end

    test "list, max: 2" do
      schema = %{list: [type: {:array, :string}, max: 2]}

      works = %{"list" => ["a", "b"]}
      breaks = %{"list" => ["a", "b", "c"]}
      optional = %{}

      changeset1 = Goal.build_changeset(schema, works)
      changeset2 = Goal.build_changeset(schema, breaks)
      changeset3 = Goal.build_changeset(schema, optional)

      assert changes_on(changeset1) == %{list: ["a", "b"]}
      assert errors_on(changeset2) == %{list: ["should have at most 2 item(s)"]}
      assert changes_on(changeset3) == %{}
    end

    test "list, is: 2" do
      schema = %{list: [type: {:array, :string}, is: 2]}

      works = %{"list" => ["a", "b"]}
      breaks1 = %{"list" => ["a", "b", "c"]}
      breaks2 = %{"list" => ["a"]}
      optional = %{}

      changeset1 = Goal.build_changeset(schema, works)
      changeset2 = Goal.build_changeset(schema, breaks1)
      changeset3 = Goal.build_changeset(schema, breaks2)
      changeset4 = Goal.build_changeset(schema, optional)

      assert changes_on(changeset1) == %{list: ["a", "b"]}
      assert errors_on(changeset2) == %{list: ["should have 2 item(s)"]}
      assert errors_on(changeset3) == %{list: ["should have 2 item(s)"]}
      assert changes_on(changeset4) == %{}
    end

    test "list and item both invalid" do
      schema = %{list: [type: {:array, :string}, max: 1, rules: [min: 3]]}

      works = %{"list" => ["hello"]}
      breaks = %{"list" => ["as", "we"]}

      changeset1 = Goal.build_changeset(schema, works)
      changeset2 = Goal.build_changeset(schema, breaks)

      assert changes_on(changeset1) == %{list: ["hello"]}

      assert errors_on(changeset2) == %{
               list: [
                 "item should be at least 3 character(s)",
                 "should have at most 1 item(s)"
               ]
             }
    end

    test "required list, min: 2" do
      schema = %{list: [type: {:array, :string}, required: true, min: 1]}

      works = %{"list" => ["hello"]}
      breaks = %{}

      changeset1 = Goal.build_changeset(schema, works)
      changeset2 = Goal.build_changeset(schema, breaks)

      assert changes_on(changeset1) == %{list: ["hello"]}
      assert errors_on(changeset2) == %{list: ["can't be blank"]}
    end

    test "list, items and basic types together" do
      schema = %{
        name: [type: :string, min: 1, required: true],
        age: [type: :integer],
        hobbies: [type: {:array, :string}, required: true, min: 1, rules: [trim: true, min: 2]],
        picks: [type: {:array, :integer}, max: 4, rules: [min: 14, max: 48]]
      }

      data = %{
        "age" => "pete",
        "hobbies" => ["i "],
        "picks" => [11, 44, 19, 22, 31]
      }

      changeset = Goal.build_changeset(schema, data)

      assert errors_on(changeset) == %{
               name: ["can't be blank"],
               age: ["is invalid"],
               hobbies: ["item should be at least 2 character(s)"],
               picks: [
                 "item must be greater than or equal to 14",
                 "should have at most 4 item(s)"
               ]
             }
    end

    test "list, missing items" do
      schema = %{
        list: [type: {:array, :string}, required: true, rules: [format: :uuid]]
      }

      changeset = Goal.build_changeset(schema, %{})

      assert errors_on(changeset) == %{
               list: ["can't be blank"]
             }
    end

    test "list, different type given" do
      schema = %{
        list: [type: {:array, :string}, rules: [format: :uuid]]
      }

      changeset = Goal.build_changeset(schema, %{"list" => "not_a_list"})

      assert errors_on(changeset) == %{
               list: ["is invalid"]
             }
    end

    test "list item validations do not override the changeset validity" do
      schema = %{
        name: [type: :string, max: 3],
        list: [type: {:array, :string}, min: 1, rules: [min: 1]]
      }

      data = %{"name" => "peetee", "list" => ["hello", "world"]}

      changeset = Goal.build_changeset(schema, data)

      assert errors_on(changeset) == %{name: ["should be at most 3 character(s)"]}
    end

    test "list with maps validation does not override changeset validity" do
      schema = %{
        name: [type: :string, max: 3],
        list_2: [
          type: {:array, :map},
          properties: %{
            name: [type: :string, required: true]
          }
        ]
      }

      params = %{
        "name" => "peetee",
        "list_2" => [
          %{"name" => "hello"}
        ]
      }

      changeset = Goal.build_changeset(schema, params)

      assert errors_on(changeset) == %{name: ["should be at most 3 character(s)"]}
    end

    test "list with enums, string-based" do
      schema = %{
        list: [type: {:array, :enum}, required: true, rules: [values: ["active", "inactive"]]]
      }

      changeset_1 = Goal.build_changeset(schema, %{"list" => ["active", "inactive"]})
      assert changes_on(changeset_1) == %{list: [:active, :inactive]}

      changeset_2 = Goal.build_changeset(schema, %{})
      assert errors_on(changeset_2) == %{list: ["can't be blank"]}
    end

    test "list with enums, atom-based" do
      schema = %{
        list: [
          type: {:array, :enum},
          required: true,
          rules: [values: [:active, :inactive], min: 1]
        ]
      }

      changeset_1 = Goal.build_changeset(schema, %{"list" => ["active", "inactive"]})
      assert changes_on(changeset_1) == %{list: [:active, :inactive]}

      changeset_2 = Goal.build_changeset(schema, %{})
      assert errors_on(changeset_2) == %{list: ["can't be blank"]}

      changeset_3 = Goal.build_changeset(schema, %{list: []})
      assert errors_on(changeset_3) == %{list: ["should have at least 1 item(s)"]}
    end

    test "list with enums, nested inside of map" do
      data = %{
        "id" => "1",
        "nested_map" => %{
          "key" => "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
          "list" => ["active"]
        }
      }

      schema = %{
        id: [type: :integer],
        nested_map: [
          type: :map,
          properties: %{
            key: [type: :string, format: :uuid],
            list: [type: {:array, :enum}, rules: [values: ["active", "inactive"]]]
          }
        ]
      }

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
               id: 1,
               nested_map: %{
                 key: "f45fb959-b0f9-4a32-b6ca-d32bdb53ee8e",
                 list: [:active]
               }
             }
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

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{string_1: "world"}
    end

    test "missing data" do
      data = %{
        "string_1" => "world"
      }

      schema = %{
        string_1: [type: :string],
        string_2: [type: :string]
      }

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{string_1: "world"}
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

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{string_1: "world"}
    end

    test "missing required data" do
      data = %{
        "string_1" => "world"
      }

      schema = %{
        string_1: [type: :string, required: true],
        string_2: [type: :string, required: true]
      }

      changeset = Goal.build_changeset(schema, data)

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

      changeset = Goal.build_changeset(schema, data)

      assert errors_on(changeset) == %{
               string_2: ["can't be blank"],
               map_1: ["can't be blank"]
             }
    end

    test "works with atom-based maps" do
      data = %{
        map: %{
          string: "hello",
          integer: 5
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

      changeset = Goal.build_changeset(schema, data)

      assert changes_on(changeset) == %{
               map: %{
                 string: "hello",
                 integer: 5
               }
             }
    end

    test "includes empty values when they were given" do
      schema = %{timestamp: [type: :utc_datetime]}
      params = %{"timestamp" => nil}

      changeset = Goal.build_changeset(schema, params)

      assert changes_on(changeset) == %{timestamp: nil}
    end

    test "excludes empty values when they were not given" do
      schema = %{name: [type: :string]}
      params = %{}

      changeset = Goal.build_changeset(schema, params)

      assert changes_on(changeset) == %{}
    end
  end

  describe "recase_keys/2" do
    test "to snake_case" do
      params = %{firstName: "Jane", lastName: "Doe"}
      opts = [recase_keys: [to: :snake_case]]

      assert Goal.recase_keys(params, opts) == %{first_name: "Jane", last_name: "Doe"}
    end

    test "to camel_case" do
      params = %{first_name: "Jane", last_name: "Doe"}
      opts = [recase_keys: [to: :camel_case]]

      assert Goal.recase_keys(params, opts) == %{firstName: "Jane", lastName: "Doe"}
    end

    test "to pascal_case" do
      params = %{first_name: "Jane", last_name: "Doe"}
      opts = [recase_keys: [to: :pascal_case]]

      assert Goal.recase_keys(params, opts) == %{FirstName: "Jane", LastName: "Doe"}
    end

    test "to kebab_case" do
      params = %{first_name: "Jane", last_name: "Doe"}
      opts = [recase_keys: [to: :kebab_case]]

      assert Goal.recase_keys(params, opts) == %{"first-name": "Jane", "last-name": "Doe"}
    end

    test "string-based map" do
      params = %{"first_name" => "Jane", "last_name" => "Doe"}
      opts = [recase_keys: [to: :camel_case]]

      assert Goal.recase_keys(params, opts) == %{"firstName" => "Jane", "lastName" => "Doe"}
    end

    test "nested map" do
      params = %{
        first_name: "Jane",
        last_name: "Doe",
        preferences: %{food_choice: "pizza", drink_choice: "cola"}
      }

      opts = [recase_keys: [to: :camel_case]]

      assert Goal.recase_keys(params, opts) == %{
               firstName: "Jane",
               lastName: "Doe",
               preferences: %{foodChoice: "pizza", drinkChoice: "cola"}
             }
    end

    test "list of maps" do
      params = %{
        first_name: "Jane",
        last_name: "Doe",
        preferences: [%{food_choice: "pizza", drink_choice: "cola"}]
      }

      opts = [recase_keys: [to: :camel_case]]

      assert Goal.recase_keys(params, opts) == %{
               firstName: "Jane",
               lastName: "Doe",
               preferences: [%{foodChoice: "pizza", drinkChoice: "cola"}]
             }
    end

    test "list of string" do
      params = %{
        first_name: "Jane",
        last_name: "Doe",
        preferences: ["pizza", "cola"]
      }

      opts = [recase_keys: [to: :camel_case]]

      assert Goal.recase_keys(params, opts) == %{
               firstName: "Jane",
               lastName: "Doe",
               preferences: ["pizza", "cola"]
             }
    end

    test "list of structs" do
      struct = DateTime.utc_now()

      params = %{
        first_name: "Jane",
        last_name: "Doe",
        preferences: [struct, struct]
      }

      opts = [recase_keys: [to: :camel_case]]

      assert Goal.recase_keys(params, opts) ==
               %{
                 firstName: "Jane",
                 lastName: "Doe",
                 preferences: [struct, struct]
               }
    end
  end

  describe "recase_keys/3" do
    test "from snake_case" do
      schema = %{firstName: [type: :string], lastName: [type: :string]}
      params = %{"first_name" => "Jane", "last_name" => "Doe"}
      opts = [recase_keys: [from: :snake_case]]

      assert Goal.recase_keys(schema, params, opts) == %{firstName: "Jane", lastName: "Doe"}
    end

    test "from camel_case" do
      schema = %{first_name: [type: :string], last_name: [type: :string]}
      params = %{"firstName" => "Jane", "lastName" => "Doe"}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) == %{first_name: "Jane", last_name: "Doe"}
    end

    test "from pascal_case" do
      schema = %{first_name: [type: :string], last_name: [type: :string]}
      params = %{"FirstName" => "Jane", "LastName" => "Doe"}
      opts = [recase_keys: [from: :pascal_case]]

      assert Goal.recase_keys(schema, params, opts) == %{first_name: "Jane", last_name: "Doe"}
    end

    test "from kebab_case" do
      schema = %{first_name: [type: :string], last_name: [type: :string]}
      params = %{"first-name" => "Jane", "last-name" => "Doe"}
      opts = [recase_keys: [from: :kebab_case]]

      assert Goal.recase_keys(schema, params, opts) == %{first_name: "Jane", last_name: "Doe"}
    end

    test "atom-based map" do
      schema = %{first_name: [type: :string], last_name: [type: :string]}
      params = %{firstName: "Jane", lastName: "Doe"}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) == %{first_name: "Jane", last_name: "Doe"}
    end

    test "empty map" do
      schema = %{description: [type: :map, required: true]}
      params = %{"description" => %{}}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) == %{description: %{}}
    end

    test "non-empty map" do
      schema = %{description: [type: :map]}
      params = %{"description" => %{"hello" => "world"}}
      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) == %{description: %{"hello" => "world"}}
    end

    test "nested map" do
      schema = %{
        first_name: [type: :string],
        last_name: [type: :string],
        preferences: [
          type: :map,
          properties: %{
            food_choice: [type: :string],
            drink_choice: [type: :string]
          }
        ]
      }

      params = %{
        "firstName" => "Jane",
        "lastName" => "Doe",
        "preferences" => %{"foodChoice" => "pizza", "drinkChoice" => "cola"}
      }

      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) ==
               %{
                 first_name: "Jane",
                 last_name: "Doe",
                 preferences: %{food_choice: "pizza", drink_choice: "cola"}
               }
    end

    test "list of maps" do
      schema = %{
        first_name: [type: :string],
        last_name: [type: :string],
        preferences: [
          type: {:array, :map},
          properties: %{
            food_choice: [type: :string],
            drink_choice: [type: :string]
          }
        ]
      }

      params = %{
        "firstName" => "Jane",
        "lastName" => "Doe",
        "preferences" => [%{"foodChoice" => "pizza", "drinkChoice" => "cola"}]
      }

      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) ==
               %{
                 first_name: "Jane",
                 last_name: "Doe",
                 preferences: [%{food_choice: "pizza", drink_choice: "cola"}]
               }
    end

    test "list of strings" do
      schema = %{
        first_name: [type: :string],
        last_name: [type: :string],
        preferences: [type: {:array, :string}]
      }

      params = %{
        "firstName" => "Jane",
        "lastName" => "Doe",
        "preferences" => ["pizza", "cola"]
      }

      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) ==
               %{
                 first_name: "Jane",
                 last_name: "Doe",
                 preferences: ["pizza", "cola"]
               }
    end

    test "list of structs" do
      schema = %{
        first_name: [type: :string],
        last_name: [type: :string],
        preferences: [type: {:array, DateTime}]
      }

      struct = DateTime.utc_now()

      params = %{
        "firstName" => "Jane",
        "lastName" => "Doe",
        "preferences" => [struct, struct]
      }

      opts = [recase_keys: [from: :camel_case]]

      assert Goal.recase_keys(schema, params, opts) ==
               %{
                 first_name: "Jane",
                 last_name: "Doe",
                 preferences: [struct, struct]
               }
    end

    test "redundant fields" do
      schema = %{firstName: [type: :string], lastName: [type: :string]}
      params = %{"first_name" => "Jane", "last_name" => "Doe", "age" => 25}
      opts = [recase_keys: [from: :snake_case]]

      assert Goal.recase_keys(schema, params, opts) == %{firstName: "Jane", lastName: "Doe"}
    end
  end
end
