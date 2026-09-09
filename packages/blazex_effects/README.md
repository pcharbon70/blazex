# BlazeX Effects

Defines host-neutral capability requests, effects, opaque resources, grants,
ownership, cancellation, timeouts, fallback, and disposal. Components use these
contracts to request host facilities without receiving JavaScript, DOM, OS, or
native-toolkit objects.

Concrete providers belong in host adapters such as `blazex_host_browser`.
Renderer capabilities remain distinct and are negotiated through
`blazex_renderer`.

Status: experimental BH-02 Phase 3 implementation. Four proof capabilities,
deny-by-default negotiation, typed effect requests/results, a provider
behaviour, deterministic pending-effect tracking, and generation-scoped opaque
resource ownership/transfer/disposal are implemented. No concrete provider or
support claim exists.

## BH-05 Phase 1 activation

Governance only: existing experimental behavior is preserved, with no new
BH-05 callbacks, facade, process or support claim. Package ownership and API
migration decisions are recorded in `docs/research/assets/bh-05-baseline`.
Runtime/host profiles consume neutral contracts; LiveView and LocalLiveView
integration remain explicitly deferred.

## BH-05 Phase 8 action bridge

`ActionBridge` implements Core's abstract action port using declared bindings,
deny-by-default `Negotiation`, and the existing neutral `Effect` contract. The
runtime supplies provider configurations; they never enter component inputs.
Command declarations remain untrusted intent for an explicit future adapter,
not local authorization or an implemented server transport. No concrete browser,
OS or network provider is introduced.
