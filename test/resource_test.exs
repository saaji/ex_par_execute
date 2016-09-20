defmodule ParExecute.ResourceTest do
  use ExUnit.Case
  alias ParExecute.Simple
  alias ParExecute.Resource

  defp gen_resource(name) do
    config = [name: name, init_count: 2, max_count: 128]
    {:ok, pid} = GenServer.start_link(Resource, config)
    pid
  end

  test "single job" do
    r = gen_resource(:test_single)
    res = Resource.execute({Kernel, :*, [2, 2]}, r)
    assert {:ok, 4} == res
  end

  test "woker timeout" do
    r = gen_resource(:test_timeout)
    res = Resource.execute({:timer, :sleep, [100000]}, r)
    assert {:error, :worker_timeout} == res
  end

  test "single batch" do
    r = gen_resource(:batch_execute)
    sample = Enum.map(1 .. 1000, fn x -> {:ok, x * x} end)
    bulk_attrs = Enum.map(1 .. 1000, fn x -> {Kernel, :*, [x, x]} end)

    assert sample == Resource.batch(bulk_attrs, r)
  end

  test "multiple concurrent batches" do
    r = gen_resource(:multi_batch_execute)
    sample = Enum.map(1 .. 1000, fn x -> {:ok, x * x} end)
    bulk_attrs = Enum.map(1 .. 1000, fn x -> {Kernel, :*, [x, x]} end)
    batches = Enum.map(1 .. 4, fn _ -> {Resource, :batch, [bulk_attrs, r]} end)

    for res <- Simple.naive_run(batches) do
      assert sample == res
    end
  end
end
