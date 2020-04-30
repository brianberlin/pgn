defmodule PGN.Tables do
  def get_table_options do
    query("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'")
  end

  def get_field_options(nil), do: []

  def get_field_options(name) do
    query("SELECT column_name FROM information_schema.COLUMNS WHERE table_name = $1", [name])
  end

  defp query(query, opts \\ []) do
    query
    |> PGN.Repo.query!(opts)
    |> to_options()
  end

  defp to_options(%Postgrex.Result{rows: rows}) do
    Enum.map(rows, &Enum.at(&1, 0))
  end
end
