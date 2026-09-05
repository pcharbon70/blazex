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
