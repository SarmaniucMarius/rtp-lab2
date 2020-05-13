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

  def clear_messages(topic) do
    GenServer.cast(__MODULE__, {:clear_messages, topic})
  end

  @impl true
  def init(_) do
    # Process.send_after(self(), :debug, 1000)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:debug, state) do
    IO.inspect(Map.keys(state))
    Process.send_after(self(), :debug, 1000)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add, publisher_data}, state) do
    topic = publisher_data["topic"]
    current_data = Map.get(state, topic, [])
    new_state = Map.put(state, topic, current_data ++ [publisher_data])

    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get_messages, topic}, _from, state) do
    {
      :reply,
      Map.get(state, topic),
      state
    }
  end

  @impl true
  def handle_cast({:clear_messages, topic}, state) do
    {:noreply, Map.put(state, topic, [])}
  end
end
