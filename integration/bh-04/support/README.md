# Protocol test support

- [Phase 4 atomic DOM fixture runner](atomic_dom_runner.exs) adds real mount transactions to the frozen reconciliation scenarios.

- [Phase 3 cases](reconciliation_cases.exs) define 50 real renderer callback traces and full-root projection parity.
- [Phase 3 trace runner](reconciliation_runner.exs) regenerates or checks canonical trace evidence.
- [Phase 3 protocol runner](reconciliation_protocol_runner.exs) compares the v2 Elixir codec/validator with Node.

- [Elixir runner](protocol_runner.exs) reads canonical fixtures and emits normalized bytes, digests and error classes. It performs no DOM or runtime dispatch.
