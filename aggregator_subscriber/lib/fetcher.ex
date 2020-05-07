defmodule Fetcher do
  require Logger

  def start(port) do
    Logger.info("Fetcher starting")
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> socket
      {:error, reason} ->
        Logger.info("Could not open UDP port! Reason: #{reason}")
        Process.exit(self(), reason)
    end
    pid = spawn_link(__MODULE__, :get_messages, [socket])
    {:ok, pid}
  end

  def send_notification(socket, host, port, topics) do
    case :gen_udp.send(socket, host, port, topics) do
      :ok ->
        Logger.info("Notification sent: #{topics}")
      {:error, reason} ->
        Logger.info("Could not send notification! Reason: #{reason}")
    end
  end

  def get_messages(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.inspect(data)
      {:error, reason} ->
        Logger.info("recv error in Fetcher get_message! Reason #{reason}")
    end
    # data_as_string = List.to_string(data)
    # String.split(data_as_string, "!", trim: true)
    # |> Enum.map(fn message ->
    #   IO.inspect(message)
    # end)
    # sensors_data = Poison.decode!(data)
    # IO.inspect(sensors_data)
    get_messages(socket)
  end
end
