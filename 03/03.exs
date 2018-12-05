defmodule DayThree do
  defmodule Claim do
    defstruct [:id, :x, :y, :width, :height]

    def parse(str) do
      [id, coordinates, dimensions] =
        str
        |> String.replace("#", "")
        |> String.replace(":", "")
        |> String.replace("@ ", "")
        |> String.split(" ")
      [x, y] = coordinates |> String.split(",") |> Enum.map(&String.to_integer(&1))
      [width, height] = dimensions  |> String.split("x") |> Enum.map(&String.to_integer(&1))

      %Claim{id: id, x: x, y: y, width: width, height: height}
    end

    def coordinates(claim) do
      for row <- rows(claim), column <- columns(claim), do: {column, row}
    end

    def columns(claim) do
      Range.new(claim.x, claim.x + claim.width - 1)
    end

    def rows(claim) do
      Range.new(claim.y, claim.y + claim.height - 1)
    end

    def valid?(claim, cloth) do
      coordinates(claim)
      |> Enum.all?(fn(target_coordinates) -> Map.get(cloth, target_coordinates, []) == [claim] end)
    end
  end

  defmodule Cloth do
    def side_range do
      0..1000
    end

    def print(cloth) do
      side_range() |> Enum.each(&print_row(&1, cloth))
      cloth
    end

    def print_row(row, cloth) do
      side_range() |> Enum.each(&print_square(&1, row, cloth))
      IO.puts ""
    end

    def print_square(column, row, cloth) do
      IO.write character_at_coordinates(column, row, cloth)
    end

    def character_at_coordinates(column, row, cloth) do
      coordinates = {column, row}
      if Map.has_key?(cloth, coordinates) do
        claims = Map.get(cloth, coordinates)
        if Enum.count(claims) > 1 do
          "x"
        else
          "*"
        end
      else
        "."
      end
    end
  end

  def valid_claim do
    cached_cloth = claimed_cloth()
    claims()
    |> Enum.find(fn(claim) -> Claim.valid?(claim, cached_cloth) end)
  end

  def overused_count do
    overused_squares() |> Enum.count
  end

  def overused_squares do
    claimed_cloth()
    |> Enum.filter(fn({_coordinate, claims}) -> Enum.count(claims) > 1 end)
  end

  def claimed_cloth do
    claims()
    |> Enum.reduce(%{}, &process_claim(&1, &2))
  end

  def process_claim(claim, cloth) do
    claim
    |> Claim.coordinates
    |> Enum.reduce(cloth, &claim_square(&1, claim, &2))
  end

  def claim_square(coordinates, claim, cloth) do
    Map.update(cloth, coordinates, [claim], fn(claims) -> claims ++ [claim] end)
  end

  def claims do
    input_lines()
    |> Enum.map(&Claim.parse(&1))
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

IO.puts "Overused square inches:"
IO.inspect DayThree.overused_count # 104126

IO.puts "Valid claim:"
IO.puts DayThree.valid_claim.id # 695

#DayThree.Cloth.print(DayThree.claimed_cloth())
