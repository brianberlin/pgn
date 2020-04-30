defmodule PGN.Notifications do
  @moduledoc """
  The Dashboard context.
  """

  import Ecto.Query, warn: false
  alias PGN.Repo

  alias PGN.Notifications.Notification

  @doc """
  Returns the list of notifications.

  ## Examples

      iex> list_notifications()
      [%Notification{}, ...]

  """
  def list_notifications do
    Repo.all(Notification)
  end

  @doc """
  Gets a single notification.

  Raises `Ecto.NoResultsError` if the Notification does not exist.

  ## Examples

      iex> get_notification!(123)
      %Notification{}

      iex> get_notification!(456)
      ** (Ecto.NoResultsError)

  """
  def get_notification!(id), do: Repo.get!(Notification, id)

  @doc """
  Creates a notification.

  ## Examples

      iex> create_notification(%{field: value})
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> insert_function()
    |> insert_trigger()
  end

  @doc """
  Updates a notification.

  ## Examples

      iex> update_notification(notification, %{field: new_value})
      {:ok, %Notification{}}

      iex> update_notification(notification, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_notification(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
    |> insert_function()
  end

  @doc """
  Deletes a notification.

  ## Examples

      iex> delete_notification(notification)
      {:ok, %Notification{}}

      iex> delete_notification(notification)
      {:error, %Ecto.Changeset{}}

  """
  def delete_notification(%Notification{} = notification) do
    notification
    |> Repo.delete()
    |> delete_trigger()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking notification changes.

  ## Examples

      iex> change_notification(notification)
      %Ecto.Changeset{data: %Notification{}}

  """
  def change_notification(%Notification{} = notification, attrs \\ %{}) do
    Notification.changeset(notification, attrs)
  end


  defp trigger_name(id), do: "app_trigger_#{id}"
  defp function_name(id), do: "app_function_#{id}"

  defp after_statement(%Notification{on_update: on_update, on_insert: on_insert, on_delete: on_delete}) do
    %{DELETE: on_delete, INSERT: on_insert, UPDATE: on_update}
      |> Enum.filter(&(elem(&1, 1)))
      |> Enum.to_list()
      |> Enum.map(fn {key, _} -> key end)
      |> Enum.join(" OR ")
  end

  defp function_fields(table, fields) do
    fields =
      fields
      |> Enum.map(&"'#{&1}', NEW.#{&1}")
      |> Enum.join(",")

    "'db_table', '#{table}', 'payload', json_build_object(#{fields})"
  end

  defp insert_function({:ok, %Notification{id: id, table: table, fields: fields} = notification}) do
    query =
      """
        CREATE OR REPLACE FUNCTION #{function_name(id)}()
        RETURNS trigger AS $$
        BEGIN
          PERFORM pg_notify(
            'notification',
            json_build_object(#{function_fields(table, fields)})::text
          );
        RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      """

    PGN.Repo.query!(query)
    |> IO.inspect()

    {:ok, notification}
  end

  defp insert_trigger({:ok, %Notification{id: id, table: table} = notification}) do
    query =
      """
        CREATE TRIGGER #{trigger_name(id)}
        AFTER #{after_statement(notification)}
        ON #{table}
        FOR EACH ROW
        EXECUTE PROCEDURE #{function_name(id)}()
      """

    PGN.Repo.query!(query)
    |> IO.inspect()

    {:ok, notification}
  end

  defp delete_trigger({:ok, %Notification{id: id, table: table} = notification}) do
    query =
      """
        DROP TRIGGER IF EXISTS #{trigger_name(id)}
        ON #{table} CASCADE
      """
    PGN.Repo.query!(query)
    {:ok, notification}

  end
end
