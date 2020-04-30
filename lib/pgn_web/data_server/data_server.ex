defmodule PGNWeb.DataServer do
  @moduledoc """
  Data servers are used to cache data and watch for notifications
  about data changes for specific Live Views, mobile views or anything else
  interested in that data. They have 3 main purposes:

    1. They watch for notifications from pg_notify (or possibly other sources)
       about changes to relevant data
    2. They cache and broadcast that data for all watching processes to use
    3. They close themselves when there are no more watching processes

  This module creates a __using__ macro to ensure all data servers can handle
  processes subscribing to their data and handle when those processes go down.
  It is also a behaviour to ensure the data servers have a certain interface
  """

  @doc "All data servers will need to fetch data. This is public for testing"
  @callback fetch_data(any()) :: any()

  defmacro __using__(_opts) do
    quote do
      use GenServer
      alias PGNWeb.DataServerSupervisor

      @behaviour PGNWeb.DataServer

      def start_link(params) do
        GenServer.start_link(__MODULE__, params)
      end

      # When a process crashes, remove it from the list of processes in the state
      # then tell the supervisor to kill this data server if there are no more
      # processes subscribed to it
      def handle_info({:DOWN, _ref, :process, pid, _}, state) do
        processes = List.delete(state.processes, pid)

        if Enum.empty?(processes) do
          DataServerSupervisor.kill(self(), __MODULE__, state.initial_params)
          {:noreply, state}
        else
          state = Map.put(state, :processes, processes)
          {:noreply, state}
        end
      end

      # When a process subscribes to changes to the data, monitor the process
      # to know when it goes down, send it the data from the state then add it
      # to the list of processes in the state
      def handle_info({:subscribe, pid}, %{data: data, processes: processes} = state) do
        IO.inspect({pid, data, processes}, label: "handle_info_subscribe")
        Process.monitor(pid)
        processes = [pid | processes]
        new_state = Map.put(state, :processes, processes)
        send(pid, {__MODULE__, data})
        {:noreply, new_state}
      end

      # This is to handle a bug in hackney that causes :ssl_closed messages to
      # be sent to the process
      # https://github.com/benoitc/hackney/issues/464
      def handle_info({:ssl_closed, _message}, state) do
        IO.inspect({:ssl_closed}, label: "handle_info_ssl_closed")
        {:noreply, state}
      end

      @doc """
      Handles incoming message from a given process that wants the current state.data
      Just returns the same __MODULE__ message as `broadcast_data`
      """
      def handle_call(:retrieve_data, _from, %{data: data} = state) do
        IO.inspect({:retrieve_data, data}, label: "handle_info_retrieve_data")

        {:reply, data, state}
      end

      defp broadcast_data(data, processes) do
        IO.inspect({:broadcast_data, processes}, label: "broadcast_data")
        Enum.each(processes, fn pid ->
          send(pid, {__MODULE__, data})
        end)
      end
    end
  end
end
