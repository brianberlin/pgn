defmodule PGN.Helpers do
  alias PGN.{Repo}

  def query(sql, params \\ []) do
    sql
    |> Repo.query!(params)
    |> result_to_maps()
  end

  def result_to_maps(%Postgrex.Result{columns: _, rows: nil}), do: []

  def result_to_maps(%Postgrex.Result{columns: col_nms, rows: rows}) do
    Enum.map(rows, fn row -> row_to_map(col_nms, row) end)
  end

  def row_to_map(col_nms, vals) do
    col_nms
    |> Stream.zip(vals)
    |> Enum.into(Map.new(), fn {key, val} ->
      {String.to_atom(key), val}
    end)
  end
end
