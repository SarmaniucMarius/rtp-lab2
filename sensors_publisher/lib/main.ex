defmodule Main do
  use Application

  def start(_, _) do
    children = [
      {
        Registry,
        [keys: :unique, name: :workers_registry]
      },
      %{
        id: WorkersSupervisor,
        start: {WorkersSupervisor, :start_link, []},
        type: :supervisor
      },
      %{
        id: Fetcher,
        start: {Fetcher, :start_link, ["http://localhost:4000/sensors"]}
      },
      %{
        id: Scheduler,
        start: {Scheduler, :start_link, [5]}
      },
    ]

    opts = [strategy: :one_for_one, name: IOT_Supervisor]
    Supervisor.start_link(children, opts)
    IO.puts("Sensors supervisor started!")

    receive do
      {:message_type, _value} -> IO.puts("Bye bye")
    end

    {:ok, self()}
  end
end
