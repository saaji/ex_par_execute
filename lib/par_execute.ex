defmodule ParExecute do
  use Application

  def start(_type, _args) do
    ParExecute.Supervisor.start_link()
  end
end
