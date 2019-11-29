defmodule MorpionElixir.Conductor do
  use GenServer
  alias __MODULE__

  def init(num_workers) do
    Process.send_after(self(), :start_processing, 0)
    {:ok, num_workers}
  end

  def start_link(num_workers) do
    GenServer.start_link(Conductor, num_workers, name: Conductor)
  end

  def handle_info(:start_processing, num_workers) do
    1..num_workers
    |> Enum.each(fn _ -> MorpionElixir.WorkerSupervisor.add_worker() end)

    {:noreply, num_workers}
  end
end
