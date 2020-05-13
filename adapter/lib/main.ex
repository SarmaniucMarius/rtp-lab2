defmodule Main do
  use Application
  require Logger

  def start(_, _) do
    children = [
      %{
        id: MQTT_Connection,
        start: {MQTT_Connection, :start_link, [1883]}
      },
      %{
        id: Broker_Connection,
        start: {Broker_Connection, :start, [4055]}
      }
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)

    receive do
      {:message_type, _value} -> IO.puts("Bye bye!")
    end

    {:ok, self()}
  end
end
