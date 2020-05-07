defmodule PGNWeb.NotificationLive.FormComponent do
  use PGNWeb, :live_component

  alias PGN.{Notifications, Tables}

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign_changeset()
    |> assign_table_options()
    |> assign_field_options()
    |> assign_action()
    |> ok()
  end

  @impl true
  def handle_event("validate", %{"notification" => params}, socket) do
    socket
    |> assign_changeset(params)
    |> assign_field_options(params)
    |> noreply()
  end

  def handle_event("save", %{"notification" => notification_params}, socket) do
    save_notification(socket, socket.assigns.action, notification_params)
  end

  defp save_notification(socket, :edit, notification_params) do
    case Notifications.update_notification(socket.assigns.notification, notification_params) do
      {:ok, _notification} ->
        socket
        |> put_flash(:info, "Notification updated successfully")
        |> push_redirect(to: socket.assigns.return_to)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(:changeset, changeset)
        |> noreply()
    end
  end

  defp save_notification(socket, :new, notification_params) do
    case Notifications.create_notification(notification_params) do
      {:ok, _notification} ->
        socket
        |> put_flash(:info, "Notification created successfully")
        |> push_redirect(to: socket.assigns.return_to)
        |> noreply()

      {:error, %Ecto.Changeset{} = changeset} ->
        socket
        |> assign(changeset: changeset)
        |> noreply()
    end
  end

  defp assign_changeset(socket, params \\ %{}) do
    changeset =
      socket.assigns.notification
      |> Notifications.change_notification(params)
      |> Map.put(:action, :validate)

    assign(socket, :changeset, changeset)
  end

  defp field_names(table), do: Tables.get_field_options(table)

  defp assign_field_options(%{assigns: %{notification: %{table: table, fields: fields}}} = socket) do
    assign_field_options(socket, table, fields)
  end

  defp assign_field_options(%{assigns: %{notification: %{table: table}}} = socket) do
    assign_field_options(socket, table, [])
  end

  defp assign_field_options(socket, %{"table" => table, "fields" => fields}) do
    assign_field_options(socket, table, fields)
  end

  defp assign_field_options(socket, table, fields) do
    fields = Enum.map(field_names(table), &{&1, Enum.member?(fields, &1)})
    assign(socket, :fields, fields)
  end

  defp assign_table_options(socket) do
    assign(socket, :tables, PGN.Tables.get_table_options())
  end

  defp assign_action(%{assigns: %{notification: %{id: nil}}} = socket) do
    assign(socket, :action, :new)
  end

  defp assign_action(socket), do: assign(socket, :action, :edit)
end
