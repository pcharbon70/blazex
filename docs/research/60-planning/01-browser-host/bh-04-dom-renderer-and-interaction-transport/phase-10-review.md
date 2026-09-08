---
title: "BH-04 Phase 10 evidence review and re-entry findings"
kind: note
created: "2026-09-08"
maturity: developing
tags: [bh-04, acceptance, review]
aliases: []
---

# BH-04 Phase 10 evidence review and re-entry findings

This is an evidence-first **implementer review**, not an independent specialist
approval. Ownership roles below are accountable future reviewers, not people
who have supplied sign-off. Independent reviewer authorization was requested;
no response or separate review is credited in this candidate.

## Findings

| Finding | Severity / owner | Disposition and re-entry requirement | Blocks |
| --- | --- | --- | --- |
| BH04-10-PAINT | high / performance-owner | Open. Double requestAnimationFrame records opportunities, not compositor paint. Add correlated actual paint tracing for both active engines; freeze the revised method before rerunning at least 100 samples each. Do not rename the proxy a paint result. Due before BH-04 acceptance. | acceptance and BH-05 |
| BH04-10-INDEPENDENCE | high / quality-owner | Open. Implementer review cannot fulfill independent evidence-first review. Obtain separately authorized reviewers across all eight lenses and retain their findings/disagreements against the exact final candidate. Due before BH-04 acceptance. | acceptance and BH-05 |
| BH04-10-ATTEMPT-RETENTION | medium / renderer-owner | Corrected by retaining completed rows when scenario execution throws, with a forced-failure probe in each browser. The original aborted attempt remains uncredited; the final rerun must include the probe and full sample minima. Review trigger: harness exception handling changes. | until final rerun passes |
| BH04-10-FORMATTING | low / renderer-owner | Corrected. Whole-corpus formatting exposed seven historical fixture scripts. Apply the pinned formatter and rerun fixture generation, package and browser checks; historical evidence is replayed at its original revision. Review trigger: any fixture change. | until final rerun passes |
| BH04-10-CLEAN-HOST | medium / qualification-owner | Bounded condition only. Offline clean Docker builds are independent build directories on the same host, not an independent machine/operator. Repeat a representative subset on an independently controlled clean host before BH-22 qualification. | release qualification |

No waiver, threshold change or scenario deletion is proposed. Open active
findings cannot be deferred under the unavailable-environment policy. A merge
of this evidence candidate is not BH-04 acceptance.

## Eight review lenses

1. **Architecture — architecture-owner.** Read the retained semantic/DOM and
   effect boundaries, Phase 9 application fixture audit, and standalone dependency
   isolation. Components still use Core/UITree contracts; DOM objects remain
   renderer-private. The ERTS test carrier does not establish a new Wasm endpoint.
   LiveView/LocalLiveView integration is expressly deferred, not impossible.
2. **Implementation — renderer-owner.** Inspected `DOMRootQueues`,
   `AtomicDOMRoots`, `EffectDOMRoots`, transaction planning and the new harness.
   Generation/owner checks precede application; commit updates projection only
   after synchronous DOM verification. Rollback preserves retained identities;
   unrecoverable application failures quarantine the root. See the harness
   partial-retention defect above; an aborted run is not clean evidence.
3. **Renderer/conformance — renderer-owner.** The canonical 51 semantic cases
   compare actual headless snapshots and standalone browser observations twice
   per engine. Replays independently evaluate runtime acknowledgement chains.
   Fifty atomic cases include 1,204 injected operation boundaries per browser.
   Tests are bounded fixture coverage, not every future product component.
4. **Security — security-owner.** Reviewed canonical shape/digest checks,
   root capabilities, attribute/property allowlists and effect grants. The new
   benchmark server binds loopback and serves only renderer/integration JS;
   it has no application-command or production-server authority. Chrome runs
   with sandbox disabled in this test environment, so production security is
   not qualified. Bounded diagnostics contain codes, not exception payloads.
5. **Accessibility — accessibility-owner.** Phase 9 computed role/name snapshots,
   direct relationship/state attributes, reading order and rollback continuity
   remain the automated oracle. Focus, selection, composition and cleanup are
   rerun. Neither computed snapshots nor headless rendering is manual AT proof.
   Native platform and physical-device qualification remains owned and deferred.
6. **Performance/reliability — performance-owner.** Raw timing boundaries use
   one monotonic browser clock and retain one labeled setup sample plus all 100
   measured samples. Final Chrome p95 30.3 ms, Firefox 32 ms are frame proxies only.
   CV is 6.51% / 3.35%; no >10% investigation trigger in this run. No matching
   previous BH-04 baseline exists, so no regression percentage is invented.
   Queue bursts reject the 65th proposal; no unsafe coalescing is credited.
   All 1,000 messages per path per engine are stale-rejected. Failed cleanup
   leases remain counted rather than reset to zero; a real cleanup failure
   would block acceptance, not become a passing zero-resource snapshot.
7. **Packaging/dependency — packaging-owner.** No runtime dependency or lock
   upgrade is requested. Standalone builds mount only six core/renderer packages
   and a protocol fixture with frameworks/profiles physically absent. Existing
   profile-level Phoenix/Popcorn/AtomVM/private pins remain inherited risks, not
   removed dependencies or new standalone-runtime proof. The future Plug profile
   remains unactivated; no public package publication is authorized.
8. **Provenance — quality-owner.** Authorization binds the accepted Phase 9 merge,
   all active phase completion identities, quality registry, roadmap and policy.
   Historical validators execute their accepted snapshots; current candidate
   validation is separate. Reports derive statistics and hashes from raw data.
   The canonical planned acceptance registry is unchanged. Section commits,
   raw failures, test logs and the final decision remain visible.

## Inherited obligations and negative conclusions

Carry the entire BH-03 entry ledger, including AVM reachability, Firefox timer
workaround, private API pins, runtime-repeat obligations, Brotli serving,
production security, release controls, native role gaps and unavailable
qualification. This phase changes no runtime/bundle bytes. Historical runtime
passes do not authorize changing those bytes later without reruns. Existing
BH-03 corrective acceptance does not close unrelated renderer measurements.

BH-05 remains **ineligible and unauthorized** while active findings are open.
Public component API, product components, server authority, Plug execution,
prerender/activation and release support remain later work. The requested
scripts-move warning remains due at actual BH-04 acceptance; no scripts move
is performed or implied by this review.

## Connections

- [Frozen acceptance contract](phase-10-acceptance-contract.md)
- [Phase 10 plan](phase-10-measurement-review-and-bh-04-acceptance.md)
- [Milestone index](README.md)
- [Entry ledger](../../../assets/bh-04-baseline/blazex-bh-04-entry-ledger-v0.1.0.json)
- [Raw measurements](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-measurements-v0.1.0.json)
- [Statistics](../../../assets/bh-04-baseline/blazex-bh-04-phase-10-statistics-v0.1.0.json)
