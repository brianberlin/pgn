defmodule PGN.Repo do
  use Ecto.Repo,
    otp_app: :postgres_pgnotify,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Each listener will open a database connection so only 1 should be started
  per process like a DataServer
  """
  def start_notification_listener() do
    Postgrex.Notifications.start_link(__MODULE__.config())
  end

  @doc """
  Tell the listening process to listen for notifications on a certain channel
  and send the notifications to the calling process
  """
  def listen(listener, channel_name) do
    Postgrex.Notifications.listen(listener, channel_name)
  end
end
