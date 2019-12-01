defmodule MorpionElixir.Worker do
  use GenServer
  use Bitwise
  alias MorpionElixer.Move
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
    # IO.puts("processing #{item}")

    initial_board = generate_initial_board()
    moves = random_completion(initial_board, initial_moves())
    IO.inspect(length(moves), label: "random completion score")
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

  defp mask_direction(direction) do
    case direction do
      0 -> 2
      1 -> 4
      2 -> 8
      3 -> 16
    end
  end

  defp generate_initial_board do
    initial_moves()
    |> Enum.flat_map(fn move ->
      Enum.map(0..4, fn offset ->
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

  defp board_value_at(board, x, y) do
    case get_in(board, [board_index_at(x, y)]) do
      nil -> 0
      result -> result
    end
  end

  defp is_empty_at(board, x, y) do
    board_value_at(board, x, y) == 0
  end

  defp update_board(board, {move_x, move_y, move_direction, move_start_offset}) do
    {delta_x, delta_y} = Enum.at(direction_offsets(), move_direction)

    board_update =
      Enum.map(0..4, fn offset ->
        combined_offset = offset + move_start_offset
        x = move_x + delta_x * combined_offset
        y = move_y + delta_y * combined_offset

        {board_index_at(x, y), board_value_at(board, x, y) ||| mask_direction(move_direction)}
      end)
      |> Enum.into(%{})

    Map.merge(board, board_update)
  end

  defp eval_line(board, start_x, start_y, direction) do
    # dimitri
    {delta_x, delta_y} = Enum.at(direction_offsets(), direction)

    num_inner_points_taken_in_direction =
      0..4
      |> Enum.map(fn offset ->
        x = start_x + delta_x * offset
        y = start_y + delta_y * offset

        offset > 0 && offset < 4 && is_direction_taken(board, x, y, direction)
      end)
      |> Enum.filter(& &1)
      |> length

    empty_points =
      0..4
      |> Enum.map(fn offset ->
        x = start_x + delta_x * offset
        y = start_y + delta_y * offset

        case is_empty_at(board, x, y) do
          false -> nil
          true -> {x, y, offset}
        end
      end)
      |> Enum.filter(& &1)

    # IO.puts(
    #   "considering #{start_x} #{start_y} #{direction}  #{num_inner_points_taken_in_direction}, #{
    #     length(empty_points)
    #   }"
    # )

    cond do
      length(empty_points) == 1 && num_inner_points_taken_in_direction == 0 ->
        [{point_x, point_y, empty_point_offset}] = empty_points
        [Move.new(point_x, point_y, direction, -empty_point_offset)]

      true ->
        []
    end
  end

  defp find_created_moves(board, move_x, move_y) do
    Enum.flat_map(0..3, fn direction ->
      Enum.map(-4..0, fn offset ->
        {delta_x, delta_y} = Enum.at(direction_offsets(), direction)
        x = move_x + delta_x * offset
        y = move_y + delta_y * offset

        # Enum.map(0..4, fn eval_line_offset ->
        #   x = start_x + delta_x * offset
        #   y = start_y + delta_y * offset
        # end)
        eval_line(board, x, y, direction)
      end)
    end)
    |> Enum.filter(fn a -> length(a) > 0 end)
    |> List.flatten()
  end

  defp make_move(
         board,
         possible_moves,
         taken_moves,
         {move_x, move_y, _move_direction, _move_start_offset} = move
       ) do
    new_board = update_board(board, move)

    # print_board(new_board)

    # created_possible_moves = find_created_moves(new_board, move_x, move_y)
    # a =
    #   possible_moves
    #   |> Enum.filter(fn move -> is_move_valid(new_board, move) end)

    # IO.inspect(created_possible_moves, label: "created")

    new_possible_moves =
      possible_moves
      |> Enum.filter(fn move -> is_move_valid(new_board, move) end)
      |> Enum.concat(find_created_moves(new_board, move_x, move_y))
      |> Enum.into(MapSet.new())
      |> Enum.into([])

    # union!(possible_moves, find_created_moves(board, move.x, move.y))

    {new_board, new_possible_moves, taken_moves ++ [move]}
  end

  defp is_direction_taken(board, x, y, direction) do
    c =
      case get_in(board, [board_index_at(x, y)]) do
        nil -> 0
        result -> result
      end

    # IO.puts("c:#{c}  direction:#{direction}   res:#{c &&& direction}")

    (c &&& mask_direction(direction)) != 0
  end

  defp is_move_valid(board, {move_x, move_y, move_direction, move_start_offset}) do
    {delta_x, delta_y} = Enum.at(direction_offsets(), move_direction)

    available_locations =
      Enum.map(0..4, fn offset ->
        combined_offset = offset + move_start_offset
        x = move_x + delta_x * combined_offset
        y = move_y + delta_y * combined_offset

        # IO.puts(
        #   "checking #{x}, #{y}   #{is_empty_at(board, x, y)}   #{
        #     is_direction_taken(board, x, y, move_direction)
        #   }"
        # )

        cond do
          is_empty_at(board, x, y) -> true
          offset > 0 && offset < 4 && is_direction_taken(board, x, y, move_direction) -> true
          true -> false
        end
      end)
      |> Enum.filter(& &1)
      |> length

    available_locations == 1
  end

  defp random_completion(board, possible_moves) do
    random_completion(board, possible_moves, [])
  end

  defp random_completion(_, [], taken_moves), do: taken_moves

  defp random_completion(board, possible_moves, taken_moves) do
    move = Enum.random(possible_moves)

    # IO.inspect(possible_moves, label: "starting possible moves")
    # IO.inspect(move, label: "making move")

    {new_board, new_possible_moves, new_taken_moves} =
      make_move(board, possible_moves, taken_moves, move)

    # IO.inspect(new)
    # print_board(new_board)
    # IO.inspect(new_possible_moves, label: "new possible moves")

    # IO.puts("")

    # System.halt()

    random_completion(new_board, new_possible_moves, new_taken_moves)
  end

  defp print_board(board) do
    Enum.each(-14..23, fn y ->
      Enum.each(-14..23, fn x ->
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
