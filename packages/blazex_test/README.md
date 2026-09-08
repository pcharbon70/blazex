# BlazeX Test

Provides reusable component fixtures, renderer assertions, event scripts,
runtime probes, and harnesses for testing behavior across hosts and profiles.

Shared conformance definitions belong here when they are useful to downstream
packages; repository-wide suites and executable matrices belong under
`integration/`.

Status: experimental BH-02 Phase 5 support. Backend-neutral lifecycle scripts
and exact artifact equality assertions are implemented. No concrete backend,
runtime, browser, server, or support claim is included.

## BH-05 Phase 1 activation

Governance only: existing experimental behavior is preserved, with no new
BH-05 callbacks, facade, process or support claim. Package ownership and API
migration decisions are recorded in `docs/research/assets/bh-05-baseline`.
Runtime/host profiles consume neutral contracts; LiveView and LocalLiveView
integration remain explicitly deferred.
