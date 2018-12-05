defmodule DayFour do
  defmodule RawEvent do
    defstruct [:raw_date, :raw_time, :event, :guard_id]

    def parse(str) do
      [raw_datetime, raw_event] = str |> String.replace("[", "") |> String.split("] ")
      [raw_date, raw_time] = raw_datetime |> String.split(" ")
      {event, guard_id} = case String.split(raw_event, " ") do
        ["wakes", "up"] -> {:wakes_up, nil}
        ["falls", "asleep"] -> {:falls_asleep, nil}
        ["Guard", number_str, "begins", "shift"] -> {:begins_shift, String.to_integer(String.replace(number_str, "#", ""))}
      end

      %RawEvent{raw_date: raw_date, raw_time: raw_time, event: event, guard_id: guard_id}
    end

    def timestamp(event) do
      "#{event.raw_date}T#{event.raw_time}:00Z"
    end

    def minute(event) do
      event.raw_time |> String.split(":") |> List.last |> String.to_integer()
    end
  end

  defmodule Shift do
    def default do
      for _ <- 0..59, do: true
    end

    def awake_after(minutes, minute) do
      minutes
      |> Enum.with_index
      |> Enum.map(fn ({awake, index}) -> if (index >= minute), do: true, else: awake  end)
    end

    def asleep_after(minutes, minute) do
      minutes
      |> Enum.with_index
      |> Enum.map(fn ({awake, index}) -> if (index >= minute), do: false, else: awake  end)
    end

    def print(minutes) do
      minutes
      |> Enum.map(fn (awake) -> if (awake), do: ".", else: "#" end)
      |> Enum.join("")
      |> IO.puts
    end
  end

  defmodule Guard do
    defstruct [:id, :events, :shifts]

    def sleepiest_minute(guard) do
      guard.shifts
      |> Map.values
      |> Enum.reduce(%{},
           fn (minutes, minute_hash) ->
             minutes
             |> Enum.with_index
             |> Enum.reduce(
                    minute_hash,
                    fn ({awake, minute}, hash) ->
                      diff = if (awake), do: 0, else: 1

                      Map.update(hash, minute, diff, &(&1 + diff))
                    end
                )
           end
         )
      |> Enum.sort_by(fn ({_minute, count}) -> count end)
      |> List.last
    end

    def time_asleep(guard) do
      guard.shifts
      |> Map.values
      |> Enum.reduce(0, fn(minutes, total) -> total + Enum.count(minutes, &(!&1)) end)
    end

    def record_event(guard, event) do
      %Guard{guard | events: guard.events ++ [event], shifts: updated_shifts(guard, event)}
    end

    def updated_shifts(guard, event) do
      event_minute = RawEvent.minute(event)
      event_date = event.raw_date

      current_shifts = Map.put_new((guard.shifts || %{}), event_date, Shift.default)

      case event.event do
        :begins_shift -> current_shifts
        :falls_asleep -> Map.update!(current_shifts, event_date, &Shift.asleep_after(&1, event_minute))
        :wakes_up -> Map.update!(current_shifts, event_date, &Shift.awake_after(&1, event_minute))
      end
    end

    def on_duty(guards) do
      guards
      |> Enum.sort_by(fn({_guard_id, guard}) -> RawEvent.timestamp(List.last(guard.events)) end)
      |> List.last
      |> elem(1)
    end

    def print(guard) do
      guard.shifts
      |> Map.keys
      |> Enum.sort
      |> Enum.each(
           fn(date) ->
             IO.write(date <> " #" <> Integer.to_string(guard.id) <> " ")
             Shift.print(guard.shifts[date])
           end
         )
    end
  end

  def strategy_one do
    guard = sleepiest_guard()
    {minute, count} = Guard.sleepiest_minute(guard)
    guard.id * minute
  end

  def strategy_two do
    {guard, minute, count} =
      all_guards()
      |> Enum.map(fn (guard) -> {minute, count} = Guard.sleepiest_minute(guard); {guard, minute, count} end)
      |> Enum.sort_by(fn ({_guard, _minute, count}) -> count end)
      |> List.last

    guard.id * minute
  end

  def sleepiest_guard do
    all_guards()
    |> Enum.sort_by(&Guard.time_asleep(&1))
    |> List.last
  end

  def summarize do
    IO.puts("Date   ID      Minute")
    IO.puts("               000000000011111111112222222222333333333344444444445555555555")
    IO.puts("               012345678901234567890123456789012345678901234567890123456789")
    all_guards() |> Enum.each(&Guard.print(&1))
  end

  def all_guards() do
    raw_events()
    |> Enum.reduce(%{}, &handle_event(&1, &2))
    |> Map.values
  end

  def raw_events() do
    input_lines()
    |> Enum.map(&RawEvent.parse(&1))
    |> Enum.sort_by(&RawEvent.timestamp(&1))
  end

  def handle_event(event, guards) do
    guard =
      case event do
        %{event: :begins_shift, guard_id: guard_id} -> Map.get(guards, guard_id, %Guard{id: guard_id, events: []})
        _ -> Guard.on_duty(guards)
      end

    Map.put(guards, guard.id, Guard.record_event(guard, event))
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

#DayFour.summarize
#IO.puts ""

IO.puts "Strategy 1:"
IO.inspect DayFour.strategy_one
IO.puts "Strategy 2:"
IO.inspect DayFour.strategy_two
