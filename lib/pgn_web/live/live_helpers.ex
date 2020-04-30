defmodule PGNWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers

  @doc """
  Renders a component inside the `PGNWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, PGNWeb.NotificationLive.FormComponent,
        id: @notification.id || :new,
        action: @live_action,
        notification: @notification,
        return_to: Routes.notification_index_path(@socket, :index) %>
  """
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(socket, PGNWeb.ModalComponent, modal_opts)
  end

  def noreply(socket), do: {:noreply, socket}
  def ok(socket), do: {:ok, socket}
end
