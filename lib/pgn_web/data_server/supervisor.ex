defmodule PGNWeb.DataServerSupervisor do
  @moduledoc """
  Starts, stops, and keeps track of running data servers
  """

  use DynamicSupervisor

  @ets_table_name :data_servers

  def start_link(init_arg \\ %{}) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc false
  def init(_init_arg) do
    :ets.new(@ets_table_name, [:set, :public, :named_table])
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Used by LiveView processes, Phoenix channels or any process that wants to
  subscribe to notifications about data changes for a data server with
  specific parameters
  """
  def subscribe(data_server, params) do
    case :ets.lookup(@ets_table_name, {data_server, params}) do
      [{_key, pid}] ->
        send(pid, {:subscribe, self()})

        pid

      [] ->
        # Start child with given params
        spec = {data_server, params}
        {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, spec)

        # and subscribe the live view process
        send(pid, {:subscribe, self()})

        # store dataserver pid in ets table
        :ets.insert(@ets_table_name, {{data_server, params}, pid})

        pid
    end
  end

  @doc """
  This function allows any module to access the data of a specified
  data server, and will default to applying that data server's fetch_data
  function if the data server is not currently running.
  """
  def retrieve_data(data_server, params) do
    case :ets.lookup(@ets_table_name, {data_server, params}) do
      [{_key, pid}] ->
        GenServer.call(pid, :retrieve_data)

      _ ->
        apply(data_server, :fetch_data, params)
    end
  end

  @doc """
  Kill a data server and remove it from the ets table
  """
  def kill(pid, data_server, params) do
    :ets.delete(@ets_table_name, {data_server, params})
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
