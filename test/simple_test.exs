defmodule ParExecute.SimpleTest do
  use ExUnit.Case
  alias ParExecute.Simple

  defp sum(l) when is_list(l), do: Enum.reduce(l, &+/2)

  setup do
    attrs = Enum.map(1 .. 100, fn x -> {Kernel, :*, [x, x]} end)
    res =
      Enum.map(1 .. 100, fn x -> x * x end)
      |> sum

    {:ok, attrs: attrs, sample: res}
  end

  test "naive run", %{attrs: attrs, sample: sample} do
    res = attrs |> Simple.naive_run |> sum
    assert sample == res
  end

  test "naive supervised run", %{attrs: attrs, sample: sample} do
    res = attrs |> Simple.naive_supervised_run |> sum
    assert sample == res
  end

  test "run", %{attrs: attrs, sample: sample} do
    res = attrs |> Simple.run |> sum
    assert sample == res
  end

  test "nolink run", %{attrs: attrs, sample: sample} do
    res = attrs |> Simple.run_nolink |> sum
    assert sample == res
  end

  test "batch", %{attrs: attrs, sample: sample} do
    res = attrs |> Simple.batch |> sum
    assert sample == res
  end

  test "nolink batch", %{attrs: attrs, sample: sample} do
    res = attrs |> Simple.batch_nolink |> sum
    assert sample == res
  end
end
