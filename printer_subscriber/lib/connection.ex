defmodule Connection do
  require Logger

  def start(socket) do
    Logger.info("Connection starting")
    send_notification(socket, 'localhost', 4050, "aggregator")
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
        message = elem(data, 2)
        decoded_message = Poison.decode!(message)
        Printer.add_message(decoded_message)
      {:error, reason} ->
        Logger.info("recv error in Fetcher get_message! Reason #{reason}")
    end
    get_messages(socket)
  end
end
