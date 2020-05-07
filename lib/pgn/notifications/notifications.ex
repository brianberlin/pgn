defmodule PGN.Notifications do
  @moduledoc """
  The Dashboard context.
  """

  alias PGN.{Helpers, Notification}
  import PGN.Helpers

  @base_trigger_sql """
  SELECT
    trigger_name as name,
    string_agg(event_manipulation, ', ') as operations,
    event_object_table as table
  FROM
    information_schema.triggers
  """

  @list_triggers """
  #{@base_trigger_sql}
  WHERE
    trigger_name LIKE 'app_trigger_%'
  GROUP BY
    trigger_name, event_object_table
  """

  @get_trigger """
  #{@base_trigger_sql}
  WHERE
    trigger_name = $1
  GROUP BY
    trigger_name, event_object_table
  """

  @get_function "SELECT prosrc FROM pg_proc WHERE proname = $1"

  def list_notifications do
    @list_triggers
    |> query()
    |> Enum.map(&to_notification/1)
  end

  def get_notification(id) do
    @get_trigger
    |> query(["app_trigger_" <> id])
    |> List.first()
    |> to_notification()
  end

  defp to_notification(%{name: "app_trigger_" <> id, table: table, operations: operations} = trigger) do
    %Notification{
      id: id,
      table: table,
      on_insert: String.contains?(operations, "INSERT"),
      on_update: String.contains?(operations, "UPDATE"),
      on_delete: String.contains?(operations, "DELETE"),
      fields: get_fields(id)
    }
  end

  defp get_fields(id) do
    @get_function
    |> query(["app_function_#{id}"])
    |> List.first()
    |> parse_fields()
  end

  defp parse_fields(%{prosrc: prosrc}) do
    ~r/NEW\.([a-zA-Z_]+),/
    |> Regex.scan(prosrc)
    |> Enum.map(&Enum.at(&1, 1))
  end

  @doc """
  Creates a trigger.

  ## Examples

      iex> create_notification(%{field: value})
      {:ok, %Notification{}}

      iex> create_notification(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Ecto.Changeset.apply_changes()
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
  def delete_notification(%Notification{id: id, table: table} = notification) do
    query = "DROP FUNCTION #{function_name(id)} CASCADE"
    PGN.Repo.query!(query)
    {:ok, notification}
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


  defp function_fields(fields) do
    new_data =
      fields
      |> Enum.map(&"'#{&1}', NEW.#{&1}")
      |> Enum.join(",")

    old_data =
      fields
      |> Enum.map(&"'#{&1}', OLD.#{&1}")
      |> Enum.join(",")

    "'table', TG_TABLE_NAME, 'op', TG_OP, 'new_data', json_build_object(#{new_data}), 'old_data', json_build_object(#{old_data})"
  end

  defp insert_function(%Notification{id: id, table: table, fields: fields} = notification) do
    query =
      """
        CREATE OR REPLACE FUNCTION #{function_name(id)}()
        RETURNS trigger AS $$
        BEGIN
          PERFORM pg_notify(
            'notification',
            json_build_object(#{function_fields(fields)})::text
          );
        RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      """

    PGN.Repo.query!(query)

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

    {:ok, notification}
  end

end
