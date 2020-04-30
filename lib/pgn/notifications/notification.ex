defmodule PGN.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :on_delete, :boolean, default: false
    field :on_insert, :boolean, default: false
    field :on_update, :boolean, default: false
    field :table, :string
    field :fields, {:array, :string}, default: []

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:on_insert, :on_update, :on_delete, :table, :fields])
    |> validate_required([:on_insert, :on_update, :on_delete, :table, :fields])
    |> filter_empty_strings_from_fields()
  end

  defp filter_empty_strings_from_fields(%{changes: %{fields: ["" | fields]}} = changeset) do
    put_change(changeset, :fields, fields)
  end

  defp filter_empty_strings_from_fields(changeset), do: changeset
end
