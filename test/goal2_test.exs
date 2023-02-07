defmodule Goal2Test do
  use ExUnit.Case
  use Goal2

  defparams do
    required(:id, :integer)
  end

  defparams :show do
    required(:id, :integer)
  end

  defparams :index do
    required(:id, :integer)
    required(:uuid, :string, format: :uuid)
    required(:name, :string, min: 3, max: 20)
    optional(:type, :string, squish: true)
    optional(:age, :integer, min: 0, max: 120)
    optional(:gender, :enum, values: ["female", "male", "non-binary"])

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

  describe "__using__/1" do
    test "schema/0" do
      assert schema() == %{id: [type: :integer, required: true]}
    end

    test "schema/1" do
      assert schema(:show) == %{id: [type: :integer, required: true]}

      assert schema(:index) == %{
               id: [type: :integer, required: true],
               uuid: [type: :string, required: true, format: :uuid],
               name: [type: :string, required: true, min: 3, max: 20],
               type: [type: :string, squish: true],
               age: [type: :integer, min: 0, max: 120],
               gender: [type: :enum, values: ["female", "male", "non-binary"]],
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
               action: :validate,
               changes: %{},
               errors: [id: {"can't be blank", [validation: :required]}],
               data: %{},
               valid?: false
             } = changeset(:show)
    end

    test "changeset/2" do
      assert %Ecto.Changeset{
               action: :validate,
               changes: %{},
               errors: [],
               data: %{},
               valid?: true
             } = changeset(:show, %{id: 123})

      assert %Ecto.Changeset{
               action: :validate,
               changes: %{},
               errors: [id: {"can't be blank", [validation: :required]}],
               data: %{},
               valid?: false
             } = changeset(:show, %{})
    end

    test "validate/2" do
      assert validate(:show, %{id: 123}) == {:ok, %{id: 123}}

      assert {:error,
              %Ecto.Changeset{
                action: :validate,
                changes: %{},
                errors: [id: {"can't be blank", [validation: :required]}],
                data: %{},
                valid?: false
              }} = validate(:show, %{})
    end
  end
end
