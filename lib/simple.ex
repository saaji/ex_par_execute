defmodule ParExecute.Simple do
  @doc "Naive parallel execution implementation"
  def naive_run(bulk_attrs) do
    bulk_attrs
    |> Enum.map(fn ({m, f, a}) -> Task.async(m, f, a) end)
    |> Enum.map(fn (task) -> Task.await(task) end)
  end

  @doc "Supervised naive parallel execution implementation"
  def naive_supervised_run(bulk_attrs) do
    bulk_attrs
    |> Enum.map(fn ({m, f, a}) ->
      Task.Supervisor.async(ParExecute.TaskSupervisor, fn() ->
        Kernel.apply(m, f, a)
      end)
    end)
    |> Enum.map(fn (task) -> Task.await(task) end)
  end

  @doc "Concurrently execute tasks in a list of {m, f, a}"
  def run(bulk_attrs) do
    do_run(&Task.Supervisor.async/2, bulk_attrs)
  end

  @doc "Concurrently execute tasks in a list of {m, f, a}, not crashing the caller"
  def run_nolink(bulk_attrs) do 
    do_run(&Task.Supervisor.async_nolink/2, bulk_attrs)
  end

  @doc "Execute a list of {m, f, a} as a sequence of concurrent batches"
  def batch(bulk_attrs, batch_size \\ 32) do 
    do_batch(&Task.Supervisor.async/2, bulk_attrs, batch_size)
  end

  @doc "Safe execute a list of {m, f, a} as a sequence of concurrent batches"
  def batch_nolink(bulk_attrs, batch_size \\ 32) do 
    do_batch(&Task.Supervisor.async_nolink/2, bulk_attrs, batch_size)
  end

  defp do_run(executor, bulk_attrs) do
    bulk_attrs
    |> Enum.map(fn ({m, f, a}) ->
      executor.(ParExecute.TaskSupervisor, fn() -> Kernel.apply(m, f, a) end)
    end)
    |> Enum.map(fn (task) -> Task.await(task) end)
  end

  defp do_batch(executor, bulk_attrs, batch_size) do
    bulk_attrs
    |> Enum.chunk(batch_size, batch_size, [])
    |> Enum.flat_map(fn (chunk) ->
      do_run(executor, chunk)
    end)
  end
end
