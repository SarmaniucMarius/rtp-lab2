defmodule Aggregator do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, name: __MODULE__)
  end

  def add_message(message) do
    GenServer.cast(__MODULE__, {:add_message, message})
  end

  @impl true
  def init(socket) do
    Process.send_after(self(), :aggregate, 1000)
    {:ok, {socket, []}}
  end

  @impl true
  def handle_cast({:add_message, message}, state) do
    socket = elem(state, 0)
    messages = elem(state, 1)
    {:noreply, {socket, messages ++ [message]}}
  end

  @impl true
  def handle_info(:aggregate, state) do
    socket = elem(state, 0)
    messages = elem(state, 1)

    if length(messages) > 0 do
      forcast = Enum.map(messages, fn message -> message["forcast"] end) |>
        Enum.frequencies |>
        Map.to_list |>
        Enum.sort_by(&(elem(&1, 1)), :desc) |> hd |> elem(0)

      most_frequent_messages = Enum.filter(messages, fn message ->
        message["forcast"] === forcast
      end)
      time = hd(most_frequent_messages)["unix_timestamp_100us"]
      humidity = sum(most_frequent_messages, "humidity") / length(most_frequent_messages)
      light = sum(most_frequent_messages, "light") / length(most_frequent_messages)
      pressure = sum(most_frequent_messages, "pressure") / length(most_frequent_messages)
      temperature = sum(most_frequent_messages, "temperature") / length(most_frequent_messages)
      wind = sum(most_frequent_messages, "wind") / length(most_frequent_messages)

      weather = %{
        forcast: forcast,
        humidity: humidity,
        light: light,
        pressure: pressure,
        temperature: temperature,
        wind: wind,
        unix_timestamp_100us: time,
        topic: "aggregator",
      }

      :gen_udp.send(socket, '127.0.0.1', 4040, Poison.encode!(weather))
      IO.puts("Aggregated and sent!")
    end



    Process.send_after(self(), :aggregate, 1000)
    {:noreply, {socket, messages}}
  end

  defp sum(messages, key) do
    Enum.reduce(messages, 0, fn message, acc ->
      message[key] + acc
    end)
  end
end
