defmodule ResourceWorker do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def handle_cast({client, {m, f, a}}, state) do
    send client, {:ok, self, Kernel.apply(m, f, a)}
    {:noreply, state}
  end
end
