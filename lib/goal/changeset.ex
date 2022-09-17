defmodule Goal.Changeset do
  @moduledoc """
  Goal.Changeset contains an adapted version of `Ecto.Changeset.traverse_errors/2`.
  """

  alias Ecto.Changeset

  @empty_values [""]

  defstruct valid?: false,
            data: nil,
            params: nil,
            changes: %{},
            errors: [],
            validations: [],
            required: [],
            prepare: [],
            constraints: [],
            filters: %{},
            action: nil,
            types: nil,
            empty_values: @empty_values,
            repo: nil,
            repo_opts: []

  @type t(data_type) :: %Changeset{
          valid?: boolean(),
          repo: atom | nil,
          repo_opts: Keyword.t(),
          data: data_type,
          params: %{optional(String.t()) => term} | nil,
          changes: %{optional(atom) => term},
          required: [atom],
          prepare: [(t -> t)],
          errors: [{atom, error}],
          constraints: [constraint],
          validations: [{atom, term}],
          filters: %{optional(atom) => term},
          action: action,
          types: nil | %{atom => Ecto.Type.t() | {:assoc, term()} | {:embed, term()}}
        }

  @type t :: t(Ecto.Schema.t() | map | nil)
  @type error :: {String.t(), Keyword.t()}
  @type action :: nil | :insert | :update | :delete | :replace | :ignore | atom
  @type constraint :: %{
          type: :check | :exclusion | :foreign_key | :unique,
          constraint: String.t(),
          match: :exact | :suffix | :prefix,
          field: atom,
          error_message: String.t(),
          error_type: atom
        }
  @type data :: map()
  @type types :: map()

  @relations [:embed, :assoc, :map]

  @spec traverse_errors(t, (error -> String.t()) | (Changeset.t(), atom, error -> String.t())) ::
          %{atom => [term]}
  def traverse_errors(
        %Changeset{errors: errors, changes: changes, types: types} = changeset,
        msg_func
      )
      when is_function(msg_func, 1) or is_function(msg_func, 3) do
    errors
    |> Enum.reverse()
    |> merge_keyword_keys(msg_func, changeset)
    |> merge_related_keys(changes, types, msg_func, &traverse_errors/2)
  end

  defp merge_keyword_keys(keyword_list, msg_func, _) when is_function(msg_func, 1) do
    Enum.reduce(keyword_list, %{}, fn {key, val}, acc ->
      val = msg_func.(val)
      Map.update(acc, key, [val], &[val | &1])
    end)
  end

  defp merge_keyword_keys(keyword_list, msg_func, changeset) when is_function(msg_func, 3) do
    Enum.reduce(keyword_list, %{}, fn {key, val}, acc ->
      val = msg_func.(changeset, key, val)
      Map.update(acc, key, [val], &[val | &1])
    end)
  end

  defp merge_related_keys(_, _, nil, _, _) do
    raise ArgumentError, "changeset does not have types information"
  end

  defp merge_related_keys(map, changes, types, msg_func, traverse_function) do
    Enum.reduce(types, map, fn
      {field, {tag, %{cardinality: :many}}}, acc when tag in @relations ->
        if changesets = Map.get(changes, field) do
          {child, all_empty?} =
            Enum.map_reduce(changesets, true, fn changeset, all_empty? ->
              child = traverse_function.(changeset, msg_func)
              {child, all_empty? and child == %{}}
            end)

          case all_empty? do
            true -> acc
            false -> Map.put(acc, field, child)
          end
        else
          acc
        end

      {field, {tag, %{cardinality: :one}}}, acc when tag in @relations ->
        if changeset = Map.get(changes, field) do
          case traverse_function.(changeset, msg_func) do
            child when child == %{} -> acc
            child -> Map.put(acc, field, child)
          end
        else
          acc
        end

      # This clause allows traversing nested maps
      {field, :map}, acc ->
        if changeset = Map.get(changes, field) do
          case traverse_function.(changeset, msg_func) do
            child when child == %{} -> acc
            child -> Map.put(acc, field, child)
          end
        else
          acc
        end

      {_, _}, acc ->
        acc
    end)
  end
end
