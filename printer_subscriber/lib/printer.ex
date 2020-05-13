defmodule Printer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_message(message) do
    GenServer.cast(__MODULE__, {:add_message, message})
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :print_forcast, 3000)
    {:ok, []}
  end

  @impl true
  def handle_cast({:add_message, message}, state) do
    {:noreply, state ++ [message]}
  end

  @impl true
  def handle_info(:print_forcast, messages) do
    sensors_data = List.first(messages)
    if sensors_data != nil do
      time_stamp = sensors_data["unix_timestamp_100us"] |>
        Integer.to_string |>
        String.slice(0..9) |>
        String.to_integer() |>
        DateTime.from_unix() |>
        elem(1) |> DateTime.add(10800, :second)
      humidity = sensors_data["humidity"] |> Float.round(2)
      light = sensors_data["light"] |> Float.round(2)
      pressure = sensors_data["pressure"] |> Float.round(2)
      temperature = sensors_data["temperature"] |> Float.round(2)
      wind = sensors_data["wind"] |> Float.round(2)
      forcast = sensors_data["forcast"]
      IO.puts("=================================")
      IO.puts("FORCAST ON #{time_stamp.day}.#{time_stamp.month}.#{time_stamp.year}, AT #{time_stamp.hour}:#{time_stamp.minute}:#{time_stamp.second}")
      IO.puts("---------------------------------")
      IO.puts("#{forcast}")
      IO.puts("---------------------------------")
      IO.puts("Humidity: #{humidity}")
      IO.puts("Light: #{light}")
      IO.puts("Pressure: #{pressure}")
      IO.puts("Temperature: #{temperature}")
      IO.puts("Wind: #{wind}")
      IO.puts("=================================")
    end
    Process.send_after(self(), :print_forcast, 3000)
    {:noreply, List.delete_at(messages, 0)}
  end
end
