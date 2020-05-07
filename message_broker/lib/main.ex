defmodule Main do
  use Application
  require Logger

  def start(_, _) do
    children = [
      %{
        id: PublisherServer,
        start: {PublisherServer, :start, [4040]}
      },
      %{
        id: SubscriberServer,
        start: {SubscriberServer, :start, [4050]}
      },
      %{
        id: Sender,
        start: {Sender, :start_link, []}
      },
      %{
        id: Queue,
        start: {Queue, :start_link, []}
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
