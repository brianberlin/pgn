defmodule PGNWeb.NotificationLive.Index do
  use PGNWeb, :live_view

  alias PGN.{Repo, Notifications, Notifications.Notification}

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign_notifications()
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
  def handle_info({:notification, _pid, _ref, name, payload}, socket) do
    IO.inspect({name, payload})

    socket
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

  defp assign_notifications(socket) do
    {:ok, listener} = Repo.start_notification_listener()
    notifications = Notifications.list_notifications()
    Enum.each(notifications, fn notification ->
      {:ok, _ref} = Repo.listen(listener, Notifications.function_name(notification.id))
    end)
    assign(socket, :notifications, notifications)
  end
end
