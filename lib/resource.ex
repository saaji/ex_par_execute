defmodule ParExecute.Resource do
  use Retry
  use GenServer

  @worker_take_wait_ms 100
  @worker_timeout_ms 5000
  @max_timeout_ms @worker_timeout_ms + 1000

  def start_link(config, opts \\ []) do
    GenServer.start_link(config, opts)
  end

  def init(config) do
    ensure_worker_pool_ready(config)
    workers = :ets.new(:"resource_workers_#{config[:name]}", [:private])

    {:ok, %{config: config, workers: workers}}
  end

  def execute(mfa, pid) do
    backoff @worker_timeout_ms do
      GenServer.call(pid, {:execute, mfa}, @max_timeout_ms)
    end
  end

  def batch(bulk_attrs, pid, batch_size \\ 32) do
    do_batch(bulk_attrs, pid, batch_size)
  end

  # Server Callbacks

  def handle_call({:execute, mfa}, client, state) do
    run_async({self, mfa}, client, state)
  end

  def handle_info({:ok, worker, res}, state) do
    notify_client(state, worker, {:ok, res})
    {:noreply, state}
  end

  def handle_info({:worker_timeout, worker}, state) do
    notify_client(state, worker, {:error, :worker_timeout})
    {:noreply, state}
  end

  # Utility

  defp default_config do
    [group: :resources,
     start_mfa: {ResourceWorker, :start_link, []}]
  end

  defp ensure_worker_pool_ready(config) do
    cfg = config ++ default_config
    :pooler.rm_pool(cfg[:name])
    :pooler.new_pool(cfg)
  end

  defp run_async(msg, client, state) do
    config = state.config
    case :pooler.take_member(config[:name], @worker_take_wait_ms) do
      :error_no_members ->
        {:reply, {:error, :no_free_workers}, state}
      worker ->
        timer = Process.send_after(self, {:worker_timeout, worker}, @worker_timeout_ms)
        true = :ets.insert(state.workers, {worker, {client, timer}})
        GenServer.cast(worker, msg)
        {:noreply, state}
    end
  end

  defp notify_client(%{workers: workers, config: config}, worker, msg) do
    case :ets.lookup(workers, worker) do
      [{worker, {client, timer}}] ->
        Process.cancel_timer(timer)
        :ets.delete(workers, worker)
        :pooler.return_member(config[:name], worker, :fail)
        GenServer.reply(client, msg)
      [] -> true
    end
  end

  defp do_run(bulk_attrs, pid) do
    bulk_attrs
    |> Enum.map(fn (mfa) ->
      Task.Supervisor.async(ParExecute.TaskSupervisor, fn() ->
        execute(mfa, pid)
      end)
    end)
    |> Enum.map(fn (task) -> Task.await(task) end)
  end

  defp do_batch(bulk_attrs, pid, batch_size) do
    bulk_attrs
    |> Enum.chunk(batch_size, batch_size, [])
    |> Enum.flat_map(fn (chunk) ->
      do_run(chunk, pid)
    end)
  end
end
