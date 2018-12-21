defmodule DayTen do
  defmodule Beacon do
    defstruct [:x, :y, :dx, :dy]

    def step(beacon) do
      %Beacon{beacon | x: beacon.x + beacon.dx, y: beacon.y + beacon.dy}
    end

    def parse(line) do
      line
      |> String.slice(10..-2)
      |> String.split("> velocity=<")
      |> build
    end

    defp build([position_string, velocity_string]) do
      [x, y] = parse_coordinate(position_string)
      [dx, dy] = parse_coordinate(velocity_string)
      %Beacon{x: x, y: y, dx: dx, dy: dy}
    end

    defp parse_coordinate(string) do
      string
      |> String.split(",")
      |> Enum.map(&String.trim(&1))
      |> Enum.map(&String.to_integer(&1))
    end

    def columns(beacons) do
      beacons |> Enum.map(fn(beacon) -> beacon.x end) |> Enum.min_max |> range_from_minmax
    end

    def rows(beacons) do
      beacons |> Enum.map(fn(beacon) -> beacon.y end) |> Enum.min_max |> range_from_minmax
    end

    defp range_from_minmax({min, max}) do
      Range.new(min - 1, max + 1)
    end

    def neighbor_coordinates(beacon) do
      [
        {beacon.x + 1, beacon.y},
        {beacon.x - 1, beacon.y},
        {beacon.x, beacon.y + 1},
        {beacon.x, beacon.y - 1},
      ]
    end
  end

  defmodule Constellation do
    defstruct [:beacons, :seconds]

    def aligned?(constellation) do
      beacons_with_neighbors(constellation) > (Enum.count(constellation.beacons) * 0.5)
    end

    defp beacons_with_neighbors(constellation) do
      constellation.beacons
      |> Enum.count(fn(beacon) -> neighbors?(beacon, constellation) end)
    end

    defp neighbors?(beacon, constellation) do
      count_neighbors =
        Beacon.neighbor_coordinates(beacon)
        |> Enum.count(fn(coordinates) -> beacon_at?(coordinates, constellation) end)

      count_neighbors > 1
    end

    def step(constellation) do
      %Constellation{beacons: constellation.beacons |> Enum.map(&Beacon.step(&1)), seconds: constellation.seconds + 1}
    end

    def print(constellation) do
      IO.puts "T + #{constellation.seconds}:"
      IO.puts "Beacons with neighbors: #{beacons_with_neighbors(constellation)}"
      IO.puts "Total beacons: #{Enum.count(constellation.beacons)}"
      for row <- rows(constellation), do: print_row(row, constellation)
    end

    defp rows(constellation) do
      constellation.beacons |> Beacon.rows
    end

    defp print_row(row, constellation) do
      (for column <- columns(constellation), do: character({column, row}, constellation))
      |> Enum.join(" ")
      |> IO.puts
    end

    defp columns(constellation) do
      constellation.beacons |> Beacon.columns
    end

    defp character(coordinates, constellation) do
      if beacon_at?(coordinates, constellation), do: "#", else: "."
    end

    defp beacon_at?({column, row}, constellation) do
      constellation.beacons
      |> Enum.any?(fn(beacon) -> beacon.x == column && beacon.y == row end)
    end
  end

  def start do
    simulate(starting_constellation())
  end

  defp simulate(constellation) do
    if debug?() do
      Constellation.print(constellation)
      case String.trim(IO.gets("Hit enter to continue:")) do
        "" -> simulate(Constellation.step(constellation))
        "q" -> nil
        "quit" -> nil
        "exit" -> nil
      end
    else
      if Constellation.aligned?(constellation) do
        Constellation.print(constellation)
      else
        simulate(Constellation.step(constellation))
      end
    end
  end

  defp starting_constellation do
    %Constellation{beacons: input_lines() |> Enum.map(&Beacon.parse(&1)), seconds: 0}
  end

  defp debug? do
    false
  end

  defp sample? do
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

DayTen.start()
