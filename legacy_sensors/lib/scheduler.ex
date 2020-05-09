defmodule Scheduler do
  use GenServer
  require Logger

  def start_link(workers_count) do
    GenServer.start_link(__MODULE__, workers_count, name: Scheduler)
  end

  def get_workers(scheduler_pid) do
    GenServer.call(scheduler_pid, :get_workers)
  end

  @impl true
  def init(workers_count) do
    IO.puts("Starting scheduler")

    opts = [:binary, active: false]
    socket = case :gen_udp.open(4043, opts) do
      {:ok, socket} -> socket
      {:error, reason} ->
        Logger.info("Could not open UDP port! Reason: #{reason}")
        Process.exit(self(), :normal)
    end

    workers = 1..workers_count |>
    Enum.map(fn id ->
      worker = "Worker #{id}"
      WorkersSupervisor.start_child(worker, socket)
      worker
    end) |> List.to_tuple

    Process.send_after(self(), :events, 500)

    {:ok, {workers, workers_count, 0, socket}}
  end

  @impl true
  def handle_info(:events, state) do
    workers = elem(state, 0)
    workers_count = elem(state, 1)
    event_count = elem(state, 2)
    socket = elem(state, 3)

    wanted_workers_count = cond do
      event_count <= 100 -> 5
      event_count <= 300 -> 10
      event_count >  300 -> 15
    end

    # Start workers that crashed
    1..workers_count |>
    Enum.map(fn id ->
      worker = "Worker #{id}"
      WorkersSupervisor.start_child(worker, socket)
    end)

    additional_workers =  wanted_workers_count - workers_count
    workers = cond do
      additional_workers > 0 ->
        result = workers_count+1..wanted_workers_count |>
        Enum.map(fn id ->
          worker = "Worker #{id}"
          WorkersSupervisor.start_child(worker, socket)
          worker
        end)
        Tuple.to_list(workers) ++ result |> List.to_tuple

      additional_workers < 0 ->
        result = wanted_workers_count+1..workers_count |>
        Enum.map(fn id ->
          worker = "Worker #{id}"
          worker_list = Registry.lookup(:workers_registry, worker)
          if length(worker_list) > 0 do
            hd(worker_list) |>
            elem(0) |>
            WorkersSupervisor.delete_child
          end
          worker
        end)
        Tuple.to_list(workers) -- result |> List.to_tuple

      true -> workers # if total_workers_count = 0 do nothing
    end

    Process.send_after(self(), :events, 500)
    {:noreply, {workers, wanted_workers_count, 0, socket}}
  end

  @impl true
  def handle_call(:get_workers, _, state) do
    workers = elem(state, 0)
    workers_count = elem(state, 1)
    event_count = elem(state, 2) + 1
    socket = elem(state, 3)
    {:reply, workers, {workers, workers_count, event_count, socket}}
  end
end
