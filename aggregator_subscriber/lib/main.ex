defmodule Main do
  use Application
  require Logger

  def start(_, _) do
    children = [
      %{
        id: Fetcher,
        start: {Fetcher, :start, [4051]}
      }
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)

    Logger.info("Aggregator started!")

    receive do
      {:message_type, _value} -> IO.puts("Bye bye")
    end

    {:ok, self()}
  end
end
