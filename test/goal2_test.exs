defmodule Goal2Test do
  use ExUnit.Case

  use Goal2

  defparams do
    required(:id, :integer)
  end

  defparams :index do
    required(:id, :integer)
  end

  describe "using" do
    test "schema/0" do
      # TODO: Returning a block will break existing implementations...
      assert schema() == [do: %{id: [type: :integer, required: true]}]
    end

    test "schema/1" do
      # TODO: Returning a block will break existing implementations...
      assert schema(:index) == [do: %{id: [type: :integer, required: true]}]
    end

    test "changeset/2" do
      assert %Ecto.Changeset{
               action: :validate,
               changes: %{},
               errors: [],
               data: %{},
               valid?: true
             } = changeset(:index, %{id: 123})

      assert %Ecto.Changeset{
               action: :validate,
               changes: %{},
               errors: [id: {"can't be blank", [validation: :required]}],
               data: %{},
               valid?: false
             } = changeset(:index, %{})
    end

    test "validate/2" do
      assert validate(:index, %{id: 123}) == {:ok, %{id: 123}}

      assert {:error,
              %Ecto.Changeset{
                action: :validate,
                changes: %{},
                errors: [id: {"can't be blank", [validation: :required]}],
                data: %{},
                valid?: false
              }} = validate(:index, %{})
    end
  end

  # describe "defparams/1" do
  #   test "single entry" do
  #     schema =
  #       defparams do
  #         required(:id, :integer)
  #       end

  #     assert schema == %{id: [type: :integer, required: true]}
  #   end
  # end

  # describe "defparams/2" do
  #   test "single entry" do
  #     schema =
  #       defparams :new do
  #         required(:id, :integer)
  #       end

  #     assert schema == %{id: [type: :integer, required: true]}
  #   end

  #   test "multiple entries" do
  #     schema =
  #       defparams :index do
  #         required(:id, :integer)
  #         required(:uuid, :string, format: :uuid)
  #         required(:name, :string, min: 3, max: 20)
  #         optional(:type, :string, squish: true)
  #         optional(:age, :integer, min: 0, max: 120)
  #         optional(:gender, :enum, values: ["female", "male", "non-binary"])

  #         required :car, :map do
  #           optional(:name, :string, min: 3, max: 20)
  #           optional(:brand, :string, included: ["Mercedes", "GMC"])

  #           required :stats, :map do
  #             optional(:age, :integer)
  #             optional(:mileage, :float)
  #             optional(:color, :string, excluded: ["camo"])
  #           end

  #           optional(:deleted, :boolean)
  #         end

  #         required :dogs, {:array, :map} do
  #           optional(:name, :string)
  #           optional(:age, :integer)
  #           optional(:type, :string)

  #           required :data, :map do
  #             optional(:paws, :integer)
  #           end
  #         end
  #       end

  #     assert schema == %{
  #              id: [type: :integer, required: true],
  #              uuid: [type: :string, required: true, format: :uuid],
  #              name: [type: :string, required: true, min: 3, max: 20],
  #              type: [type: :string, squish: true],
  #              age: [type: :integer, min: 0, max: 120],
  #              gender: [type: :enum, values: ["female", "male", "non-binary"]],
  #              car: [
  #                type: :map,
  #                required: true,
  #                properties: %{
  #                  name: [type: :string, min: 3, max: 20],
  #                  brand: [type: :string, included: ["Mercedes", "GMC"]],
  #                  stats: [
  #                    type: :map,
  #                    required: true,
  #                    properties: %{
  #                      age: [type: :integer],
  #                      mileage: [type: :float],
  #                      color: [type: :string, excluded: ["camo"]]
  #                    }
  #                  ],
  #                  deleted: [type: :boolean]
  #                }
  #              ],
  #              dogs: [
  #                type: {:array, :map},
  #                required: true,
  #                properties: %{
  #                  name: [type: :string],
  #                  age: [type: :integer],
  #                  type: [type: :string],
  #                  data: [
  #                    type: :map,
  #                    required: true,
  #                    properties: %{
  #                      paws: [type: :integer]
  #                    }
  #                  ]
  #                }
  #              ]
  #            }
  #   end
  # end
end
