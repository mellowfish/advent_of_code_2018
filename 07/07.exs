defmodule DaySeven do
  def sample? do
    false
  end

  def alone? do
    false
  end

  defmodule Task do
    defstruct [:name, :dependencies]

    def parse_dependency(definition) do
      definition
      |> String.slice(5, 32) # "X must be finished before step Y"
      |> String.split(" must be finished before step ")
      |> Enum.reverse
    end

    def pop_next_task(tasks_remaining) do
      tasks_remaining
      |> Map.pop(next_step(tasks_remaining))
    end

    def next_step(tasks_remaining) do
      tasks_remaining
      |> Enum.reject(fn({_name, task}) -> !Enum.empty?(task.dependencies) end)
      |> Enum.map(fn({name, _task}) -> name end)
      |> Enum.sort()
      |> List.first
    end

    def done?(task, age) do
      age >= cost(task)
    end

    defp base_cost do
      if DaySeven.sample?(), do: 0, else: 60
    end

    defp cost(task) do
      <<name_value::utf8>> = task.name
      base_cost() + (name_value - ?A)
    end

    def complete_task(target_task, tasks) do
      tasks
      |> Map.pop(target_task.name)
      |> elem(1)
      |> Enum.reduce(
           %{},
           fn({name, task}, possible_tasks) ->
             Map.put(
               possible_tasks,
               name,
               %Task{task | dependencies: task.dependencies |> List.delete(target_task.name)}
             )
           end
         )
    end

    def steps(tasks) do
      tasks
      |> Enum.map(fn(task) -> task.name end)
      |> Enum.join("")
    end
  end

  def task_order do
    parse_tasks()
    |> start_ticking
    |> Task.steps
  end

  defp worker_count do
    cond do
      alone?() -> 1
      sample?() -> 2
      true -> 5
    end
  end

  defp initial_workers do
    for _ <- 1..(worker_count()), do: {nil, 0}
  end

  defp start_ticking(tasks) do
    tick_world({tasks, 0, initial_workers(), []})
  end

  defp tick_world({remaining_tasks, second, tasks_in_flight, completed_tasks}) do
    if second > 2000 || all_done?(remaining_tasks, tasks_in_flight) do
      completed_tasks
    else
      {new_remaining_tasks, updated_tasks_in_flight, newly_completed_tasks} =
        tasks_in_flight
        |> Enum.reduce({remaining_tasks, [], []}, &tick_worker(&1, &2))

      print_tick(second, updated_tasks_in_flight, completed_tasks ++ newly_completed_tasks)
      tick_world({new_remaining_tasks, second + 1, updated_tasks_in_flight, completed_tasks ++ newly_completed_tasks})
    end
  end

  def all_done?(remaining_tasks, tasks_in_flight) do
    Enum.empty?(remaining_tasks) && tasks_in_flight |> Enum.all?(fn({task, _age}) -> task == nil end)
  end

  defp print_tick(second, tasks_in_flight, completed_tasks) do
    IO.write String.pad_leading(Integer.to_string(second), 4)
    tasks_in_flight
    |> Enum.each(fn({task, age}) -> IO.write(if task == nil, do: " . ", else: " " <> task.name <> " ") end)

    IO.write String.pad_trailing(completed_tasks |> Task.steps, 8)

    IO.puts ""
  end

  defp tick_worker({task, age}, {remaining_tasks, updated_tasks_in_flight, recently_completed_tasks}) do
    cond do
      task == nil && Enum.empty?(remaining_tasks) ->
        {remaining_tasks, updated_tasks_in_flight ++ [{nil, 0}], recently_completed_tasks}
      task == nil && !Enum.empty?(remaining_tasks) ->
        {next_task, new_remaining_tasks} = Task.pop_next_task(remaining_tasks)

        {new_remaining_tasks, updated_tasks_in_flight ++ [{next_task, 0}], recently_completed_tasks}
      Task.done?(task, age) ->
        updated_remaining_tasks = Task.complete_task(task, remaining_tasks)
        {next_task, new_remaining_tasks} = Task.pop_next_task(updated_remaining_tasks)

        {
          new_remaining_tasks,
          updated_tasks_in_flight ++ [{next_task, 0}],
          recently_completed_tasks ++ [task]
        }
      true ->
        {remaining_tasks, updated_tasks_in_flight ++ [{task, age + 1}], recently_completed_tasks}
    end
  end

  defp parse_tasks do
    input_lines()
    |> Enum.reduce(%{}, &process_dependency(&1, &2))
  end

  defp process_dependency(definition, tasks) do
    [name, dependency] = Task.parse_dependency(definition)

    tasks_with_dependency =
      if Map.has_key?(tasks, dependency) do
        tasks
      else
        Map.put(tasks, dependency, %Task{name: dependency, dependencies: []})
      end

    Map.update(
      tasks_with_dependency,
      name,
      %Task{name: name, dependencies: [dependency]},
      fn(task) -> %Task{task | dependencies: task.dependencies ++ [dependency]} end
    )
  end

  defp input_file do
    if sample?(), do: "sample_input.txt", else: "input.txt"
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

# All Alone: ADEFKLBVJQWUXCNGORTMYSIHPZ after 1911 seconds
# 5 Workers: ADEFLKVXBJQWCUNOGRTMYSIHPZ after 1120 seconds
IO.puts("Task work summary:")
IO.puts DaySeven.task_order

