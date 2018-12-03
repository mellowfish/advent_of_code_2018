defmodule DayOne do
  def final_frequency do
    List.first(frequencies())
  end

  def frequencies do
    input_lines()
    |> Enum.reduce([0], &process_adjustment(&1, &2))
  end

  def process_adjustment(adjustment, history) do
    frequency = adjustment + List.first(history)
    [frequency | history]
  end

  def duplicate_frequency_brute_force do
    input_lines_forever
    |> Enumerable.reduce({:cont, [0]}, &process_adjustment_brute_force(&1, &2))
    |> elem(1)
  end

  def process_adjustment_brute_force(adjustment, history) do
    frequency = adjustment + List.first(history)

#    if rem(Enum.count(history), 999) == 0 do
#      IO.puts "Iteration #{div(Enum.count(history), 999)}"
#    end

    if Enum.member?(history, frequency) do
      { :suspend, frequency }
    else
      { :cont, [frequency | history] }
    end
  end

  def duplicate_frequency do
    offset = final_frequency()
    cached_frequencies = frequencies() |> Enum.reject(fn (x) -> x == 0 end) |> Enum.reverse()
    number_groups =
      cached_frequencies
      |> Enum.group_by(fn (frequency) -> rem(abs(frequency), offset) end)
      |> Enum.reject(fn ({modulo, numbers}) -> Enum.count(numbers) < 2 end)
      |> Enum.map(fn ({modulo, numbers}) -> {modulo, Enum.reverse(Enum.sort(numbers))} end)

    min_distance =
      number_groups
      |> Enum.map(fn ({modulo, numbers}) -> [(List.first(numbers) - List.last(numbers)) | numbers] end)
      |> Enum.sort_by(fn ([diff | numbers]) -> diff end)
  end

  def frequency_duplicated?(frequency, history) do
    history
    |> Enum.filter(fn (x) -> x == frequency end)
    |> Enum.any?
  end

  def input_lines do
    File.stream!("input.txt")
    |> Enum.map(&clean_line(&1))
    |> Enum.reject(fn (line) -> line == "" end)
    |> Enum.map(&String.to_integer(&1))
  end

  def input_lines_forever do
    input_lines() |> Stream.cycle
  end

  def clean_line(line) do
    String.replace(line, ~r/\n|\+/, "")
  end
end

IO.puts "Final Frequency"
IO.inspect DayOne.final_frequency() # 574
IO.puts "First Duplicate Frequency (Brute Force)"
IO.inspect DayOne.duplicate_frequency_brute_force() # 452 (139 iterations)
