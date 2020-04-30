defmodule PGNWeb.NotificationLive.Show do
  use PGNWeb, :live_view

  alias PGN.Notifications

  @impl true
  def mount(_params, _session, socket) do
    ok(socket)
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:notification, Notifications.get_notification!(id))
     |> noreply()
  end

  defp page_title(:show), do: "Show Notification"
  defp page_title(:edit), do: "Edit Notification"
end
