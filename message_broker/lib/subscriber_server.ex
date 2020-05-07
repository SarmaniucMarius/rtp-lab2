defmodule SubscriberServer do
  require Logger

  def start(port) do
    Logger.info("Starting subscriber server")

    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> socket
      {:error, reason} ->
        Logger.info("Could not open UDP port! Reason: #{reason}")
        Process.exit(self(), reason)
    end
    pid = spawn_link(__MODULE__, :get_topics, [socket])
    spawn(__MODULE__, :broadcast, [socket])
    {:ok, pid}
  end

  def get_topics(socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, data} ->
        subscriber = {elem(data, 0), elem(data, 1)}
        topics = elem(data, 2) |> String.split("/", trim: true)
        Sender.update_subscriber_topics(subscriber, topics)
      {:error, reason} ->
        Logger.info("Recv error! Reason: #{reason}")
        Process.exit(self(), reason)
    end
    get_topics(socket)
  end

  def broadcast(socket) do
    Sender.broadcast_messages(socket)
    Process.sleep(10)
    broadcast(socket)
  end
end
