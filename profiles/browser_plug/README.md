# Browser + Plug Profile

This executable profile will assemble the browser runtime and DOM renderer with
the Plug adapter. It demonstrates a smaller server footprint and continuously
proves that this smaller browser profile has no mandatory Phoenix, LiveView, or
LocalLiveView dependency. It must not depend on
`blazex_renderer_dom_liveview` directly or transitively.

Its supported server features may be intentionally narrower than the canonical
Phoenix profile, but component and renderer semantics must remain identical.

Status: directory scaffold only; create the Mix project when its implementation
milestone begins. `dependency-contract.json` records the Phase 6 qualified
candidate Plug closure and explicitly limits the result to a static boundary,
not an executable-profile claim.
