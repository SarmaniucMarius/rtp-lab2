defmodule Forcast do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket, name: __MODULE__)
  end

  def add_message(message) do
    GenServer.cast(__MODULE__, {:add_message, message})
  end

  @impl true
  def init(socket) do
    Process.send_after(self(), :forcast, 1000)
    {:ok, {socket, []}}
  end

  @impl true
  def handle_cast({:add_message, message}, state) do
    socket = elem(state, 0)
    messages = elem(state, 1)
    {:noreply, {socket, messages ++ [message]}}
  end

  @impl true
  def handle_info(:forcast, state) do
    socket = elem(state, 0)
    messages = elem(state, 1)

    if length(messages) > 0 do
      Enum.map(messages, fn message ->
        weather_forcast = forcast(
          message["humidity"], message["light"],
          message["pressure"], message["temperature"],
          message["wind"]
        )
        %{
          humidity:     message["humidity"],
          light:        message["light"],
          pressure:     message["pressure"],
          temperature:  message["temperature"],
          wind:         message["wind"],
          forcast:      weather_forcast,
          topic:        "forcast",
          unix_timestamp_100us: message["unix_timestamp_100us"],
        }
      end) |>
      Enum.each(fn message ->
        :gen_udp.send(socket, '127.0.0.1', 4040, Poison.encode!(message))
      end)
      IO.puts("Forcast sent!")
    end

    Process.send_after(self(), :forcast, 1000)
    {:noreply, {socket, []}}
  end

  defp forcast(humidity, light, pressure, temperature, wind) do
    cond do
      temperature < -2 && light < 128 && pressure < 720 -> "SNOW"
      temperature < -2 && light > 128 && pressure < 680 -> "WET_SNOW"
      temperature < -8 -> "SNOW"
      temperature < -15 && wind > 45 -> "BLIZZARD"
      temperature > 0 && pressure < 710 && humidity > 70 && wind < 20 -> "SLIGHT_RAIN"
      temperature > 0 && pressure < 690 && humidity > 70 && wind > 20 -> "HEAVY_RAIN"
      temperature > 30 && pressure < 770 && humidity > 80 && light > 192 -> "HOT"
      temperature > 30 && pressure < 770 && humidity > 50 && light > 192 && wind > 35 -> "CONVECTION_OVEN"
      temperature > 25 && pressure < 750 && humidity > 70 && light < 192 && wind < 10 -> "WARM"
      temperature > 25 && pressure < 750 && humidity > 70 && light < 192 && wind > 10 -> "SLIGHT_BREEZE"
      light < 128 -> "CLOUDY"
      temperature > 30 && pressure < 660 && humidity > 85 && wind > 45 -> "MONSOON"
      true -> "JUST_A_NORMAL_DAY"
    end
  end
end
