defmodule DayNine do
  defmodule Circle do
    defstruct [:player_count, :current_player, :current_marble, :marbles, :players]

    def init(player_count) do
      %Circle{
        player_count: player_count,
        current_player: 1,
        current_marble: 0,
        marbles: [0],
        players: %{}
      }
    end

    def play_round(marble, circle) do
      print_round(marble, circle)
      cond do
        rem(marble, 23) == 0 -> something_entirely_different(marble, circle)
        true -> place(marble, circle)
      end
    end

    def print_round(marble, circle) do
      if DayNine.debug?() do
        IO.write(String.pad_leading("#{marble - 1}", 3))
        IO.write(String.pad_leading("#{circle.current_player}: ", 4))
        IO.puts(
          circle.marbles
          |> Enum.map(
               fn(m) ->
                 if m == circle.current_marble do
                   String.pad_leading("(#{m})", 5)
                 else
                   String.pad_trailing(String.pad_leading("#{m}", 4), 5)
                 end
               end
             )
          |> Enum.join("")
        )
      end
    end

    defp something_entirely_different(marble, circle) do
      next_player = find_next_player(circle)
      player_marbles = Map.get(circle.players, circle.current_player, [])
      {removed_marble, next_marbles} = remove_marble(circle.marbles, current_index(circle) - 7)

      %Circle{
        circle |
        current_player: next_player,
        current_marble: Enum.at(next_marbles, current_index(circle) - 7),
        marbles: next_marbles,
        players: Map.put(circle.players, circle.current_player, player_marbles ++ [marble, removed_marble])
      }
    end

    defp remove_marble(marbles, index) do
      {Enum.at(marbles, index), Enum.take(marbles, index) ++ Enum.drop(marbles, index + 1)}
    end

    defp find_next_player(circle) do
      rem(circle.current_player, circle.player_count) + 1
    end

    defp place(marble, circle) do
      next_player = find_next_player(circle)
      insertion_point = find_insertion_point(circle)
      new_marbles = Enum.take(circle.marbles, insertion_point) ++ [marble] ++ Enum.drop(circle.marbles, insertion_point)

      %Circle{
        circle |
        current_player: next_player,
        current_marble: marble,
        marbles: new_marbles
      }
    end

    defp find_insertion_point(circle) do
      rem(current_index(circle) + 1, Enum.count(circle.marbles)) + 1
    end

    defp current_index(circle) do
      Enum.find_index(circle.marbles, & (&1 == circle.current_marble))
    end
  end

  def run do
    input_lines()
    |> Enum.each(fn(line) -> IO.puts "#{line}: #{high_score(line)}" end)
  end

  defp high_score(line) do
    [player_count, marble_count] = parse_line(line)

    final_circle =
      (1..marble_count)
      |> Enum.reduce(Circle.init(player_count), &Circle.play_round(&1, &2))
      |> (fn(circle) -> Circle.print_round(marble_count, circle); circle end).()

    final_circle.players
    |> Enum.map(fn({_player, marbles}) -> Enum.sum(marbles) end)
    |> Enum.max
  end

  defp parse_line(line) do
    line
    |> String.slice(0..-8)
    |> String.split(" players; last marble is worth ")
    |> Enum.map(&String.to_integer(&1))
  end

  def sample? do
    true
  end

  def debug? do
    false
  end

  defp input_file do
    if sample?() do
      "sample_input.txt"
    else
      "input.txt"
    end
  end

  defp input_lines do
    File.stream!(input_file())
    |> Enum.map(&clean_line(&1))
    |> Enum.reject(fn (line) -> line == "" end)
  end

  defp clean_line(line) do
    String.replace(line, ~r/\n/, "")
  end
end

DayNine.run()
