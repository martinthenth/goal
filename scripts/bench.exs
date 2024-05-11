defmodule Bench do
  use Goal

  @statuses [:draft, :pending, :done]

  defparams(:presence) do
    required(:uuid)
    required(:name)
    optional(:type)
    optional(:age)
  end

  defparams(:simple) do
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string)
    optional(:age, :integer, min: 0, max: 120)
  end

  defparams(:flat) do
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string, trim: true)
    optional(:age, :integer, min: 0, max: 120)
    required(:document, :map)
    optional(:document_status, :enum, values: @statuses)
    optional(:document_hash, :string, format: ~r/^[[:alpha:]]+$/)
    required(:document_float, :decimal)
    required(:document_dogs, {:array, :map})
    optional(:document_dogs_name, :string)
    optional(:document_dogs_data, :map)
    optional(:document_dogs_data_paws, :integer)
  end

  defparams(:nest) do
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string, trim: true)
    optional(:age, :integer, min: 0, max: 120)

    required(:document, :map) do
      optional(:status, :enum, values: @statuses)
      optional(:hash, :string, format: ~r/^[[:alpha:]]+$/)
      required(:float, :decimal)
    end

    required(:dogs, {:array, :map}) do
      optional(:name, :string)

      required(:data, :map) do
        optional(:paws, :integer)
      end
    end
  end

  defparams(:deep) do
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string, trim: true)
    optional(:age, :integer, min: 0, max: 120)

    required(:document, :map) do
      optional(:status, :enum, values: @statuses)
      optional(:hash, :string, format: ~r/^[[:alpha:]]+$/)
      required(:float, :decimal)

      required(:dogs, {:array, :map}) do
        optional(:name, :string)

        required(:data, :map) do
          optional(:paws, :integer)
        end
      end
    end
  end
end

presence_params = %{
  uuid: "123e4567-e89b-12d3-a456-426614174000",
  name: "Jane Doe",
  type: "  user  ",
  age: 42
}

simple_params = %{
  uuid: "123e4567-e89b-12d3-a456-426614174000",
  name: "Jane Doe",
  type: "  user  ",
  age: 42
}

flat_params = %{
  uuid: "123e4567-e89b-12d3-a456-426614174000",
  name: "Jane Doe",
  type: "  user  ",
  age: 42,
  document: %{},
  document_status: :draft,
  document_hash: "abcdef",
  document_float: 123.45,
  document_dogs: [
    %{
      "name" => "Fido",
      "data" => %{
        "paws" => 4
      }
    },
    %{
      "name" => "Spot",
      "data" => %{
        "paws" => 4
      }
    }
  ],
  document_dogs_name: "Fido",
  document_dogs_data: %{
    "paws" => 4
  },
  document_dogs_data_paws: 4
}

nest_params = %{
  uuid: "123e4567-e89b-12d3-a456-426614174000",
  name: "Jane Doe",
  type: "  user  ",
  age: 42,
  document: %{
    status: :draft,
    hash: "abcdef",
    float: 123.45
  },
  dogs: [
    %{
      name: "Fido",
      data: %{
        paws: 4
      }
    },
    %{
      name: "Spot",
      data: %{
        paws: 4
      }
    }
  ]
}

deep_params = %{
  uuid: "123e4567-e89b-12d3-a456-426614174000",
  name: "Jane Doe",
  type: "  user  ",
  age: 42,
  document: %{
    status: :draft,
    hash: "abcdef",
    float: 123.45,
    dogs: [
      %{
        name: "Fido",
        data: %{
          paws: 4
        }
      },
      %{
        name: "Spot",
        data: %{
          paws: 4
        }
      }
    ]
  }
}

{:ok, _} = Bench.validate(:presence, presence_params)
{:ok, _} = Bench.validate(:simple, simple_params)
{:ok, _} = Bench.validate(:flat, flat_params)
{:ok, _} = Bench.validate(:nest, nest_params)
{:ok, _} = Bench.validate(:deep, deep_params)

Benchee.run(
  %{
    "presence params (4 fields)" => fn -> Bench.validate(:presence, presence_params) end,
    "simple params (4 fields)" => fn -> Bench.validate(:simple, simple_params) end,
    "flat params (12 fields)" => fn -> Bench.validate(:flat, flat_params) end,
    "nested params (12 fields)" => fn -> Bench.validate(:nest, nest_params) end,
    "deeply nested params (12 fields)" => fn -> Bench.validate(:deep, deep_params) end
  },
  warmup: 5,
  time: 10,
  memory_time: 5
)
