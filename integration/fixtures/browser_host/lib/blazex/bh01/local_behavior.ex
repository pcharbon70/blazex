defmodule BlazeX.BH01.LocalBehavior do
  @moduledoc false
  @protocol "blazex.bh01.fixture-effect/0.1"
  @dom_protocol "blazex.bh01.dom/0.1"
  @state_key :blazex_bh01_local_behavior_state
  @scenario "BX-BH01-SCENARIO-LOCAL-BROWSER"

  def initialize(generation) when is_integer(generation) and generation > 0 do
    state = initial(generation)
    Process.put(@state_key, state)
    state
  end

  def command(generation, %{"command" => command} = payload) when is_binary(command) do
    state = current(generation)

    case transition(command, payload, state) do
      {:ok, next, operations, result} -> publish(next, operations, result)
      {:error, code, message} -> {:error, error(code, message, state)}
    end
  end

  def command(generation, _payload) do
    state = current(generation)
    {:error, error("fixture-command-invalid", "The fixture command is malformed", state)}
  end

  def event(generation, %{
        "protocol" => "blazex.bh01.fixture-event/0.1",
        "generation" => generation,
        "node_id" => node_id,
        "event" => "action",
        "payload" => _payload
      }) do
    cond do
      node_id == "bx-parent-action" ->
        command(generation, %{"command" => "parent.increment"})

      node_id == "bx-field-reset" ->
        command(generation, %{"command" => "field.reset"})

      String.starts_with?(node_id, "bx-child-") and String.ends_with?(node_id, "-action") ->
        key =
          node_id
          |> String.replace_prefix("bx-child-", "")
          |> String.replace_suffix("-action", "")

        command(generation, %{"command" => "child.increment", "key" => key})

      true ->
        {:error,
         error(
           "fixture-event-target-invalid",
           "The action target is not declared",
           current(generation)
         )}
    end
  end

  def event(generation, %{
        "protocol" => "blazex.bh01.fixture-event/0.1",
        "generation" => generation,
        "node_id" => "bx-field",
        "event" => event,
        "payload" => payload
      })
      when event in ["input", "change", "focus", "blur"] do
    field_event(event, payload, current(generation)) |> publish_event()
  end

  def event(generation, _event),
    do:
      {:error,
       error("fixture-event-invalid", "The fixture event is malformed", current(generation))}

  def snapshot(generation), do: current(generation) |> external_snapshot()

  def async(message) do
    state = Process.get(@state_key) || initial(1)

    message
    |> async_transition(state)
    |> publish_event()
  end

  def async(generation, message) do
    message
    |> async_transition(current(generation))
    |> publish_event()
  end

  defp current(generation) do
    case Process.get(@state_key) do
      %{generation: ^generation} = state -> state
      _ -> initialize(generation)
    end
  end

  defp initial(generation) do
    %{
      generation: generation,
      sequence: 0,
      mounted: false,
      disposed: false,
      parent_count: 0,
      parent_restarts: 0,
      children: [child("alpha", 1), child("beta", 1)],
      field: initial_field(),
      async: initial_async(),
      stale_drops: 0,
      failures: 0
    }
  end

  defp child(key, instance), do: %{key: key, count: 0, instance: instance, restarts: 0}

  defp initial_field do
    %{
      value: "",
      touched: false,
      valid: false,
      error: "Name is required",
      disabled: false,
      read_only: false,
      focused: false,
      composing: false,
      validation_revision: 0
    }
  end

  defp initial_async do
    %{
      timer_ref: nil,
      timer_token: 0,
      timer_ticks: 0,
      timer_limit: 0,
      timer_delay_ms: 0,
      messages: 0,
      pending_messages: 0,
      seen_message_ids: [],
      duplicate_drops: 0,
      last_result: "Idle"
    }
  end

  defp transition("mount", _payload, %{disposed: false} = state) do
    next = %{state | mounted: true}
    {:ok, next, render_all(next), %{"mounted" => true}}
  end

  defp transition("parent.increment", _payload, %{mounted: true, disposed: false} = state) do
    next = %{state | parent_count: state.parent_count + 1}

    {:ok, next, [text("bx-parent-count", "Parent count: #{next.parent_count}")],
     %{"parent_count" => next.parent_count}}
  end

  defp transition("child.increment", %{"key" => key}, %{mounted: true, disposed: false} = state) do
    case update_child(state.children, key, fn item -> %{item | count: item.count + 1} end) do
      {:ok, children, item} ->
        next = %{state | children: children}

        {:ok, next, [text(child_count_id(key), child_text(item))],
         %{"key" => key, "count" => item.count}}

      :error ->
        {:error, "fixture-child-missing", "The child identity does not exist"}
    end
  end

  defp transition("child.insert", %{"key" => key}, %{mounted: true, disposed: false} = state) do
    if valid_key?(key) and not child_exists?(state.children, key) do
      item = child(key, 1)
      next = %{state | children: state.children ++ [item]}
      {:ok, next, child_operations(item), %{"key" => key, "inserted" => true}}
    else
      {:error, "fixture-child-duplicate", "The inserted child identity is invalid or duplicated"}
    end
  end

  defp transition("child.reorder", %{"keys" => keys}, %{mounted: true, disposed: false} = state)
       when is_list(keys) do
    with true <- length(keys) == length(state.children),
         true <- length(Enum.uniq(keys)) == length(keys),
         true <- Enum.sort(keys) == Enum.sort(Enum.map(state.children, & &1.key)) do
      children = Enum.map(keys, fn key -> Enum.find(state.children, &(&1.key == key)) end)
      next = %{state | children: children}

      operations =
        Enum.map(children, fn item -> move(child_group_id(item.key), "bx-child-list") end)

      {:ok, next, operations, %{"keys" => keys}}
    else
      _ ->
        {:error, "fixture-child-order-invalid",
         "The reorder set must match every child exactly once"}
    end
  end

  defp transition("child.remove", %{"key" => key}, %{mounted: true, disposed: false} = state) do
    if child_exists?(state.children, key) do
      next = %{state | children: Enum.reject(state.children, &(&1.key == key))}
      {:ok, next, [remove(child_group_id(key))], %{"key" => key, "removed" => true}}
    else
      {:error, "fixture-child-missing", "The removed child identity does not exist"}
    end
  end

  defp transition(
         "child.replace",
         %{"old_key" => old_key, "new_key" => new_key},
         %{mounted: true, disposed: false} = state
       ) do
    cond do
      not child_exists?(state.children, old_key) ->
        {:error, "fixture-child-missing", "The replaced child identity does not exist"}

      not valid_key?(new_key) or child_exists?(state.children, new_key) ->
        {:error, "fixture-child-duplicate", "The replacement identity is invalid or duplicated"}

      true ->
        replacement = child(new_key, 1)

        children =
          Enum.map(state.children, fn item ->
            if item.key == old_key, do: replacement, else: item
          end)

        next = %{state | children: children}

        operations =
          [remove(child_group_id(old_key)) | child_operations(replacement)] ++
            Enum.map(children, fn item -> move(child_group_id(item.key), "bx-child-list") end)

        {:ok, next, operations, %{"old_key" => old_key, "new_key" => new_key}}
    end
  end

  defp transition("child.crash", %{"key" => key}, %{mounted: true, disposed: false} = state) do
    case update_child(state.children, key, fn item ->
           %{item | count: 0, instance: item.instance + 1, restarts: item.restarts + 1}
         end) do
      {:ok, children, item} ->
        next = %{state | children: children, failures: state.failures + 1}

        {:ok, next, [text(child_count_id(key), child_text(item))],
         %{"key" => key, "restarted_instance" => item.instance}}

      :error ->
        {:error, "fixture-child-missing", "The crashed child identity does not exist"}
    end
  end

  defp transition("parent.crash", _payload, %{mounted: true, disposed: false} = state) do
    next = %{
      state
      | parent_count: 0,
        parent_restarts: state.parent_restarts + 1,
        children: [child("alpha", 1), child("beta", 1)],
        failures: state.failures + 1
    }

    operations =
      [text("bx-parent-count", "Parent count: 0")] ++
        Enum.map(state.children, &remove(child_group_id(&1.key))) ++
        Enum.flat_map(next.children, &child_operations/1)

    {:ok, next, operations, %{"parent_restarts" => next.parent_restarts}}
  end

  defp transition("child.late-output", %{"key" => key, "generation" => generation}, state) do
    if generation == state.generation and child_exists?(state.children, key) and
         not state.disposed do
      transition("child.increment", %{"key" => key}, state)
    else
      next = %{state | stale_drops: state.stale_drops + 1}
      {:ok, next, [], %{"accepted" => false, "reason" => "stale-or-missing"}}
    end
  end

  defp transition("field.set", %{"value" => value}, %{mounted: true, disposed: false} = state)
       when is_binary(value) and byte_size(value) <= 2_048 do
    update_field_value(state, value, false, "programmatic")
  end

  defp transition("field.reset", _payload, %{mounted: true, disposed: false} = state) do
    field = %{initial_field() | validation_revision: state.field.validation_revision + 1}
    next = %{state | field: field}
    {:ok, next, field_operations(field), %{"reset" => true}}
  end

  defp transition(
         "field.disabled",
         %{"value" => value},
         %{mounted: true, disposed: false} = state
       )
       when is_boolean(value) do
    field = %{state.field | disabled: value}
    next = %{state | field: field}

    {:ok, next, [property("bx-field", "disabled", value)], %{"disabled" => value}}
  end

  defp transition(
         "field.read-only",
         %{"value" => value},
         %{mounted: true, disposed: false} = state
       )
       when is_boolean(value) do
    field = %{state.field | read_only: value}
    next = %{state | field: field}

    {:ok, next, [property("bx-field", "read_only", value)], %{"read_only" => value}}
  end

  defp transition(
         "field.validation-result",
         %{"revision" => revision, "value" => value},
         %{mounted: true, disposed: false} = state
       )
       when is_integer(revision) and is_binary(value) and byte_size(value) <= 2_048 do
    if revision == state.field.validation_revision and value == state.field.value do
      field = validate_field(state.field)
      next = %{state | field: field}
      {:ok, next, field_validation_operations(field), %{"accepted" => true}}
    else
      next = %{state | stale_drops: state.stale_drops + 1}
      {:ok, next, [], %{"accepted" => false, "reason" => "stale-validation"}}
    end
  end

  defp transition(
         "timer.start",
         %{"delay_ms" => delay_ms, "ticks" => ticks},
         %{mounted: true, disposed: false} = state
       )
       when is_integer(delay_ms) and delay_ms >= 5 and delay_ms <= 5_000 and
              is_integer(ticks) and ticks >= 1 and ticks <= 5 do
    cancel_timer(state.async.timer_ref)
    token = state.async.timer_token + 1
    timer_ref = schedule_timer(state.generation, token, delay_ms)

    async = %{
      state.async
      | timer_ref: timer_ref,
        timer_token: token,
        timer_ticks: 0,
        timer_limit: ticks,
        timer_delay_ms: delay_ms,
        last_result: "Timer pending"
    }

    next = %{state | async: async}

    {:ok, next, [text("bx-async-status", async.last_result)],
     %{"timer_epoch" => token, "ticks" => ticks, "delay_ms" => delay_ms}}
  end

  defp transition("timer.cancel", _payload, %{mounted: true, disposed: false} = state) do
    cancel_timer(state.async.timer_ref)

    async = %{
      state.async
      | timer_ref: nil,
        timer_token: state.async.timer_token + 1,
        last_result: "Timer cancelled"
    }

    next = %{state | async: async}
    {:ok, next, [text("bx-async-status", async.last_result)], %{"cancelled" => true}}
  end

  defp transition("timer.crash", _payload, %{mounted: true, disposed: false} = state) do
    cancel_timer(state.async.timer_ref)

    async = %{
      state.async
      | timer_ref: nil,
        timer_token: state.async.timer_token + 1,
        last_result: "Timer crashed; restart required"
    }

    next = %{state | async: async, failures: state.failures + 1}
    {:ok, next, [text("bx-async-status", async.last_result)], %{"crashed" => true}}
  end

  defp transition(
         "message.send",
         %{"message_id" => message_id, "value" => value},
         %{mounted: true, disposed: false} = state
       )
       when is_binary(value) and byte_size(value) <= 128 do
    if valid_key?(message_id) do
      send(self(), {:bh01_fixture_message, state.generation, message_id, value})
      async = %{state.async | pending_messages: state.async.pending_messages + 1}
      next = %{state | async: async}
      {:ok, next, [], %{"queued" => true, "message_id" => message_id}}
    else
      {:error, "fixture-message-invalid", "The fixture message identity is invalid"}
    end
  end

  defp transition(
         "message.duplicate",
         %{"message_id" => message_id, "value" => value},
         %{mounted: true, disposed: false} = state
       )
       when is_binary(value) and byte_size(value) <= 128 do
    if valid_key?(message_id) do
      message = {:bh01_fixture_message, state.generation, message_id, value}
      send(self(), message)
      send(self(), message)
      async = %{state.async | pending_messages: state.async.pending_messages + 2}
      next = %{state | async: async}
      {:ok, next, [], %{"queued" => 2, "message_id" => message_id}}
    else
      {:error, "fixture-message-invalid", "The fixture message identity is invalid"}
    end
  end

  defp transition(
         "message.late",
         %{"message_id" => message_id, "value" => value, "generation" => generation},
         %{mounted: true, disposed: false} = state
       )
       when is_binary(value) and byte_size(value) <= 128 and is_integer(generation) do
    if valid_key?(message_id) do
      send(self(), {:bh01_fixture_message, generation, message_id, value})
      async = %{state.async | pending_messages: state.async.pending_messages + 1}
      next = %{state | async: async}
      {:ok, next, [], %{"queued" => true, "message_id" => message_id}}
    else
      {:error, "fixture-message-invalid", "The fixture message identity is invalid"}
    end
  end

  defp transition("dispose", _payload, state) do
    cancel_timer(state.async.timer_ref)

    async = %{
      state.async
      | timer_ref: nil,
        timer_token: state.async.timer_token + 1,
        pending_messages: 0,
        last_result: "Disposed"
    }

    next = %{state | mounted: false, disposed: true, children: [], async: async}
    {:ok, next, [root_dispose()], %{"disposed" => true}}
  end

  defp transition("snapshot", _payload, state), do: {:ok, state, [], external_snapshot(state)}

  defp transition(_command, _payload, _state),
    do:
      {:error, "fixture-command-unknown",
       "The fixture command is not allowlisted or is illegal in the current state"}

  defp field_event(event, payload, %{mounted: true, disposed: false} = state)
       when event in ["input", "change"] do
    with %{"value" => value, "is_composing" => composing} <- payload,
         true <- is_binary(value) and byte_size(value) <= 2_048,
         true <- is_boolean(composing) do
      cond do
        state.field.disabled ->
          {:error, error("fixture-field-disabled", "The disabled field rejects input", state)}

        state.field.read_only ->
          {:error, error("fixture-field-read-only", "The read-only field rejects input", state)}

        true ->
          update_field_value(state, value, event == "input" and composing, event)
      end
    else
      _ -> {:error, error("fixture-field-event-invalid", "The field event is malformed", state)}
    end
  end

  defp field_event(
         "focus",
         %{"related_target" => related},
         %{mounted: true, disposed: false} = state
       )
       when related in ["none", "present"] do
    field = %{state.field | focused: true}
    next = %{state | field: field}
    {:ok, next, [], %{"focused" => true}}
  end

  defp field_event(
         "blur",
         %{"related_target" => related},
         %{mounted: true, disposed: false} = state
       )
       when related in ["none", "present"] do
    field =
      state.field
      |> Map.merge(%{focused: false, touched: true, composing: false})
      |> validate_field()

    next = %{state | field: field}
    {:ok, next, field_validation_operations(field), %{"focused" => false, "touched" => true}}
  end

  defp field_event(_event, _payload, state),
    do: {:error, error("fixture-field-event-invalid", "The field event is malformed", state)}

  defp publish_event({:ok, state, operations, result}),
    do: publish(state, operations, result)

  defp publish_event({:error, error}), do: {:error, error}

  defp update_field_value(state, value, composing, source) do
    revision = state.field.validation_revision + 1
    changed = %{state.field | value: value, composing: composing, validation_revision: revision}
    field = if composing, do: changed, else: validate_field(changed)
    next = %{state | field: field}

    operations =
      [property("bx-field", "value", value)] ++
        if(composing, do: [], else: field_validation_operations(field))

    {:ok, next, operations,
     %{"source" => source, "value" => value, "validation_revision" => revision}}
  end

  defp validate_field(field) do
    {valid, message} =
      cond do
        byte_size(field.value) == 0 -> {false, "Name is required"}
        byte_size(field.value) < 2 -> {false, "Use at least 2 bytes"}
        byte_size(field.value) > 64 -> {false, "Use at most 64 bytes"}
        true -> {true, ""}
      end

    %{field | valid: valid, error: message, composing: false}
  end

  defp async_transition(
         {:bh01_fixture_timer, generation, token},
         %{generation: generation, disposed: false} = state
       ) do
    if state.async.timer_ref != nil and token == state.async.timer_token do
      ticks = state.async.timer_ticks + 1

      timer_ref =
        if ticks < state.async.timer_limit do
          schedule_timer(state.generation, token, state.async.timer_delay_ms)
        else
          nil
        end

      result = "Timer tick #{ticks}/#{state.async.timer_limit}"

      async = %{
        state.async
        | timer_ref: timer_ref,
          timer_ticks: ticks,
          last_result: result
      }

      next = %{state | async: async}
      {:ok, next, [text("bx-async-status", result)], %{"timer_tick" => ticks}}
    else
      drop_async(state, "stale-timer")
    end
  end

  defp async_transition(
         {:bh01_fixture_message, generation, message_id, value},
         %{generation: generation, disposed: false} = state
       ) do
    pending = decrement(state.async.pending_messages)

    if message_id in state.async.seen_message_ids do
      async = %{
        state.async
        | pending_messages: pending,
          duplicate_drops: state.async.duplicate_drops + 1
      }

      drop_async(%{state | async: async}, "duplicate-message")
    else
      result = "Message #{message_id}: #{value}"

      async = %{
        state.async
        | messages: state.async.messages + 1,
          pending_messages: pending,
          seen_message_ids: retain_message_id(state.async.seen_message_ids, message_id),
          last_result: result
      }

      next = %{state | async: async}
      {:ok, next, [text("bx-async-status", result)], %{"message_id" => message_id}}
    end
  end

  defp async_transition({:bh01_fixture_message, _generation, _message_id, _value}, state) do
    async = %{state.async | pending_messages: decrement(state.async.pending_messages)}
    drop_async(%{state | async: async}, "stale-message")
  end

  defp async_transition(_message, state),
    do: {:error, error("fixture-async-message-invalid", "The async message is malformed", state)}

  defp drop_async(state, reason) do
    next = %{state | stale_drops: state.stale_drops + 1}
    {:ok, next, [], %{"accepted" => false, "reason" => reason}}
  end

  defp schedule_timer(generation, token, delay_ms),
    do: Process.send_after(self(), {:bh01_fixture_timer, generation, token}, delay_ms)

  defp cancel_timer(nil), do: :ok

  defp cancel_timer(timer_ref) do
    Process.cancel_timer(timer_ref)
    :ok
  end

  defp decrement(value) when value > 0, do: value - 1
  defp decrement(_value), do: 0

  defp retain_message_id(ids, id) when length(ids) < 16, do: ids ++ [id]
  defp retain_message_id([_oldest | rest], id), do: rest ++ [id]

  defp publish(state, operations, result) do
    next = %{state | sequence: state.sequence + 1}
    Process.put(@state_key, next)

    effect = %{
      "protocol" => @protocol,
      "scenario_id" => @scenario,
      "generation" => next.generation,
      "sequence" => next.sequence,
      "operations" => Enum.map(operations, &Map.put(&1, "generation", next.generation)),
      "snapshot" => external_snapshot(next)
    }

    {:ok, effect, %{"accepted" => true, "effect_sequence" => next.sequence, "result" => result}}
  end

  defp error(code, message, state),
    do: %{
      "code" => code,
      "message" => message,
      "retryable" => false,
      "generation" => state.generation,
      "sequence" => state.sequence
    }

  defp render_all(state) do
    [
      root(),
      upsert(
        "bx-title",
        "bx-fixture-root",
        "heading",
        "Disposable local behavior",
        "bx-test-title"
      ),
      upsert("bx-parent", "bx-fixture-root", "group", nil, "bx-test-parent"),
      upsert(
        "bx-parent-count",
        "bx-parent",
        "status",
        "Parent count: #{state.parent_count}",
        "bx-test-parent-count"
      ),
      upsert(
        "bx-parent-action",
        "bx-parent",
        "action",
        "Increment parent",
        "bx-test-parent-action"
      ),
      listener("bx-parent-action", "action"),
      upsert("bx-child-list", "bx-parent", "list", nil, "bx-test-child-list")
    ] ++
      Enum.flat_map(state.children, &child_operations/1) ++
      form_operations(state.field) ++ async_operations(state.async)
  end

  defp child_operations(item) do
    group = child_group_id(item.key)

    [
      upsert(group, "bx-child-list", "item", nil, "bx-test-child-#{item.key}"),
      upsert(child_count_id(item.key), group, "status", child_text(item), nil),
      upsert("bx-child-#{item.key}-action", group, "action", "Increment #{item.key}", nil),
      listener("bx-child-#{item.key}-action", "action")
    ]
  end

  defp child_text(item), do: "#{item.key}: #{item.count} (instance #{item.instance})"
  defp child_group_id(key), do: "bx-child-#{key}"
  defp child_count_id(key), do: "bx-child-#{key}-count"

  defp form_operations(field) do
    [
      upsert("bx-form", "bx-fixture-root", "group", nil, "bx-test-form"),
      upsert("bx-field-label", "bx-form", "label", "Name", "bx-test-field-label"),
      upsert(
        "bx-field-help",
        "bx-form",
        "help",
        "Enter 2 to 64 bytes",
        "bx-test-field-help"
      ),
      upsert("bx-field-error", "bx-form", "error", field.error, "bx-test-field-error"),
      upsert("bx-field", "bx-form", "field", nil, "bx-test-field"),
      upsert("bx-field-reset", "bx-form", "action", "Reset name", "bx-test-field-reset"),
      relationship("bx-field-label", "label_for", ["bx-field"]),
      relationship("bx-field", "described_by", ["bx-field-help", "bx-field-error"]),
      relationship("bx-field", "error_message", ["bx-field-error"])
    ] ++
      field_operations(field) ++
      [
        listener("bx-field", "input"),
        listener("bx-field", "change"),
        listener("bx-field", "focus"),
        listener("bx-field", "blur"),
        listener("bx-field-reset", "action")
      ]
  end

  defp field_operations(field) do
    [
      property("bx-field", "value", field.value),
      property("bx-field", "disabled", field.disabled),
      property("bx-field", "read_only", field.read_only)
    ] ++ field_validation_operations(field)
  end

  defp field_validation_operations(field) do
    [
      property("bx-field", "invalid", not field.valid),
      text("bx-field-error", field.error)
    ]
  end

  defp async_operations(async) do
    [
      upsert("bx-async", "bx-fixture-root", "group", nil, "bx-test-async"),
      upsert(
        "bx-async-status",
        "bx-async",
        "status",
        async.last_result,
        "bx-test-async-status"
      )
    ]
  end

  defp root,
    do: %{
      "protocol" => @dom_protocol,
      "op" => "root.mount",
      "id" => "bx-fixture-root",
      "test_id" => "bx-test-root"
    }

  defp root_dispose,
    do: %{"protocol" => @dom_protocol, "op" => "root.dispose", "id" => "bx-fixture-root"}

  defp upsert(id, parent, kind, text, test_id) do
    %{
      "protocol" => @dom_protocol,
      "op" => "node.upsert",
      "id" => id,
      "parent_id" => parent,
      "kind" => kind
    }
    |> put_optional("text", text)
    |> put_optional("test_id", test_id)
  end

  defp text(id, value),
    do: %{"protocol" => @dom_protocol, "op" => "node.text", "id" => id, "text" => value}

  defp listener(id, event),
    do: %{"protocol" => @dom_protocol, "op" => "listener.bind", "id" => id, "event" => event}

  defp property(id, name, value),
    do: %{
      "protocol" => @dom_protocol,
      "op" => "node.property",
      "id" => id,
      "name" => name,
      "value" => value
    }

  defp relationship(id, name, target_ids),
    do: %{
      "protocol" => @dom_protocol,
      "op" => "node.relationship",
      "id" => id,
      "name" => name,
      "target_ids" => target_ids
    }

  defp move(id, parent),
    do: %{
      "protocol" => @dom_protocol,
      "op" => "node.move",
      "id" => id,
      "parent_id" => parent,
      "before_id" => nil
    }

  defp remove(id), do: %{"protocol" => @dom_protocol, "op" => "node.remove", "id" => id}
  defp put_optional(map, _key, nil), do: map
  defp put_optional(map, key, value), do: Map.put(map, key, value)

  defp external_snapshot(state) do
    %{
      "protocol" => "blazex.bh01.fixture-snapshot/0.1",
      "scenario_id" => @scenario,
      "generation" => state.generation,
      "sequence" => state.sequence,
      "mounted" => state.mounted,
      "disposed" => state.disposed,
      "parent_count" => state.parent_count,
      "parent_restarts" => state.parent_restarts,
      "children" =>
        Enum.map(state.children, fn item ->
          %{
            "key" => item.key,
            "count" => item.count,
            "instance" => item.instance,
            "restarts" => item.restarts
          }
        end),
      "field" => %{
        "value" => state.field.value,
        "touched" => state.field.touched,
        "valid" => state.field.valid,
        "error" => state.field.error,
        "disabled" => state.field.disabled,
        "read_only" => state.field.read_only,
        "focused" => state.field.focused,
        "composing" => state.field.composing,
        "validation_revision" => state.field.validation_revision
      },
      "async" => %{
        "timer_active" => state.async.timer_ref != nil,
        "timer_epoch" => state.async.timer_token,
        "timer_ticks" => state.async.timer_ticks,
        "timer_limit" => state.async.timer_limit,
        "messages" => state.async.messages,
        "pending_messages" => state.async.pending_messages,
        "duplicate_drops" => state.async.duplicate_drops,
        "last_result" => state.async.last_result
      },
      "resources" => %{
        "processes" => if(state.disposed, do: 0, else: 1),
        "timers" => if(state.async.timer_ref == nil, do: 0, else: 1),
        "pending_messages" => state.async.pending_messages,
        "mailbox_messages" => mailbox_length()
      },
      "stale_drops" => state.stale_drops,
      "failures" => state.failures
    }
  end

  defp update_child(children, key, update) do
    case Enum.find(children, &(&1.key == key)) do
      nil ->
        :error

      _ ->
        updated =
          Enum.map(children, fn item -> if item.key == key, do: update.(item), else: item end)

        {:ok, updated, Enum.find(updated, &(&1.key == key))}
    end
  end

  defp child_exists?(children, key), do: Enum.any?(children, &(&1.key == key))

  defp valid_key?(key) when is_binary(key) and byte_size(key) in 1..24 do
    case :erlang.binary_to_list(key) do
      [first | rest] when first >= ?a and first <= ?z -> Enum.all?(rest, &valid_key_byte?/1)
      _ -> false
    end
  end

  defp valid_key?(_), do: false
  defp valid_key_byte?(byte), do: byte in ?a..?z or byte in ?0..?9 or byte == ?-

  defp mailbox_length do
    case :erlang.process_info(self(), :message_queue_len) do
      {:message_queue_len, count} when is_integer(count) and count >= 0 -> count
      _ -> 0
    end
  end
end
