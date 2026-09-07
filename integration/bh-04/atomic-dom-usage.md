# Atomic DOM application (experimental)

`AtomicDOMRoots` in `js/blazex_runtime/src/atomic-dom.js` composes the unchanged
BH-03 `BrowserRootRegistry` with opaque DOM capabilities. Supply the owner's
existing bridge factory, register and mount a real BH-03 handle, then attach
an empty, non-overlapping Element container:

```javascript
const roots = new AtomicDOMRoots({ scopeId, createBridge, onAck });
const handle = await roots.register("example");
await handle.mount({ targetId: "example-target", tree: {} });
const token = roots.attach(handle, { container, owner: transaction.owner, generation: 1 });
const outcome = await roots.submit(token, transaction);
```

Transactions must come from the Phase 3 reconciler and use v2. Submit the actual
terminal acknowledgement to `ReconciledSession.acknowledge`; an `accepted`
progress acknowledgement is not a commit. Every queued submission resolves
once. Uncorrelatable malformed records and unknown capabilities throw locally.
Never share a container or let another renderer modify its subtree. No selectors
or document-wide ID lookups resolve transaction targets.
Actual DOM IDs have an opaque per-capability UUID prefix; accessibility ID
references are rewritten through that same prefix. Semantic transaction IDs
remain unchanged, and two roots cannot collide merely by reusing a projection.

Each root admits at most 64 active/queued requests. There is no coalescing:
dependent revisions must be retained or rejected, never skipped. Overflow rejects
the incoming request. A generation replacement cancels already-admitted queued
work; callers resubmit against the new accepted state. Any BH-03 generation or
lifecycle transition invalidates the attached capability; remount and attach a
fresh capability. Shutdown and runtime loss drain requests and release owned DOM.

Atomicity means a synchronous settled outcome: previous projection, new
projection, or quarantined last-valid reconstruction/empty inert fallback.
MutationObservers can observe intermediate mutation records. This phase does
not preserve uncontrolled user edits, focus continuity, or form state. It binds
inert listeners, applies existing focus/selection intent, and forces buttons to
`type="button"` to avoid implicit submission. Only text inputs are admitted.
It delivers no browser events and executes no effects, LiveView patches, or
product-control logic. A quarantined capability cannot retry.

Reproduce fixtures in the pinned Elixir environment with
`mix run ../bh-04/support/atomic_dom_runner.exs` from `integration/conformance`.
Run the same 50 real-reconciler scenarios and all 1,204 before/after operation
failure boundaries in fake DOM with `node js/blazex_runtime/test/atomic-dom-integration.test.js`.
Run active browsers with `node integration/bh-04/atomic-dom-browser.mjs /tmp/bh04-browsers.json`.
The browser runner uses a controlled acknowledgement bridge through real BH-03
handles; it does not claim fresh AtomVM/Wasm runtime execution. Override
`BH04_FIREFOX` with an installed Playwright-compatible Firefox executable.

Support remains unsupported. Unavailable platform/device/manual-AT qualification
is deferred to the respective qualification owners and reactivates by BH-22.
