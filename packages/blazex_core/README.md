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
