defmodule IOT_processor do
  use GenServer
  require Logger

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
    weather_data = Poison.decode!(event)["message"]
    avg_waether_data = calc_avg(weather_data)
    encoded_weather_data = Poison.encode!(avg_waether_data)
    host = '127.0.0.1'
    case :gen_udp.send(socket, host, 4040, encoded_weather_data) do
      :ok -> IO.inspect(encoded_weather_data)
      {:error, reason} ->
        Logger.info("Could not send message! Reason: #{reason}")
    end

    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, _socket) do
    DynamicSupervisor.terminate_child(WorkersSupervisor, self())
  end

  defp calc_avg(data) do
    pressure_avg = (data["atmo_pressure_sensor_1"] + data["atmo_pressure_sensor_2"])/2
    wind_avg = (data["wind_speed_sensor_1"] + data["wind_speed_sensor_2"])/2
    %{
      topic: "iot",
      pressure: pressure_avg,
      wind: wind_avg,
      unix_timestamp_100us: data["unix_timestamp_100us"]
    }
  end

  defp get_name(name) do
    {:via, Registry, {:workers_registry, name}}
  end
end
