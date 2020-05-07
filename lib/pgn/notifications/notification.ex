defmodule PGN.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :on_delete, :boolean, default: false
    field :on_insert, :boolean, default: false
    field :on_update, :boolean, default: false
    field :table, :string
    field :fields, {:array, :string}, default: []
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:on_insert, :on_update, :on_delete, :table, :fields])
    |> validate_required([:on_insert, :on_update, :on_delete, :table, :fields])
    |> validate_op()
    |> maybe_add_id()
    |> filter_empty_strings_from_fields()
  end

  defp generate_id do
    String.replace(Ecto.UUID.generate(), "-", "")
  end

  defp maybe_add_id(changeset) do
    id = get_field(changeset, :id)

    if is_nil(id) do
      put_change(changeset, :id, generate_id)
    else
      changeset
    end
  end

  defp validate_op(changeset) do
    on_delete = get_change(changeset, :on_delete)
    on_insert = get_change(changeset, :on_insert)
    on_update = get_change(changeset, :on_update)

    if is_nil(on_delete) and is_nil(on_insert) and is_nil(on_update) do
      add_error(changeset, :on_insert, "Must have at least one of on_delete, on_insert or on_update")
    else
      changeset
    end
  end

  defp filter_empty_strings_from_fields(%{changes: %{fields: ["" | fields]}} = changeset) do
    put_change(changeset, :fields, fields)
  end

  defp filter_empty_strings_from_fields(changeset), do: changeset
end
