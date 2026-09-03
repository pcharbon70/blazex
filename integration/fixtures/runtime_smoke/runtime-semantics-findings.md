# BH-01 Phase 3 runtime-semantics findings

## Result

The release AVM fixture ran successfully on the pinned FissionVM WebAssembly
runtime under Node 26.8.1. The run emitted 33 contiguous lifecycle records,
returned `ok`, retained the fixed 256-page shared memory, and ended with a
zero-length mailbox after a second process-tree teardown.

This is a runtime feasibility result only. It does not claim browser loading,
DOM behavior, production scale, or supported host interoperability.

## Process and mailbox behavior

The probe successfully exercised a linked OTP supervisor/worker tree, bounded
request/reply messaging, a controlled child crash, monitor delivery, automatic
supervisor restart, selective receive, and mailbox ordering. A second process
tree was started and stopped after the primary tree. All test-injected and
lifecycle messages were consumed before the final mailbox observation.

No required process primitive was missing in this slice. The result does not
establish scheduler fairness, large-mailbox behavior, or high process counts;
those remain later resilience and measurement work.

## Timer, generation, and cleanup behavior

One-shot and two-tick repeated timers fired, a bounded receive timed out, stale
and current generations were distinguished, and a deliberately late result was
first timed out and then drained. Monotonic time advanced during the sequence.

`Process.cancel_timer/1` returned `false` in AtomVM although the cancelled
message was not delivered during the bounded observation window. BlazeX must
therefore use non-delivery plus generation checks as the correctness boundary;
it must not treat the return value as equivalent to OTP's remaining-time
integer. This is a documented semantic deviation, not a normalized result.

The final runtime trace reported `cleanup=complete`; the host reported 256
memory pages; and the guest reported `message_queue_len=0` after repeated
teardown.

## Serialization and host boundary

The Wasm-executed fixture validated a versioned, exact-key request envelope
with positive request/generation identities, an allowlisted operation tag, and
bounded scalar/list/map payloads. It exercised matched response identity,
duplicate request and reply rejection, stale generation, cancellation,
host/runtime failure classification, unknown tags, prohibited capability keys,
and post-disposal traffic.

The protocol rejects code, DOM-handle, filesystem-path, secret, non-string-key,
over-depth, over-collection, oversized-string, unsupported-value, and
unbounded-payload shapes. These are fixture constraints, not yet a public
BlazeX protocol.

An attempted direct asynchronous `Module.call` from the same Node process
timed out: the VM owns that event loop while its BEAM entrypoint is waiting, so
the scheduled JavaScript callback cannot drive the guest. The canonical Node
probe therefore uses structured stdout as the actual runtime-to-host boundary
and executes request/reply policy inside Wasm. Phase 4 must prove direct calls
from a worker-separated browser host before browser interoperability can pass.

## Compatibility interpretation

The VM reports OTP release `27` while Popcorn requires OTP 26.0.2 to build the
patched application bundle. That difference is retained explicitly because VM
capability identity and BEAM build identity are not interchangeable.

The three observed deviations are bounded for continued feasibility work:

- timer correctness is guarded by generation and non-delivery checks;
- VM-reported OTP and package-build OTP are recorded separately;
- direct calls are deferred to the worker-separated browser architecture and
  remain a Phase 4 gate.

No deviation changes component semantics, creates a server-authority path, or
introduces a DOM/browser dependency into the runtime adapter. Phase 3 may
continue; Phase 4 must fail closed if the worker-separated host cannot provide
bounded request/reply, cancellation, and disposal behavior.

## Evidence

- Contract: `semantics-contract.json`
- Scenario: `../scenarios/bh01-runtime-semantics.json`
- Normalized raw observation: `../raw-evidence/bh01-phase3-runtime-semantics.json`
- Release fixture: SHA-256 `4f4b7adf6b138df2c232cb03a390674b07f6b51d015722cc0654bd25c4a66a22`, 6,541,768 bytes
- Debug fixture: SHA-256 `8fc4e73c4afc8945c745d23492b8ae4a355948f44e9092aad7f0d9d49178e72a`, 6,987,416 bytes
- Shared module inventory: 584 modules
