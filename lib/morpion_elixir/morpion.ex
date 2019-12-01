defmodule MorpionElixir.Morpion do
  use GenServer
  alias __MODULE__
  alias MorpionElixer.Move

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(_) do
    # initial_board = generate_initial_board()

    # print_board(board)
    # move = Enum.at(initial_moves(), 2)
    # {board, taken_moves, possible_moves} = make_move(board, [], initial_moves(), move)

    # print_board(board)
    # IO.puts(length(taken_moves))
    # IO.puts(length(possible_moves))

    # moves = random_completion(initial_board, initial_moves())
    # IO.inspect(length(moves), label: "random completion score")

    # IO.inspect(is_move_valid(board, move))
    # IO.inspect(Enum.map(initial_moves(), fn move -> is_move_valid(board, move) end))

    GenServer.start_link(Morpion, {0}, name: Morpion)
  end

  def next_item do
    GenServer.call(Morpion, {:next_item})
  end

  def handle_call({:next_item}, _from, {curr_num}) do
    {:reply, curr_num, {curr_num + 1}}
  end
end
