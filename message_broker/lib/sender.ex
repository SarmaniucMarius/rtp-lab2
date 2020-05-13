defmodule Sender do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def update_subscriber_topics(subscriber, topics) do
    GenServer.cast(__MODULE__, {:update_topics, subscriber, topics})
  end

  def broadcast_messages(socket) do
    GenServer.cast(__MODULE__, {:broadcast, socket})
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:update_topics, subscriber, topics}, state) do
    new_state = Map.put(state, subscriber, topics)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:broadcast, socket}, state) do
    Enum.each(state, fn {host_info, topics} ->
      Enum.each(topics, fn topic ->
        messages = Queue.get_messages(topic)
        if messages != nil do
          Enum.each(messages, fn message ->
            encoded_message = Poison.encode!(message)
            address = elem(host_info, 0)
            port = elem(host_info, 1)
            case :gen_udp.send(socket, address, port, encoded_message) do
              :ok -> 0
              {:error, reason} ->
                Logger.info("Could not send packet! Reasaon: #{reason}")
            end
          end)
        end
      end)
    end)
    Enum.each(state, fn {_host_info, topics} ->
      Enum.each(topics, fn topic ->
        Queue.clear_messages(topic)
      end)
    end)
    {:noreply, state}
  end

end
