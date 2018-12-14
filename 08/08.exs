defmodule DayEight do
  defmodule Node do
    defstruct [:child_count, :children, :metadata_count, :metadata]

    def initial([child_count, metadata_count | remaining_header], parent) do
      new_node = %Node{child_count: child_count, children: [], metadata_count: metadata_count, metadata: []}

      {
        new_node,
        (if parent, do: %Node{parent| children: parent.children ++ [new_node]}, else: nil),
        remaining_header
      }
    end

    def children_left?(node) do
      node.child_count != Enum.count(node.children)
    end

    def metadata_left?(node) do
      node.metadata_count != Enum.count(node.metadata)
    end

    def pull_metadata(header, node) do
      metadata = Enum.take(header, node.metadata_count)
      remaining_header = Enum.drop(header, node.metadata_count)

      {%Node{node | metadata: metadata}, remaining_header}
    end

    def value(node) do
      cond do
        node == nil -> 0
        node.child_count == 0 -> Enum.sum(node.metadata)
        true ->
          node.metadata
          |> Enum.map(fn(child_number) -> value(child_at_number(node, child_number)) end)
          |> Enum.sum
      end
    end

    def replace(root, old_node, new_node) do
      if root == old_node do
        new_node
      else
        %Node{root | children: root.children |> Enum.map(&replace(&1, old_node, new_node))}
      end
    end

    defp child_at_number(node, number) do
      if number < 1 || number > node.child_count do
        nil
      else
        Enum.at(node.children, number - 1)
      end
    end
  end

  defmodule Tree do
    def parse(header) do
      step(header, nil, nil)
    end

    defp step(header, root, current_node) do
      cond do
        Enum.empty?(header) -> root
        root == nil ->
          {new_root, _, remaining_header} = Node.initial(header, nil)

          step(remaining_header, new_root, new_root)
        Node.children_left?(current_node) ->
          {child_node, updated_current_node, remaining_header} = Node.initial(header, current_node)

          step(remaining_header, Node.replace(root, current_node, updated_current_node), child_node)
        Node.metadata_left?(current_node) ->
          {updated_current_node, remaining_header} = Node.pull_metadata(header, current_node)

          step(remaining_header, Node.replace(root, current_node, updated_current_node), updated_current_node)
        true -> step(header, root, parent(root, current_node))
      end
    end

    defp parent(ancestor, node) do
      cond do
        ancestor == node -> nil # this would be bad...
        Enum.member?(ancestor.children, node) -> ancestor
        true -> Enum.map(ancestor.children, &parent(&1, node)) |> Enum.reject(& !&1) |> List.first
      end
    end

    def nodes(node) do
      [node | node.children |> Enum.flat_map(&nodes(&1))]
    end
  end

  def metadata_sum do
    Tree.nodes(root())
    |> Enum.flat_map(fn(node) -> node.metadata end)
    |> Enum.sum
  end

  def root_value do
    Node.value(root())
  end

  def root do
    Tree.parse(header())
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

  defp header do
    input_lines()
    |> List.first
    |> String.split(" ")
    |> Enum.map(&String.to_integer(&1))
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

IO.write "Sum of metadata: " # 43996
IO.puts DayEight.metadata_sum()

IO.write "Value of root: " # 35189
IO.puts DayEight.root_value()
