defmodule Queue do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_topic(queue, data) do
    GenServer.cast(queue, {:add, data})
  end

  def get_messages(topic) do
    GenServer.call(__MODULE__, {:get_messages, topic})
  end

  @impl true
  def init(_) do
    # Process.send_after(self(), :debug, 1000)
    {:ok, %{iot: [], sensors: []}}
  end

  @impl true
  def handle_info(:debug, state) do
    IO.inspect(state)
    Process.send_after(self(), :debug, 1000)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add, publisher_data}, state) do
    iot_data = state[:iot]
    sensors_data = state[:sensors]

    state = case publisher_data["topic"] do
      "iot" ->
        data = %{
          pressure: publisher_data["pressure"],
          wind: publisher_data["wind"],
          time: publisher_data["unix_timestamp_100us"]
        }
        Map.put(state, :iot, iot_data ++ [data])
      "sensors" ->
        data = %{
          light: publisher_data["light"],
          time: publisher_data["unix_timestamp_100us"]
        }
        Map.put(state, :sensors, sensors_data ++ [data])
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:get_messages, topic}, _from, state) do
    topic_atom = String.to_atom(topic)
    {
      :reply,
      Map.get(state, topic_atom),
      Map.put(state, topic_atom, [])
    }
  end
end
