# Protocol test support

- [Phase 7 component](effect_component.exs) and [test-only runtime carrier](effect_runtime.exs) execute real Elixir emissions and acknowledgements without Phoenix/Plug or new Wasm packaging.

- [Continuity component](continuity_component.exs) — real controlled fields and stable single/multiple choices.
- [Continuity runtime](continuity_runtime.exs) — test-only offline ERTS carrier for the v3 opt-in endpoint.

- [Interaction counter](interaction_counter.exs) — existing semantic callbacks for all 13 mappings, including unchanged-render outcomes.
- [Interaction runtime](interaction_runtime.exs) — test-only bounded stdio carrier to real Elixir evaluation and reconciliation; not a packaged Wasm endpoint.

- [Phase 4 atomic DOM fixture runner](atomic_dom_runner.exs) adds real mount transactions to the frozen reconciliation scenarios.

- [Phase 3 cases](reconciliation_cases.exs) define 50 real renderer callback traces and full-root projection parity.
- [Phase 3 trace runner](reconciliation_runner.exs) regenerates or checks canonical trace evidence.
- [Phase 3 protocol runner](reconciliation_protocol_runner.exs) compares the v2 Elixir codec/validator with Node.

- [Elixir runner](protocol_runner.exs) reads canonical fixtures and emits normalized bytes, digests and error classes. It performs no DOM or runtime dispatch.
