defmodule Joiner do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, name: __MODULE__)
  end

  def add_message(message) do
    GenServer.cast(__MODULE__, {:add_message, message})
  end

  @impl true
  def init(socket) do
    Process.send_after(self(), :aggregate, 10000)
    {:ok, {%{}, socket}}
  end

  @impl true
  def handle_info(:aggregate, state) do
    messages = elem(state, 0)
    socket = elem(state, 1)

    iot_messages = Map.get(messages, "iot", [])
    sensors_messages = Map.get(messages, "sensors", [])
    legacy_sensors_messages = Map.get(messages, "legacy_sensors", [])

    aggregated_messages = Enum.map(iot_messages, fn iot_message ->
      iot_timestamp = iot_message["unix_timestamp_100us"]
      sensors_message = Enum.find(sensors_messages, fn sensors_message ->
        sensors_timestamp = sensors_message["unix_timestamp_100us"]
        ((iot_timestamp - sensors_timestamp) <= 100) &&
        ((iot_timestamp - sensors_timestamp) >= -100)
      end)
      legacy_sensors_message = Enum.find(legacy_sensors_messages, fn sensors_message ->
        legeacy_sensors_timestamp = sensors_message["unix_timestamp_100us"]
        ((iot_timestamp - legeacy_sensors_timestamp) <= 100) &&
        ((iot_timestamp - legeacy_sensors_timestamp) >= -100)
      end)
      if (sensors_message != nil)
      && (legacy_sensors_message != nil) do
        %{
          pressure: iot_message["pressure"],
          wind: iot_message["wind"],
          light: sensors_message["light"],
          humidity: legacy_sensors_message["humidity"],
          temperature: legacy_sensors_message["temperature"],
          unix_timestamp_100us: iot_message["unix_timestamp_100us"],
          topic: "joiner"
        }
      else
        nil
      end
    end)

    if aggregated_messages != nil do
      Enum.each(aggregated_messages, fn message ->
        if message != nil do
          :gen_udp.send(socket, '127.0.0.1', 4040, Poison.encode!(message))
        end
      end)
      IO.puts("Joined and sent!")
    end

    Process.send_after(self(), :aggregate, 1000)
    {:noreply, {%{}, socket}}
  end

  @impl true
  def handle_cast({:add_message, message}, state) do
    messages = elem(state, 0)
    socket = elem(state, 1)

    topic = message["topic"]
    current_messages = Map.get(messages, topic, [])
    new_state = Map.put(messages, topic, current_messages ++ [message])
    {:noreply, {new_state, socket}}
  end
end
