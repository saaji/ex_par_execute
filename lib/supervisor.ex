defmodule ParExecute.Supervisor do
  use Supervisor

  @name ParExecute.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end

  defp children do
    [supervisor(Task.Supervisor, [[name: ParExecute.TaskSupervisor]])]
  end
end
