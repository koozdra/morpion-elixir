defmodule MorpionElixir.Worker do
  use GenServer
  alias __MODULE__

  def init(:no_args) do
    Process.send_after(self(), :process_item, 0)
    {:ok, nil}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def handle_info(:process_item, state) do
    MorpionElixir.Morpion.next_item()
    |> process_item()

    Process.send_after(self(), :process_item, 0)

    {:noreply, state}
  end

  defp process_item(item) do
    IO.puts("processing #{item}")
    :timer.sleep(1000)
  end
end
