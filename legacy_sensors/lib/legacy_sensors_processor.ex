defmodule LegacySensors_Processor do
  use GenServer
  require Logger
  import SweetXml

  def start_link(name, socket) do
    GenServer.start_link(__MODULE__, socket, name: get_name(name))
  end

  def process_event(event_processor, event) do
    GenServer.cast(get_name(event_processor), {:process, event})
  end

  @impl true
  def init(socket) do
    {:ok, socket}
  end

  @impl true
  def handle_cast({:process, event}, socket) do
    data = Poison.decode!(event)["message"]
    IO.puts("=======================================")
    humidity = xpath(data, ~x"//humidity_percent/value"l, value: ~x"text()") |> get_avg
    temperature = xpath(data, ~x"//temperature_celsius/value"l, value: ~x"text()") |> get_avg
    time = xpath(data, ~x"//SensorReadings/@unix_timestamp_100us"l) |> List.first |> charlist_to_float |> Kernel.trunc
    avg_weather_data = %{
      topic: "legacy_sensors",
      humidity: humidity,
      temperature: temperature,
      unix_timestamp_100us: time,
    }
    encoded_weather_data = Poison.encode!(avg_weather_data)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 4040, encoded_weather_data) do
      :ok -> IO.inspect(encoded_weather_data)
      {:error, reason} ->
        Logger.info("Could not send message! Reason #{reason}")
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, _socket) do
    DynamicSupervisor.terminate_child(WorkersSupervisor, self())
  end

  defp get_avg(data_list) do
    first_element = List.first(data_list)[:value] |> charlist_to_float
    second_element = List.last(data_list)[:value] |> charlist_to_float
    (first_element + second_element)/2
  end

  defp charlist_to_float(value) do
    value |> to_string |> Float.parse |> elem(0)
  end

  defp get_name(name) do
    {:via, Registry, {:workers_registry, name}}
  end
end
