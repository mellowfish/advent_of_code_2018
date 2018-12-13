defmodule DaySix do
  def possible_characters do
    (for letter <- ?a..?z, do: << letter :: utf8 >>) ++ (for letter <- ?A..?Z, do: << letter :: utf8 >>)
  end

  def character_from_index(index) do
    possible_characters() |> Enum.at(index)
  end

  defmodule Point do
    defstruct [:x, :y, :coordinates, :character]

    def manhattan_distance({ax, ay}, {bx, by}) do
      abs(ax - bx) + abs(ay - by)
    end

    def min_x(points) do
      points
      |> Enum.map(&(&1.x))
      |> Enum.min
    end

    def max_x(points) do
      points
      |> Enum.map(&(&1.x))
      |> Enum.max
    end

    def min_y(points) do
      points
      |> Enum.map(&(&1.y))
      |> Enum.min
    end

    def max_y(points) do
      points
      |> Enum.map(&(&1.y))
      |> Enum.max
    end

    def build({coordinate_string, index}) do
      [x, y] =
        coordinate_string
        |> String.split(", ")
        |> Enum.map(&String.to_integer(&1))

      %Point{x: x, y: y, coordinates: {x, y}, character: DaySix.character_from_index(index)}
    end

    def coordinates(point) do
      {point.x, point.y}
    end
  end

  defmodule Board do
    defstruct [:rows, :columns, :points, :cells]

    def print(board) do
      board.rows
      |> Enum.each(&print_row(&1, board))

      IO.puts ""

      board
    end

    def blank_from_points(points) do
      min_x = Point.min_x(points)
      max_x = Point.max_x(points)
      min_y = Point.min_y(points)
      max_y = Point.max_y(points)
      rows = (min_y - 1)..(max_y + 1)
      columns = (min_x - 1)..(max_x + 1)
      blank_cells =
        (for row <- rows, column <- columns, do: {column, row})
        |> Enum.reduce(%{}, fn(coordinates, cells) -> Map.put(cells, coordinates, " ") end)

      %Board{rows: rows, columns: columns, points: points, cells: blank_cells}
    end

    def populate(board) do
      populated_cells =
        board.points
        |> Enum.reduce(
             board.cells,
             fn(point, cells) -> Map.put(cells, Point.coordinates(point), point.character) end
           )

      %Board{board | cells: populated_cells}
    end

    def central_region_size(board) do
      central_region(board)
      |> Enum.count
    end

    defp central_region(board) do
      coordinates(board)
      |> Enum.filter(fn(coordinates) -> total_central_distance(coordinates, board) < 10000 end)
    end

    defp total_central_distance(coordinates, board) do
      board.points
      |> Enum.map(&Point.manhattan_distance(coordinates, (&1).coordinates))
      |> Enum.sum
    end

    def point_region_size(point, board) do
      region = point_region(point, board)

      on_edge = region |> Enum.any?(fn (coordinates) -> edge?(coordinates, board) end)
      if on_edge do
        -1
      else
        region |> Enum.count
      end
    end

    defp point_region(point, board) do
      coordinates(board)
      |> Enum.filter(fn(coordinates) -> Map.get(board.cells, coordinates) == point.character end)
    end

    defp coordinates(board) do
      for row <- board.rows, column <- board.columns, do: {column, row}
    end

    defp edge?({x, y}, board) do
      x == Enum.min(board.columns) ||
        x == Enum.max(board.columns) ||
        y == Enum.min(board.rows) ||
        y == Enum.max(board.rows)
    end

    def fill(board) do
      coordinates(board)
      |> Enum.reduce(board, &fill_cell(&1, &2))
    end

    defp fill_cell(coordinates, board) do
      [{point_a, distance_a}, {_point_b, distance_b} | _other_points] =
        board.points
        |> Enum.map(fn(point) -> {point, Point.manhattan_distance(point.coordinates, coordinates)} end)
        |> Enum.sort_by(&elem(&1, 1))

      if distance_a == 0 do
        board
      else
        if distance_a == distance_b do
          %Board{board | cells: Map.put(board.cells, coordinates, ".")}
        else
          %Board{board | cells: Map.put(board.cells, coordinates, point_a.character)}
        end
      end
    end

    defp print_row(row, board) do
      board.columns
      |> Enum.map(&cell({&1, row}, board))
      |> Enum.join("  ")
      |> IO.puts
    end

    defp cell(coordinates, board) do
      board.cells
      |> Map.get(coordinates)
    end
  end

  def largest_region_size do
    board = filled_board()
    board.points
    |> Enum.map(fn(point) -> Board.point_region_size(point, board) end)
    |> Enum.max
  end

  def filled_board do
    parsed_board()
    |> Board.fill
  end

  def central_region_size do
    parsed_board()
    |> Board.central_region_size
  end

  defp parsed_board do
    parse_points()
    |> Board.blank_from_points
    |> Board.populate
  end

  defp parse_points do
    input_lines()
    |> Enum.with_index
    |> Enum.map(&Point.build(&1))
  end

  defp input_lines do
    File.stream!("input.txt")
    |> Enum.map(&clean_line(&1))
    |> Enum.reject(fn (line) -> line == "" end)
  end

  defp clean_line(line) do
    String.replace(line, ~r/\n|\+/, "")
  end
end

# DaySix.Board.print(DaySix.filled_board())

IO.write "Largest region size: " # 4143
IO.puts DaySix.largest_region_size()

IO.puts ""

IO.write "Central region size: " # 35039
IO.puts DaySix.central_region_size()
