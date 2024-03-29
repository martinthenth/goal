defmodule Goal.Changeset do
  @moduledoc """
  Goal.Changeset contains an adapted version of `Ecto.Changeset.traverse_errors/2`.

  You can use `traverse_errors/2` to build all errors into a series of nested maps.
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

  @doc ~S"""
  Traverses changeset errors and applies the given function to error messages.

  This function is particularly useful when associations, embeds, maps
  and nested maps are cast in the changeset as it will traverse all
  associations, embeds, maps and nested maps and place all errors in a
  series of nested maps.

  A changeset is supplied along with a function to apply to each
  error message as the changeset is traversed. The error message
  function receives an error tuple `{msg, opts}`, for example:

      {"should be at least %{count} characters", [count: 3, validation: :length, min: 3]}

  ## Examples

      iex> traverse_errors(changeset, fn {msg, opts} ->
      ...>   Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      ...>     opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      ...>   end)
      ...> end)
      %{title: ["should be at least 3 characters"]}

  Optionally function can accept three arguments: `changeset`, `field`
  and error tuple `{msg, opts}`. It is useful whenever you want to extract
  validations rules from `changeset.validations` to build detailed error
  description.

  This function and documentation is gratefully copied and adapted
  from `Ecto.Changeset.traverse_errors/2` 🙇
  """
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

  def traverse_errors(changes, msg_func) when is_map(changes) do
    Enum.reduce(changes, %{}, fn
      {_field, %Changeset{} = changeset}, acc ->
        Map.put(acc, :field, traverse_errors(changeset, msg_func))

      {_field, _value}, acc ->
        acc
    end)
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
        traverse_changesets(acc, changes, field, msg_func, traverse_function)

      {field, {tag, %{cardinality: :one}}}, acc when tag in @relations ->
        traverse_changeset(acc, changes, field, msg_func, traverse_function)

      {field, {:array, :map}}, acc ->
        traverse_changesets(acc, changes, field, msg_func, traverse_function)

      {field, :map}, acc ->
        traverse_changeset(acc, changes, field, msg_func, traverse_function)

      {_field, _type}, acc ->
        acc
    end)
  end

  defp traverse_changeset(acc, changes, field, msg_func, traverse_function) do
    if changeset = Map.get(changes, field) do
      case traverse_function.(changeset, msg_func) do
        child when child == %{} -> acc
        child -> Map.put(acc, field, child)
      end
    else
      acc
    end
  end

  defp traverse_changesets(acc, changes, field, msg_func, traverse_function) do
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
  end
end
