defmodule BlazeX.ScopedContextTest do
  use ExUnit.Case, async: true
  alias BlazeX.Component.{Input, ScopedContext}
  def owner, do: %{root: "r", generation: 1, path: []}
  def child, do: %{owner() | path: [{"child", "site", :child, "key"}]}

  def manifest(mode \\ :tracked),
    do: %{
      definitions: %{
        "locale" => %{
          version: 1,
          schema: :string,
          boundary: :host,
          mode: mode,
          default: {:present, "default"},
          doc: "Public locale",
          visibility: :public,
          advisory: false
        }
      },
      owners: %{
        "root" => %{provide: ["locale"], consume: ["locale"]},
        "child" => %{provide: ["locale"], consume: ["locale"]}
      }
    }

  def components,
    do: [
      %{identity: owner(), public_id: "root", context_keys: ["locale"]},
      %{identity: child(), public_id: "child", context_keys: ["locale"]}
    ]

  def p(owner, value), do: %{owner: owner, name: "locale", value: value}

  def prepare(values, old \\ nil, change \\ false, consumer \\ nil, mode \\ :tracked),
    do:
      ScopedContext.prepare(manifest(mode), values, components(), owner(), old, change, consumer)

  test "defaults nearest providers and canonical tracked invalidation retain accepted consumer values until dispatched" do
    {:ok, initial} = prepare([])
    assert ScopedContext.values(initial, child()) == %{"locale" => "default"}
    {:ok, staged} = prepare([p(owner(), "root")], initial, true)
    assert staged.pending == [owner(), child()]
    assert ScopedContext.values(staged, child())["locale"] == "default"
    {:ok, first} = prepare([p(owner(), "root")], staged, false, owner())
    assert first.pending == [child()]
    {:ok, done} = prepare([p(owner(), "root")], first, false, child())
    assert done.pending == [] and ScopedContext.values(done, child())["locale"] == "root"
    {:ok, nearest} = prepare([p(owner(), "root"), p(child(), "child")])
    assert ScopedContext.values(nearest, child())["locale"] == "child"
    assert Input.portable?(ScopedContext.snapshot(nearest))
  end

  test "fixed providers and bindings reject mutation and provider removal removes subscriptions" do
    {:ok, fixed} = prepare([p(owner(), "fixed")], nil, false, nil, :fixed)
    assert {:error, _} = prepare([p(owner(), "changed")], fixed, true, nil, :fixed)
    assert {:error, _} = prepare([], fixed, true, nil, :fixed)
    {:ok, tracked} = prepare([p(child(), "child")])

    {:ok, removed} =
      ScopedContext.prepare(manifest(), [], [hd(components())], owner(), tracked, true)

    assert length(removed.bindings) == 1 and hd(removed.removed).status == :removed
    assert removed.pending == []
  end

  test "duplicates foreign owners stale generations unknown schemas and authority payloads reject atomically" do
    assert {:error, _} = prepare([p(owner(), "a"), p(owner(), "a")])

    for bad <- [%{owner() | root: "other"}, %{owner() | generation: 2}] do
      assert {:error, _} = prepare([p(bad, "a")])
    end

    assert {:error, _} = prepare([p(owner(), %{secret: "no"})])
    assert {:error, _} = prepare([p(owner(), self())])

    assert {:error, _} =
             ScopedContext.validate(put_in(manifest(), [:definitions, "locale", :version], 2))

    assert {:error, _} =
             ScopedContext.validate(
               put_in(manifest(), [:definitions, "locale", :schema], {:callable, 1})
             )

    auth = %{
      manifest()
      | definitions: %{"auth-state" => manifest().definitions["locale"]},
        owners: %{}
    }

    assert {:error, _} = ScopedContext.validate(auth)

    assert :ok =
             ScopedContext.validate(put_in(auth, [:definitions, "auth-state", :advisory], true))
  end

  test "provider and subscription budgets reject excess and replay is deterministic" do
    assert {:error, _} = prepare(Enum.map(1..33, &p(%{owner() | root: "r#{&1}"}, "v")))
    {:ok, a} = prepare([p(owner(), "value")])
    {:ok, b} = prepare([p(owner(), "value")])
    assert a == b

    assert {:error, _} =
             ScopedContext.prepare(manifest(), [], components(), owner(), %{a | root: "foreign"})

    assert {:ok, same} = prepare([p(owner(), "value")], a, true)
    assert same.pending == [] and hd(same.providers).revision == 1
  end

  test "valid same-root owners exercise the exact provider and subscription limits" do
    nodes =
      Enum.map(1..128, fn n ->
        %{
          identity: %{owner() | path: [{"child", "site", :child, "k#{n}"}]},
          public_id: "child",
          context_keys: ["locale"]
        }
      end)

    values = Enum.map(Enum.take(nodes, 32), &p(&1.identity, "v"))
    assert {:ok, at_limit} = ScopedContext.prepare(manifest(), values, nodes, owner())
    assert length(at_limit.providers) == 32 and length(at_limit.bindings) == 128

    assert {:error, _} =
             ScopedContext.prepare(
               manifest(),
               values ++ [p(Enum.at(nodes, 32).identity, "v")],
               nodes,
               owner()
             )

    two = %{
      manifest()
      | definitions: Map.put(manifest().definitions, "second", manifest().definitions["locale"]),
        owners: %{"child" => %{provide: ["locale"], consume: ["locale", "second"]}}
    }

    nodes = Enum.map(nodes, &%{&1 | context_keys: ["locale", "second"]})
    assert {:ok, exact} = ScopedContext.prepare(two, [], Enum.take(nodes, 64), owner())
    assert length(exact.bindings) == 128
    assert {:error, _} = ScopedContext.prepare(two, [], Enum.take(nodes, 65), owner())
  end

  test "missing grants and unavailable default reject before consumer invocation" do
    assert {:error, _} =
             ScopedContext.prepare(%{manifest() | owners: %{}}, [], components(), owner())

    assert {:error, _} =
             ScopedContext.prepare(
               put_in(manifest(), [:definitions, "locale", :default], :absent),
               [],
               components(),
               owner()
             )

    {:ok, previous} = prepare([p(owner(), "provided")])
    {:ok, removed} = prepare([], previous, true)
    assert removed.pending == [owner(), child()]
    {:ok, updated} = prepare([], removed, false, child())
    assert ScopedContext.values(updated, child())["locale"] == "default"
  end
end
