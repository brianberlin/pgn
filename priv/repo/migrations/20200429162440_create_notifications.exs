defmodule PGN.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :on_insert, :boolean, default: false, null: false
      add :on_update, :boolean, default: false, null: false
      add :on_delete, :boolean, default: false, null: false
      add :table, :string
      add :fields, {:array, :string}

      timestamps()
    end

  end
end
