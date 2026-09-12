---
title: "BH-06 Runtime-Closure Reduction Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, contract, pruning, reachability]
aliases: []
---

# BH-06 Runtime-Closure Reduction Contract

Phase 9 reduces only the Phase 8 base inputs. The counter feature remains an
independently verified archive. The policy binds the pinned Popcorn tree-shaker,
the exact original input-set identity, explicit roots, and bounded keep, leave,
ignore, and drop sets. Module names must already exist in the trusted inventory;
policy loading may not create atoms.

The generated report retains path-free module identities, input and output
hashes and sizes, removed modules, removed functions, totals, and policy/tool
identities. Output must be non-empty, contain no additions, retain every root,
and be reproducible. A removed module or function absent from the report, an
unknown declaration, or overlap between incompatible policy sets rejects.

Reduction is not success by itself. The unchanged Phase 8 payload policy must
accept the candidate, and both browsers must execute the full dynamic feature
and component lifecycle without missing-code errors. Local proof does not
generalize to arbitrary applications or production delivery. LiveView and
LocalLiveView remain **[DEFERRED]**.

## Connections

- [Phase 9 plan](phase-09-audited-runtime-closure-reduction.md)
- [Phase 8 payload contract](payload-accounting-contract.md)
