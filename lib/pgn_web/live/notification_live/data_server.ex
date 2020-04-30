defmodule PGNWeb.NotificationLive.DataServer do
  @moduledoc """
  This module is a GenServer that caches and serves data for notifications

  More information about data servers can be seen in PGNWeb.DataServer
  """

  use PGNWeb.DataServer

  alias PGN.{Repo}

  @impl true
  def init(_) do
    with {:ok, listener} <- Repo.start_notification_listener(),
         {:ok, _ref} <- Repo.listen(listener, "notification") do
      {:ok, %{data: fetch_data([]), processes: [], initial_params: []}}
    else
      error ->
        {:stop, error}
    end
  end

  # Handle notification notifications from postgres
  @impl true
  def handle_info({:notification, _pid, _ref, "notification", payload}, state) do
    %{"db_table" => table, "payload" => payload} = Jason.decode!(payload)

    broadcast_data({table, payload}, state.processes)
    {:noreply, state}
  end

  @doc "Fetch data for the data server to cache and distribute"
  @impl true
  def fetch_data(_) do
    IO.inspect(:fetch_data)
    []
  end
end
