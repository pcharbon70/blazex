defmodule BlazeX.LayoutIntentTest do
  use ExUnit.Case, async: true

  alias BlazeX.Core.Identity
  alias BlazeX.UITree.{Layout, Metric, TokenRef}

  test "token and metric vocabularies are exact and portable" do
    assert TokenRef.categories() == [:space, :size, :color, :typography, :radius, :motion]
    assert Metric.forms() == [:auto, :content, :fill, :units, :token]
    assert {:ok, gap} = TokenRef.new(:space, {:scale, 2})
    assert {:ok, {:token, ^gap}} = Metric.token(gap)
    assert {:ok, {:units, 12.5}} = Metric.units(12.5)

    assert {:error, :invalid_metric_token} =
             TokenRef.new(:color, :accent) |> then(fn {:ok, token} -> Metric.token(token) end)

    assert {:error, :invalid_token_name} = TokenRef.new(:space, self())
    assert {:error, :invalid_units} = Metric.units(-1)
  end

  test "stack and grid layout retain logical constraints without geometry" do
    owner = identity!(:layout)
    {:ok, gap} = TokenRef.new(:space, :medium)
    {:ok, size} = TokenRef.new(:size, :dialog)

    assert {:ok, stack} =
             Layout.new(owner, :stack,
               direction: :row,
               align: :center,
               gap: {:token, gap},
               padding: {{:units, 4}, {:units, 8}, {:units, 4}, {:units, 8}},
               width: {:token, size},
               min_height: {:units, 24},
               grow: 1,
               overflow: :clip
             )

    assert Layout.valid?(stack)
    refute Map.has_key?(Map.from_struct(stack), :bounds)

    assert {:ok, grid} =
             Layout.new(owner, :grid,
               width: :fill,
               height: :content,
               overflow: :scroll,
               virtualization: %{axis: :column, estimated_extent: {:units, 32}, overscan: 4}
             )

    assert Layout.valid?(grid)
  end

  test "layout rejects malformed bounds and virtualization" do
    owner = identity!(:invalid_layout)
    assert {:error, :unknown_layout_mode} = Layout.new(owner, :flexbox)

    assert {:error, :invalid_width_range} =
             Layout.new(owner, :stack, min_width: {:units, 20}, max_width: {:units, 10})

    assert {:error, :invalid_virtualization} =
             Layout.new(owner, :stack,
               virtualization: %{axis: :column, estimated_extent: {:units, 0}, overscan: 2}
             )

    assert {:error, :invalid_layout_gap} = Layout.new(owner, :stack, gap: :auto)
    assert {:error, :invalid_layout_owner} = Layout.new(%{host: self()}, :stack)
  end

  defp identity!(root) do
    {:ok, identity} = Identity.new(root)
    identity
  end
end
