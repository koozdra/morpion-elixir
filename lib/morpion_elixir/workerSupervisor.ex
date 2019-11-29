defmodule MorpionElixir.WorkerSupervisor do
  use DynamicSupervisor

  @me WorkerSupervisor

  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(_) do
    a = MorpionElixer.Move.new(1, 2, 3, 4)
    IO.puts("here")
    IO.inspect(a)
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: @me)
  end

  def add_worker() do
    {:ok, _pid} = DynamicSupervisor.start_child(@me, MorpionElixir.Worker)
  end
end
