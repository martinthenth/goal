defmodule Bench do
  use Goal

  @statuses [:draft, :pending, :done]

  defparams(:flat) do
    required(:name, :string)
    required(:age, :integer)
    optional(:email, :string)
    optional(:phone, :string)
  end

  defparams(:nest) do
    required(:name, :string)
    required(:age, :integer)
    optional(:email, :string)
    optional(:phone, :string)

    required(:address, :map) do
      required(:street, :string)
      required(:city, :string)
      required(:zip, :string)
    end
  end

  defparams(:deep) do
    required(:id, :integer)
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string, squish: true)
    optional(:age, :integer, min: 0, max: 120)
    optional(:gender, :enum, values: ["female", "male", "non-binary"])
    optional(:status, :enum, values: @statuses)
    optional(:hash, :string, format: ~r/^[a-fA-F0-9]{40}$/)

    required(:car, :map) do
      optional(:name, :string, min: 3, max: 20)
      optional(:brand, :string, included: ["Mercedes", "GMC"])

      required(:stats, :map) do
        optional(:age, :integer)
        optional(:mileage, :float)
        optional(:color, :string, excluded: ["camo"])
      end

      optional(:deleted, :boolean)
    end

    required(:dogs, {:array, :map}) do
      optional(:name, :string)
      optional(:age, :integer)
      optional(:type, :string)

      required(:data, :map) do
        optional(:paws, :integer)
      end
    end
  end
end

flat_params = %{
  name: "Jane",
  age: 42,
  email: "jane@doe.com",
  phone: "1234567890"
}

nest_params = %{
  name: "Jane",
  age: 42,
  email: "jane@example.com",
  phone: "1234567890",
  address: %{
    street: "123 Elm Street",
    city: "Springfield",
    zip: "12345"
  }
}

deep_params = %{
  id: 1,
  uuid: "123e4567-e89b-12d3-a456-426614174000",
  name: "Jane Doe",
  type: "  user  ",
  age: 42,
  gender: "female",
  status: :draft,
  hash: "1234567890abcdef",
  car: %{
    name: "My Car",
    brand: "Mercedes",
    stats: %{
      age: 3,
      mileage: 123.45,
      color: "red"
    },
    deleted: false
  },
  dogs: [
    %{
      name: "Fido",
      age: 3,
      type: "dog",
      data: %{
        paws: 4
      }
    },
    %{
      name: "Spot",
      age: 5,
      type: "dog",
      data: %{
        paws: 4
      }
    }
  ]
}

Benchee.run(
  %{
    "flat params" => fn -> Bench.validate(:flat, flat_params) end,
    "nested params" => fn -> Bench.validate(:nest, nest_params) end,
    "deeply nested params" => fn -> Bench.validate(:deep, deep_params) end
  },
  warmup: 5,
  time: 10,
  memory_time: 5
)
