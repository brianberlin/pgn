defmodule PGN.Notifications.Listener do
  use GenServer
  alias PGN.Repo

  def start_link(_) do
    GenServer.start_link(__MODULE__, self())
  end

  def init(pid) do
    with {:ok, listener} <- Repo.start_notification_listener(),
         {:ok, _ref} <- Repo.listen(listener, "notification") do
      {:ok, pid: pid}
    else
      error ->
        {:stop, error}
    end
  end

  def handle_info({:notification, _pid, _ref, channel, payload}, state) do
    unless is_nil(state[:pid]) do
      send(state[:pid], {:notification, channel, Jason.decode!(payload)})
    end

    {:noreply, state}
  end
end
