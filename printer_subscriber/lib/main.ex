defmodule Main do
  use Application
  require Logger

  def start(_, _) do
    port = 4054
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
        id: Printer,
        start: {Printer, :start_link, []}
      },
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)

    Logger.info("Server started!")

    receive do
      {:message_type, _value} -> IO.puts("Bye Bye")
    end

    {:ok, self()}
  end
end
