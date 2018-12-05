defmodule DayTwo do
  def shared_box_characters do
    shared_characters(closest_match)
  end

  def closest_match do
    boxes = input_lines()
    boxes
    |> Enum.map(fn (box_one) -> {box_one, find_close_match(box_one, boxes)} end)
    |> Enum.reject(fn ({box_one, box_two}) -> box_two == nil end)
    |> List.first
  end

  def find_close_match(box_one, boxes) do
    boxes |> Enum.find(fn (box_two) -> close_match?(box_one, box_two) end)
  end

  def close_match?(box_one, box_two) do
    distance =
      Enum.zip(String.to_charlist(box_one), String.to_charlist(box_two))
      |> Enum.count(fn ({char_one, char_two}) -> char_one != char_two end)
    distance == 1
  end

  def shared_characters({box_one, box_two}) do
    different_characters = Enum.dedup(String.to_charlist(box_one)) -- Enum.dedup(String.to_charlist(box_two))
    String.to_charlist(box_one)
    |> Enum.reject(fn(character) -> Enum.member?(different_characters, character) end)
  end

  def checksum do
    data = categorized_boxes()

    count_twos = Enum.count(Map.get(data, 2, []))
    count_threes = Enum.count(Map.get(data, 3, []))
    count_twos * count_threes
  end

  def categorized_boxes do
    input_lines()
    |> Enum.reduce(%{}, &categorize_box(&1, &2))
  end

  def categorize_box(box_id, data) do
    categories =
      String.to_charlist(box_id)
      |> Enum.group_by(&(&1))
      |> Enum.map(fn({char, duplicates}) -> {Enum.count(duplicates), char} end)
      |> Enum.group_by(fn({count, _letter}) -> count end, fn({_count, letter}) -> letter end)

    push_box_id(push_box_id(data, categories, box_id, 2), categories, box_id, 3)
  end

  def push_box_id(data, categories, box_id, duplicate_count) do
    if Map.has_key?(categories, duplicate_count) do
      Map.put(data, duplicate_count, (Map.get(data, duplicate_count, []) ++ [box_id]))
    else
      data
    end
  end

  def input_lines do
    File.stream!("input.txt")
    |> Enum.map(&clean_line(&1))
    |> Enum.reject(fn (line) -> line == "" end)
  end

  def clean_line(line) do
    String.replace(line, ~r/\n|\+/, "")
  end
end

IO.puts "Checksum:" # 5750
IO.inspect DayTwo.checksum()
IO.puts "Shared letters:" # tzyvunogzariwkpcbdewmjhxi
IO.inspect DayTwo.shared_box_characters()
