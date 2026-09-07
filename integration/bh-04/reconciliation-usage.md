# Experimental pure incremental renderer

Use `BlazeX.Renderer.DOM.ReconciledSession.mount(output)` for the new path.
The returned facade has `accepted: nil` and a provisional `pending` neutral
session. `ReconciledSession.transaction(facade)` returns an internal v2 record.
It is data, not a browser operation. This phase has no DOM applicator.

Feed an independently obtained, exactly correlated protocol acknowledgement to
`ReconciledSession.acknowledge(facade, ack)`. Only `committed` (or `disposed`
for disposal) promotes the candidate. Progress acknowledgements are monotonic;
repeated or regressing progress is rejected. Always thread the returned immutable
facade. `accepted` is the only committed neutral session; callers must never
present `pending` as committed state.

`update/2`, `replace/2`, and `dispose/1` produce the next proposal. Generation
replacement requires the same root/path at exactly the next generation. A
kind/tag change within a generation rematerializes that subtree explicitly.
There is one pending proposal; supersession and implicit fallback are rejected.
After rejection or rollback, invoke the same operation on the returned facade
to retry. For a rejected initial mount, use `mount(facade, output)`. Attempt IDs
change across retries, including mount retries. An old acknowledgement cannot
commit the retried proposal. Acknowledged disposal releases projection data and
is terminal; repeated facade disposal is idempotent.

The backend implements the unchanged neutral renderer callbacks as
`BlazeX.Renderer.DOM.Incremental`. Direct neutral `Session` results are
provisional: use the facade to gate both projection and neutral metadata. The
original `BlazeX.Renderer.DOM` remains the full-root compatibility backend.
No public API stability, browser behavior, or BH-05 authority is implied.

V2 extends the exact Lowerer attribute vocabulary and replaces the v1 partial
focus/selection/listener operations with complete `intent` cells. Cells are
canonical-codec bytes in standard padded base64; null is absence. Portable
integer key values are canonical decimal strings inside these cells. Elixir
`ProtocolV2.IntentData.unpack/1` restores integer values; JavaScript
`decodeIntent()` retains their strings to avoid precision loss. Neither decoder
creates atoms, executes a handler, or restores browser focus. Historical v1
records and shared fixtures stay unchanged and v1 consumers reject v2.

Properties currently have normalized internal slots and diff/replay coverage.
The unchanged semantic kernel does not expose a new property API in this phase.
Listeners are root-owned intent data; executable listener handles and effect
resources do not exist here. Their live allocation/release remains later work.
