defmodule WorkersSupervisor do
  use DynamicSupervisor

  def start_link do
    IO.puts("Starting workers supervisor")
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    spec = %{
      id: LegacySensors_Processor,
      start: {LegacySensors_Processor, :start_link, [name]},
      restart: :temporary
    }
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def delete_child(name) do
    DynamicSupervisor.terminate_child(__MODULE__, name)
  end
end
