# BlazeX Core

Defines the host-neutral component programming model: component behaviours,
lifecycle, stable identity, state transitions, semantic events, commands, and
the contracts used to evaluate a component tree.

This package must not depend on Phoenix, Plug, DOM or JavaScript types,
Popcorn/AtomVM, or any native UI toolkit. It is the innermost dependency of the
framework.

Status: experimental BH-02 Phase 2 implementation. Structural identity is
implemented; component evaluation follows within the same authorized phase.
Events, effects, process lifecycle, messages, commands, disposal, and stable
public APIs remain deferred.
