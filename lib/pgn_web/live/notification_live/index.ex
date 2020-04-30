defmodule PGNWeb.NotificationLive.Index do
  use PGNWeb, :live_view

  alias PGN.{Notifications, Notifications.Notification}
  alias PGNWeb.{DataServerSupervisor, NotificationLive.DataServer}

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> connect_to_data_server()
    |> assign_notifications()
    |> assign_notification_log()
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> apply_action(socket.assigns.live_action, params)
    |> noreply()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    notification = Notifications.get_notification!(id)
    {:ok, _} = Notifications.delete_notification(notification)

    socket
    |> assign(:notifications, Notifications.list_notifications())
    |> noreply()
  end

  @impl true
  def handle_info({PGNWeb.NotificationLive.DataServer, data}, socket) do
    socket
    |> assign_notification_log(data)
    |> noreply()
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Notification")
    |> assign(:notification, Notifications.get_notification!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Notification")
    |> assign(:notification, %Notification{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Notifications")
    |> assign(:notification, nil)
  end

  defp assign_notification_log(socket) do
    assign(socket, :notification_log, [])
  end

  defp assign_notification_log(%{assigns: %{notification_log: notification_log}} = socket, data) do
    assign(socket, :notification_log, ["#{inspect(data)}"] ++ notification_log)
  end

  defp assign_notifications(socket) do
    notifications = Notifications.list_notifications()
    assign(socket, :notifications, notifications)
  end

  defp connect_to_data_server(socket) do
    if connected?(socket) do
      DataServerSupervisor.subscribe(DataServer, [])
    end
    socket
  end
end
