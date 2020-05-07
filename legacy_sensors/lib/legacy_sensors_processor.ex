defmodule LegacySensors_Processor do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name], name: get_name(name))
  end

  def process_event(event_processor, event) do
    GenServer.cast(get_name(event_processor), {:process, event})
  end

  @impl true
  def init(_) do
    # host = "127.0.0.1" |> String.to_charlist
    # opts = [active: false, packet: 0]
    # {:ok, sock} = :gen_tcp.connect(host, 4040, opts)
    # {:ok, sock}
    {:ok, 1}
  end

  @impl true
  def handle_cast({:process, event}, sock) do
    # IO.inspect(event)
    foo = XmlToMap.naive_map("<foo><point><x>1</x><y>5</y></point><point><x>2</x><y>9</y></point></foo>")
    IO.puts(foo)
    # IO.inspect(event)
    # :gen_tcp.send(sock, event)

    {:noreply, sock}
  end

  @impl true
  def terminate(_reason, sock) do
    # :gen_tcp.close(sock)
    DynamicSupervisor.terminate_child(WorkersSupervisor, self())
  end

  defp get_name(name) do
    {:via, Registry, {:workers_registry, name}}
  end
end
