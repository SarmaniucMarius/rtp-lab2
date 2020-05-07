defmodule PublisherServer do
  require Logger

  def start(port) do
    Logger.info("Starting publisher server")

    opts = [:binary, active: false]
    server_pid = case :gen_udp.open(port, opts) do
      {:ok, socket} -> spawn_link(__MODULE__, :loop_acceptor, [socket])
      {:error, reason} ->
        Logger.info("Could not start udp server! Reason: #{reason}")
        Process.exit(self(), reason)
    end
    {:ok, server_pid}
  end

  def loop_acceptor(socket) do
    case :gen_udp.recv(socket, 0) do
      {:ok, data} ->
        message = data |> elem(2) |> Poison.decode!
        Queue.add_topic(Queue, message)
      {:error, reason} ->
        Logger.info("Recv error! Reason: #{reason}")
        Process.exit(self(), reason)
    end
    loop_acceptor(socket)
  end

  def server(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        String.split(data, "!", trim: true)
        |> Enum.map(fn msg ->
          publisher_data = Poison.decode!(msg)
          Queue.add_topic(Queue, publisher_data)
        end)
      {:error, _reason} ->
        :gen_tcp.close(socket)
        Process.exit(self(), :normal)
    end

    server(socket)
  end
end
