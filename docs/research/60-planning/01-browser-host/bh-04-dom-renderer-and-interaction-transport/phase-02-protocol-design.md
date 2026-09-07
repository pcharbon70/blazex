---
title: "BH-04 Phase 2 internal protocol design"
kind: note
created: "2026-09-07"
maturity: developing
tags:
  - bh-04
  - protocol
aliases: []
---

# BH-04 Phase 2 internal protocol design

## Authority and boundary

[Phase 2](phase-02-versioned-render-transaction-and-patch-protocol.md) is explicitly
authorized. [Authorization](../../../assets/bh-04-baseline/blazex-bh-04-phase-02-authorization-v0.1.0.json)
binds the accepted Phase 1 completion and inherited contracts. This is an internal
candidate; it does not change the BH-02 full-root batch, its Erlang-term digest,
or its fixtures. There is no implicit conversion from that batch to this protocol.

Only pure data validation and serialization are implemented. No reconciliation,
DOM application, event delivery, framework adaptation or component API is authorized.
Existing host-neutral renderer lifecycle remains unchanged; no neutral additions
are needed. DOM records belong in the standalone renderer, browser-side validation
in the runtime JavaScript package. Dependencies remain unchanged.

## Envelope and compatibility

Identity is `blazex.dom-transaction/1`, schema `1.0.0`. Exact version matching
is required; required capabilities are exactly `atomic` and `ordered` in that
order. Unknown versions/features are incompatible, never silently downgraded.
All future protocol changes require a new version, fixtures, both codec runs,
compatibility review and BH-04 acceptance. No public stability is implied.

An opaque owner token identifies the registry-owned root scope; generation is
positive and must equal the trusted preflight context. Semantic identity remains
host-neutral; DOM node IDs retain the `bx-` plus 24 lowercase hexadecimal format.
Caller code must map the owner token to the BH-03 root handle before dispatch.
The protocol cannot grant server authority.

Each transaction declares owner, generation, root node ID, base revision,
target revision (exactly base + 1), transaction ID, kind, capabilities, ordered
operations and SHA-256 digest. Initial traffic requires revision zero, empty
nodes and no root; patch/replace/dispose require the exact live context root.
Disposed roots reject traffic. The caller supplies a bounded recent-ID window;
duplicate detection outside that window is a later host retention policy, not
a global uniqueness claim.

Operations have sequential zero-based IDs and sorted unique dependencies on
earlier IDs. References must be known when used. Create declares detached nodes;
insert attaches them, move checks the old parent, and removal is leaf-first.
Pure topology preflight rejects missing references, cycles, wrong-parent anchors,
multiple roots and excessive depth. Value assertions carry explicit old and new
values; comparing old text/property/focus values with the actual materialized
state belongs to Phase 4, not this topology-only context.

Acknowledgements and diagnostics correlate with a bounded attempt header supplied
by trusted admission code, not by replaying the attempted transaction. This lets
rejections describe stale or incompatible attempts without accepting their traffic.
The context header records the kind and operation count, carries only safe
correlation fields, and must belong to the current owner and generation. Successful
acknowledgements additionally require compatible versions and current revisions.
It is not itself proof that application or rollback occurred. No arbitrary messages, stack traces, exception values,
partial-success state or foreign-root details may cross this protocol.

## Bounds and deterministic bytes

Integers are nonnegative safe integers at most 9007199254740991 (generations
positive). Limits are depth 32, nodes 128, operations 512, listeners 256,
attributes per node 32, text UTF-8 bytes 4096, values/attributes 2048,
queued transactions per root 64 and message bytes 131072. Queue bounds are
declared protocol policy only; queue enforcement belongs to Phase 4.

Canonical encoding is a closed, length-framed byte grammar: null `n`, booleans
`t`/`f`, integers `i<decimal>;`, UTF-8 strings `s<byte-count>:<bytes>`,
arrays `a<count>:<items>`, maps `m<count>:<key,value pairs>`. Map keys are
ASCII lowercase identifiers sorted lexicographically; arrays preserve order.
No floats, negative zero, invalid Unicode, arbitrary objects, duplicate map keys,
trailing bytes, nonminimal lengths or alternate encodings are accepted.
Decode must re-encode byte-for-byte. A message is bounded before decoding.

The transaction digest is lowercase SHA-256 of the canonical transaction map
with only its `digest` field removed. It is an integrity/correlation check, not
authentication. Encoding uses no map iteration, process clocks or browser state.

## Fail-closed policy and next work

The [closed schema](../../../../../integration/bh-04/render-transaction.schema.json)
defines exact fields for all twelve operation types and the three record classes.
The [inventory](../../../../../integration/bh-04/protocol-inventory-v0.1.0.json)
names all kinds, states and diagnostics. Attributes are allowlisted (no arbitrary
markup, URLs, handlers or styles); properties distinguish text value from booleans.
Listener IDs are unique within a root. Remove/replace require leaf targets;
replacement substitutes a detached created node at the asserted parent.
An effect barrier must be last and only declares post-commit resource ordering.
All operation old/new assertions are explicit, with no omitted-value coercion.
Selection offsets are UTF-16 code units for the DOM adapter; matching them to
actual form values is deferred to Phase 4/6. The current fourteen-name attribute
allowlist is stricter than the declared 32-attribute ceiling. Queue enforcement
and materialized attribute counts remain Phase 4 work; Phase 2 does not
represent their declaration as executed queue or browser evidence.
Acknowledgements with failure states require a diagnostic; successful states
forbid one. Disposed acknowledgements require a dispose transaction.
The schema's maxBytes extension is normative and enforced by both validators.

Malformed, incompatible, stale, duplicate, missing-target, ownership, limit,
apply, rollback and disposed-root are the closed diagnostic classes.
Overflow is rejected before dispatch; there is no truncation or coercion.
Applied/rollback/fallback outcomes are representable data, not evidence that
those behaviors are implemented. Phase 3 requires separate authorization.

[DEFERRED] Unavailable OS/browser/device/manual-AT qualification remains owned
by qualification-owner and due by BH-22, with no pass credit. Linux pure protocol
tests are active; browser outcome and performance result sets remain empty.

## Connections

- [Milestone index](README.md)
- [Phase 1 evidence](phase-01-implementation-evidence.md)
