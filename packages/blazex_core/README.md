# BlazeX Core

Defines the host-neutral component programming model: component behaviours,
lifecycle, stable identity, state transitions, semantic events, commands, and
the contracts used to evaluate a component tree.

This package must not depend on Phoenix, Plug, DOM or JavaScript types,
Popcorn/AtomVM, or any native UI toolkit. It is the innermost dependency of the
framework.

Status: experimental BH-02 Phase 2 implementation. Structural identity,
bounded portable props/state, evaluation context, pure/stateful mount and
update, replacement generations, and stable diagnostics are implemented.
BH-02 Phase 3 adds semantic events and stateful dispatch. Effects remain in
their dedicated package; process lifecycle, messages, commands, disposal, and
stable public APIs remain deferred.

## BH-05 Phase 1 activation

Governance only: existing experimental behavior is preserved, with no new
BH-05 callbacks, facade, process or support claim. Package ownership and API
migration decisions are recorded in `docs/research/assets/bh-05-baseline`.
Runtime/host profiles consume neutral contracts; LiveView and LocalLiveView
integration remain explicitly deferred.
