defmodule Broker_Connection do
  require Logger

  def start(port) do
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} ->
        Logger.info("Opened UDP port on: #{port}")
        socket
      {:error, reason} ->
        Logger.info("Could not open UDP port! Reason: #{reason}")
        Process.exit(self(), reason)
    end

    pid = spawn_link(__MODULE__, :get_messages, [socket])
    spawn(__MODULE__, :get_user_input, [socket])
    {:ok, pid}
  end

  def get_user_input(socket) do
    topic = IO.gets("Enter topic to subscribe to: ") |> String.trim("\n")
    send_notification(socket, 'localhost', 4050, topic)
    MQTT_Connection.set_topic(topic)

    get_user_input(socket)
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
        MQTT_Connection.publish_message(message)
      {:error, reason} ->
        Logger.info("recv error in Fetcher get_message! Reason #{reason}")
    end
    get_messages(socket)
  end
end
