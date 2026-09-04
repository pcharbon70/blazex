defmodule BlazeX.Renderer.DOM.LiveView.Compatibility do
  @moduledoc false

  @adapter_id "blazex-renderer-dom-liveview/bh01-0.1"
  @versions %{"phoenix_live_view" => "1.2.11", "local_live_view" => "0.1.0"}
  @surfaces %{
    "diff" => [
      "new_components/0-1",
      "new_fingerprints/0",
      "render/4",
      "render_private/2",
      "write_component/4",
      "update_component/3",
      "mark_for_deletion_component/2",
      "delete_component/2"
    ],
    "renderer" => ["to_rendered/2", "__before_compile__/1"],
    "utils" => [
      "clear_changed/1",
      "clear_temp/1",
      "changed?/1-2",
      "post_mount_prune/1",
      "normalize_layout/1",
      "clear_flash/1-2",
      "put_reply/2",
      "maybe_call_live_view_mount!/4-5"
    ],
    "lifecycle" => ["build/1", "stage_info/4"],
    "session_fields" =>
      ~w(id view root_view parent_pid root_pid session redirected? router flash live_session_name assign_new),
    "socket_fields" =>
      ~w(id endpoint view parent_pid root_pid router assigns private redirected host_uri transport_pid sticky?),
    "bridge_actions" =>
      ~w(transport_frame reconnected push push_error update_assigns destroy create handle_params server_message)
  }

  def adapter_id, do: @adapter_id
  def expected_descriptor, do: %{"versions" => @versions, "surfaces" => @surfaces}

  def probe(%{"versions" => versions, "surfaces" => surfaces} = descriptor)
      when is_map(versions) and is_map(surfaces) do
    cond do
      Enum.sort(Map.keys(descriptor)) != ["surfaces", "versions"] ->
        incompatible("descriptor-fields-mismatch")

      versions != @versions ->
        incompatible("version-mismatch")

      Enum.sort(Map.keys(surfaces)) != Enum.sort(Map.keys(@surfaces)) ->
        incompatible("surface-set-mismatch")

      Enum.any?(@surfaces, fn {name, expected} ->
        not is_list(surfaces[name]) or Enum.sort(surfaces[name]) != Enum.sort(expected)
      end) ->
        incompatible("surface-shape-mismatch")

      true ->
        {:ok,
         %{
           "protocol" => "blazex.bh01.liveview-compatibility/0.1",
           "status" => "compatible",
           "adapter" => @adapter_id,
           "versions" => versions,
           "surface_count" => map_size(surfaces)
         }}
    end
  end

  def probe(_descriptor), do: incompatible("descriptor-invalid")

  defp incompatible(reason) do
    {:error,
     %{
       "protocol" => "blazex.bh01.liveview-compatibility/0.1",
       "status" => "incompatible",
       "adapter" => @adapter_id,
       "reason" => reason,
       "action" => "disable-adapter",
       "fallback" => "standalone-dom"
     }}
  end
end
