defmodule Main do
  use Application
  require Logger

  def start(_, _) do
    port = 4051
    opts = [:binary, active: false]
    socket = case :gen_udp.open(port, opts) do
      {:ok, socket} -> socket
      {:error, reason} ->
        Logger.info("Could not open UDP port! Reason: #{reason}")
        Process.exit(self(), reason)
    end

    children = [
      %{
        id: Connection,
        start: {Connection, :start, [socket]}
      },
      %{
        id: Joiner,
        start: {Joiner, :start_link, [socket]}
      },
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)

    Logger.info("Joiner started!")

    receive do
      {:message_type, _value} -> IO.puts("Bye bye")
    end

    {:ok, self()}
  end
end
