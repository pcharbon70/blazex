# BH-01 Phase 3 artifact-accounting findings

## Result

Two clean equivalent builds produced 21 byte-identical outputs: twelve runtime
binaries/compressed variants, three normalized runtime build logs, and six
debug/release fixture artifacts. The unified manifest additionally accounts
for build inputs, generated manifests, the empty patch set, embedded debug
sections, source-map omissions, licensing/notice obligations, ownership, and
reachability.

This is an initial artifact-accounting result. Exact sizes are observations,
not passed payload budgets, and no browser artifact has been loaded yet.

## Determinism investigation

The first comparison exposed two nondeterministic inputs that were corrected
before evidence was retained:

- Ninja's four-way parallel build emitted completion records in scheduler-
  dependent order. The build keeps parallel compilation but replaces progress
  indices and bytewise-sorts the complete transcript before recording
  `build.log`. The Wasm, JavaScript, and gzip outputs were already identical.
- The generated fixture boot module captured `Application.get_all_env/1` as an
  unsorted keyword list. Logger environment enumeration changed literal and
  closure identities while preserving behavior. Sorting every captured
  application environment made both debug and release AVM bundles identical.

The temporary boot BEAM is now deleted after bundling. It is an input to the
AVM, not an undeclared deployment output. Runtime CMake/Ninja object trees are
explicitly excluded clean-build intermediates and are never copied into a
runtime or evidence distribution.

## Observed primary payloads

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Debug web runtime Wasm | 4,210,633 | `e6025168933b62dec3650d9b9f78eb9f613e4eb21407ad837cb0dce9f1a55768` |
| Release web runtime Wasm | 986,537 | `d20c491e75936dc8189910c8d0740093b7813d8dcc1cf966a87c011799ade9d8` |
| Release Node-probe runtime Wasm | 986,130 | `7c31ad202adad7e8dca83f0da3a3ac7578c0ee7ea33d51ddc0e44f50e7df6814` |
| Debug fixture AVM | 6,987,416 | `8fc4e73c4afc8945c745d23492b8ae4a355948f44e9092aad7f0d9d49178e72a` |
| Release fixture AVM | 6,541,768 | `4f4b7adf6b138df2c232cb03a390674b07f6b51d015722cc0654bd25c4a66a22` |

The fixture intentionally establishes an unpruned correctness baseline. Its
size is therefore a risk observation for Phase 9, not evidence that a browser
payload budget is acceptable.

## Maps, symbols, licenses, and reachability

Debug runtime symbols are embedded as named DWARF custom sections in the debug
Wasm carrier. Release runtime debug/name sections are stripped. No runtime or
fixture mode emits an external source map; each omission has a stable record.

All eight direct runtime/fixture inputs have exact origins, content identities,
known license dispositions, notice-retention requirements, owners, and build
or runtime reachability. No BlazeX source patch is applied. The manifest fails
closed on duplicate IDs or paths, orphaned/undeclared outputs, missing hashes,
unknown licenses, missing reachability, source-map drift, repeat differences,
or a premature budget-pass claim.

## Evidence

- Accounting contract: `artifact-accounting-contract.json`
- Unified manifest: `../../../docs/research/assets/bh-01-baseline/blazex-bh-01-phase-03-artifact-manifest-v0.1.0.json`
- Repeat evidence: `../raw-evidence/bh01-phase3-artifact-reproducibility.json`
- Notices: `../../../packages/blazex_runtime_popcorn/runtime/THIRD_PARTY_NOTICES.md`
