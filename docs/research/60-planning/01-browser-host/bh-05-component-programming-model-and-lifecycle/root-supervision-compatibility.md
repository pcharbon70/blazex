---
title: "BH-05 root supervision compatibility analysis"
kind: note
created: "2026-09-09"
maturity: developing
tags: [bh-05, atomvm, supervision, compatibility]
aliases: []
---

# BH-05 root supervision compatibility analysis

Scope: [Phase 6 root lifecycle](root-lifecycle-contract.md). Access date:
2026-09-09. This is source/API analysis alongside ERTS integration execution,
not an AtomVM or Wasm execution pass and not a release/support declaration.

## Executed and inspected identities

Local execution uses immutable Docker image `a2386c21edd5`, Elixir 1.17.3,
OTP 26.0.2, offline. It exercises temporary children, linked guardian exit
observation, sibling survival, explicit remount, acknowledgement deadlines,
rollback and post-commit cleanup with the public headless renderer.

The local Hex Popcorn **0.3.3** archive is SHA-256
`356084a017b3b6e37ad3c947313f7da9031eee083e77d03e1ba1f26b55e04835`.
Its `patches/otp/stdlib/supervisor.erl` removes hibernation and replaces an integer
monotonic-time unit; SHA-256
`69da759658bf86243810dda8801974021cb8d353006371ba2195bb3ab03aafd6`.
Its `patches/otp/stdlib/gen_server.erl` replaces unsupported stacktrace queries;
SHA-256 `1c777a14eb2a1ba5fb3977f4a8c7950f7c5e0d3c89dafc7c963ed8468390f544`.
These are patches to OTP modules, not replacements for the complete API.
The [subset check](../../../70-tools/check_bh05_root_subset.py) reads and hashes
the package members without extracting executables or accessing the network.

Official upstream **v0.7.0-alpha.0** resolves to commit
`f60c037ed43d01dfb87f7db4ccc8f348266f25bd`. Its Erlang supervisor exports
start/terminate/delete/which-children operations and supports one-for-one and
temporary children. Its own caveats exclude hibernation and automatic shutdown.
[Pinned supervisor source](https://github.com/atomvm/AtomVM/blob/f60c037ed43d01dfb87f7db4ccc8f348266f25bd/libs/estdlib/src/supervisor.erl).

| Inspected file at that commit | Raw source SHA-256 |
| --- | --- |
| `libs/estdlib/src/supervisor.erl` | `5d13763d7c5a6dbe974584fcb2bf3e5ec30c36a06e9a1c4eaa9a618860af9015` |
| `libs/estdlib/src/gen_server.erl` | `0d3dc9f49467c8433b57bd52462c0191709b327f7bdf62644c18c26cafb92448` |
| `libs/exavmlib/lib/Supervisor.ex` | `c153ced8f677fc1584c1212e3e09485bc0b7f92dc230aad5815208799c844d8b` |
| `libs/exavmlib/lib/GenServer.ex` | `2ede2aa9bcf9ce6c9e332b54c4e9e4723e6e3ec2454b314d9d8c259aadcedede` |
| `libs/exavmlib/lib/Process.ex` | `a443716411638448ab6eb4420dc412e534b214189ab7ddf1168012d9d100dd84` |

Reproduce source inspection with `gh api repos/atomvm/AtomVM/contents/PATH?ref=REV`;
decode the returned base64 `content` and SHA-256 those raw bytes. Source inspection
found the Elixir wrappers for Supervisor start/init/start-child/which-children/
terminate/delete and GenServer start-link/call. Process supplies trap-exit and
timer wrappers. Guardian termination uses `:erlang.exit/2` directly, not an
assumed `Process.exit/2` wrapper; the pinned VM NIF supports targeted kill and
trap-exit delivery. [Process wrapper](https://github.com/atomvm/AtomVM/blob/f60c037ed43d01dfb87f7db4ccc8f348266f25bd/libs/exavmlib/lib/Process.ex),
[VM exit implementation](https://github.com/atomvm/AtomVM/blob/f60c037ed43d01dfb87f7db4ccc8f348266f25bd/src/libAtomVM/nifs.c).

## Compatibility findings and qualification limits

| Surface | Phase 6 finding | Remaining qualification |
| --- | --- | --- |
| Core lifecycle | Local calls, links/trap-exit, temporary one-for-one children; no hibernate, handle-continue, dynamic supervisor, registry or distributed calls | Execute packaged root fixtures on the pinned browser profile |
| Deadlines | Infrastructure send-after/cancel-timer only; late timer messages correlate to pending transaction | Verify scheduler/timer behavior in Wasm, including lost acknowledgement |
| Privacy | Bounded public observations and ERTS format-status redaction | Qualify VM crash dumps and runtime logging; never treat source API similarity as privacy proof |
| Digests | Existing deterministic ERTS term encoding/SHA-256 | Cross-VM encoding/crypto parity remains Phase 11 |
| Renderer | Real headless session integration; existing BH-04 JavaScript transaction suites replayed unchanged | Browser wire mapping of these new root ports is not implemented here |

The upstream alpha Erlang GenServer explicitly does **not** support
`format_status`, even though the Elixir wrapper declares it. Thus standalone
upstream use cannot inherit the ERTS crash-log redaction claim. Public root
observation redaction is owned by our guardian, independently of that callback.
[Pinned GenServer caveats](https://github.com/atomvm/AtomVM/blob/f60c037ed43d01dfb87f7db4ccc8f348266f25bd/libs/estdlib/src/gen_server.erl).

Stable **v0.6.6**, commit `ff993a80963298b532c1e573f883951ecaac9fef`, exposes only
supervisor start-link operations in its small Erlang implementation, not the
dynamic child management needed here. It is **not a compatible standalone
target for this implementation**. No runtime upgrade is made or authorized by
this analysis. [Pinned v0.6.6 supervisor](https://github.com/atomvm/AtomVM/blob/ff993a80963298b532c1e573f883951ecaac9fef/libs/estdlib/src/supervisor.erl).

Owner: runtime profile owner. Reactivation: **BH-05 Phase 11**, which owns
packaged runtime execution/parity and must resolve the specific library/patch
composition and crash-log privacy before any Wasm qualification credit. These
unexecuted checks receive no pass credit; the Phase 6 executed lifecycle gate is
ERTS plus headless. Available ERTS failures remain blocking. No LiveView or
LocalLiveView integration, automatic retries, effects or application scheduling
is added. A forced supervisor shutdown or VM crash is not a promise of external
renderer cleanup; normal host removal uses the explicit acknowledged stop port.
