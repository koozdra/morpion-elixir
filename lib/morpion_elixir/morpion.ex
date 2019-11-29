defmodule MorpionElixir.Morpion do
  use GenServer
  alias __MODULE__
  alias MorpionElixer.Move

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(_) do
    board = generate_initial_board()
    # IO.inspect(board, label: "karen")
    print_board(board)

    GenServer.start_link(Morpion, {0}, name: Morpion)
  end

  def next_item do
    GenServer.call(Morpion, {:next_item})
  end

  def handle_call({:next_item}, _from, {curr_num}) do
    {:reply, curr_num, {curr_num + 1}}
  end

  defp initial_moves() do
    [
      Move.new(3, -1, 3, 0),
      Move.new(6, -1, 3, 0),
      Move.new(2, 0, 1, 0),
      Move.new(7, 0, 1, -4),
      Move.new(3, 4, 3, -4),
      Move.new(7, 2, 2, -2),
      Move.new(6, 4, 3, -4),
      Move.new(0, 2, 3, 0),
      Move.new(9, 2, 3, 0),
      Move.new(-1, 3, 1, 0),
      Move.new(4, 3, 1, -4),
      Move.new(0, 7, 3, -4),
      Move.new(5, 3, 1, 0),
      Move.new(10, 3, 1, -4),
      Move.new(9, 7, 3, -4),
      Move.new(2, 2, 0, -2),
      Move.new(2, 7, 2, -2),
      Move.new(3, 5, 3, 0),
      Move.new(6, 5, 3, 0),
      Move.new(-1, 6, 1, 0),
      Move.new(4, 6, 1, -4),
      Move.new(3, 10, 3, -4),
      Move.new(5, 6, 1, 0),
      Move.new(10, 6, 1, -4),
      Move.new(6, 10, 3, -4),
      Move.new(2, 9, 1, 0),
      Move.new(7, 9, 1, -4),
      Move.new(7, 7, 0, -2)
    ]
  end

  defp direction_offsets do
    [{1, -1}, {1, 0}, {1, 1}, {0, 1}]
  end

  defp board_index_at(x, y) do
    (x + 15) * 40 + (y + 15)
  end

  defp mask_x do
    1
  end

  defp generate_initial_board do
    initial_moves()
    |> Enum.flat_map(fn move ->
      Enum.map(0..3, fn offset ->
        {move, offset}
      end)
    end)
    |> Enum.filter(fn {{move_x, move_y, move_direction, move_start_offset}, offset} ->
      {delta_x, delta_y} = Enum.at(direction_offsets(), move_direction)
      combined_offset = offset + move_start_offset
      x = move_x + delta_x * combined_offset
      y = move_y + delta_y * combined_offset
      x != move_x || y != move_y
    end)
    |> Enum.map(fn {{move_x, move_y, move_direction, move_start_offset}, offset} ->
      {delta_x, delta_y} = Enum.at(direction_offsets(), move_direction)
      combined_offset = offset + move_start_offset
      x = move_x + delta_x * combined_offset
      y = move_y + delta_y * combined_offset
      {board_index_at(x, y), mask_x()}
    end)
    |> Enum.into(%{})
  end

  defp print_board(board) do
    Enum.each(-14..23, fn x ->
      Enum.each(-14..23, fn y ->
        c =
          case get_in(board, [board_index_at(x, y)]) do
            nil -> " "
            result -> result
          end

        IO.write("#{c} ")
      end)

      IO.puts("")
    end)
  end
end
