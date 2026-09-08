# Experimental local interaction integration

Phase 5 adds a negotiated `blazex.host-bridge/2` companion. The immutable BH-03
`blazex.host-bridge/1` lifecycle protocol and `fixture.event` operation are not
changed or silently upgraded. A runtime adapter must explicitly advertise v2
and implement `root.interaction`, `root.render_ack`, and request cancellation.
The existing Popcorn/Wasm profile does not yet expose this endpoint.

The browser owner supplies an already-ready BH-03 root handle and the exact
semantic owner token. Construct `InteractionBridge` with the negotiated version,
root ID and a trusted adapter exposing `request(envelope)` and `cancel(identity)`.
Construct `InteractionStream({bridge, rootHandle})`, then
`InteractionListeners({rootId, lifecycleGeneration, owner, receiver: stream})`.
Pass it as `interactions` to `AtomicDOMRoots.attach`; bind the resulting DOM
capability with `stream.bindDOM(domRoots, token)`. Apply the initial runtime
transaction and acknowledge that commit in the runtime before accepting input.
See [the executable setup](interaction-scenarios.js) for exact construction.

The runtime owner stores one `BlazeX.Renderer.DOM.InteractionSession` per active
root. `mount` evaluates the existing component and returns an initial transaction;
`acknowledge` promotes it only after the DOM commit. `handle` accepts the closed
v2 requests and returns updated immutable state plus correlated responses.
Only committed bindings resolve to existing semantic callbacks. Keep returned
state root-local, and call `stop` when that root is lost or disposed. No new
component callback, server command or effect execution is introduced.

Each root has at most 64 outstanding interactions, including the active request.
There is no coalescing or retry. A new committed revision rejects already-queued
old-revision input as stale. An unchanged component output needs no transaction:
its semantic state and interaction sequence advance without a DOM commit.
Uncertain transport, timeout or render outcomes terminate the stream; root owners
must dispose it and establish fresh root state rather than replay input.

Listeners normalize synchronously into immutable plain data. Only successfully
admitted scalar observations permit native value/checked/selection changes in
the DOM preflight journal; unrelated attributes or structure remain protected.
The next render reapplies declared scalar properties (or empty/false defaults).
Preserving user edits, composition and focus/selection across rendering belongs
to Phase 6 and is not claimed here. Privacy filtering is a closed field/type and
designation policy, not a general detector of secrets typed into ordinary fields.

## Reproduction and limits

Run `node integration/bh-04/interaction-browser.mjs /tmp/bh04-interactions.json`
from the repository root, then
`node integration/bh-04/interaction-conformance.mjs /tmp/bh04-interactions.json`.
The pinned offline Docker image and existing fixture Jason dependency are
required; see the Phase 5 validation log for exact versions and counts.

This harness executes real Elixir components and reconciliation in ERTS using a
test-only Playwright DevTools/stdio carrier. It does not package the new endpoint
inside AtomVM/Wasm. One activation per browser uses trusted mouse input; other
mappings use browser-dispatched programmatic native events. This is not physical
device, trusted gesture, manual accessibility, performance or support evidence.
No interaction uses Phoenix, Plug, HTTP requests, or arbitrary component JS.
