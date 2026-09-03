---
title: "Phase 4 Disposition Capability Fallback and Portability Evidence"
kind: note
created: "2026-09-03"
maturity: developing
tags:
  - bh-00
  - component-catalog
  - implementation-evidence
  - product-classification
aliases:
  - "BH-00 phase 4 evidence"
---

# Phase 4 Disposition Capability Fallback and Portability Evidence

## Section 4.1 — BlazeX dispositions and delivery tiers

### Delivered artifacts

- The [disposition, tier, and package
  policy](../../../20-notes/blazex-component-disposition-tier-and-package-policy.md)
  defines six explicit family outcomes, exception outcomes, F0–F4 dependency
  meanings, six approved component packages, payload classes, extraction
  triggers, package layering, and compatibility nonclaims.
- The [classification
  schema](../../../assets/component-catalog/blazex-component-classification.schema.json)
  reserves all Phase 4 product, capability, remote, fallback, portability,
  native-strategy, visual-profile, backend-gate, and evidence fields.
- Canonical [classification
  v0.1.0](../../../assets/component-catalog/blazex-component-classification-v0.1.0.json)
  is cryptographically bound to Phase 3 catalog SHA-256
  `ec0f413c9968b92878e71c1aae9570286dd68ec538938ad880d8908cf7ea70a3`.
  It covers all 83 stable family IDs and all twelve exception IDs exactly once.
- The [generated joined
  view](../../../assets/component-catalog/blazex-component-classification-v0-1-0-generated.md)
  displays source names with their separate BlazeX product classifications.

### Classification result

| Dimension | Counts |
| --- | --- |
| Disposition | 43 `build-natively`; 28 `adapt-concept`; 11 `replace-with-platform-pattern`; 1 `renderer-specific-extension` |
| Delivery tier | 13 F0; 26 F1; 21 F2; 18 F3; 5 F4 |
| Package | 47 `blazex_ui`; 18 `blazex_forms`; 9 `blazex_surfaces`; 6 `blazex_data`; 2 `blazex_ui_tree`; 1 `blazex_charts` |
| Source exceptions | 12 explicit outcomes: omit evidence-only material, retain infrastructure/service evidence, or preserve reviewed zero findings |

No family remains unresolved, silently deferred, or omitted. `Element` is an
allowlisted renderer extension rather than a portable arbitrary-tag API.
Provider/internal-shaped families such as BreakpointProvider, Input,
InputControl, Overlay, Picker, RTLProvider, Render, and ThemeProvider become
BlazeX framework patterns. MessageBox and TableSimple become a Dialog recipe
and simple-table mode rather than parallel compatibility APIs.

All prerequisites exist, are same/earlier tier, follow package-layer rules,
and form an acyclic graph. Optional package and payload classifications match
the repository's forms, surfaces, data, and chart boundaries. No profile,
runtime, host, renderer adapter, Phoenix, Plug, or LiveView package owns
portable component behavior.

### Section validation

```text
Component classification validation passed: stage section-4.1; 83 families; 12 exceptions; dispositions {'adapt-concept': 28, 'build-natively': 43, 'renderer-specific-extension': 1, 'replace-with-platform-pattern': 11}; tiers {'F0': 13, 'F1': 26, 'F2': 21, 'F3': 18, 'F4': 5}; packages {'blazex_charts': 1, 'blazex_data': 6, 'blazex_forms': 18, 'blazex_surfaces': 9, 'blazex_ui': 47, 'blazex_ui_tree': 2}.
Ran 9 tests ... OK
```

Negative tests reject source drift, missing family coverage, duplicate public
identities, later-tier prerequisites, forbidden package dependencies,
implementation claims, premature Section 4.2 metadata, and stale generation.

### Evidence boundary

Classification state is `accepted`; implementation state remains `unknown`
with no evidence IDs. Provisional `BlazeX.*` identities are planning names,
not modules, atoms, shipped APIs, or compatibility promises. Capability,
remote, fallback, portability, native, visual-profile, and backend-coverage
fields remain explicitly unassigned/unproven for Sections 4.2 and 4.3.

## Section 4.2 — Capabilities, remote authority, and fallbacks

### Delivered artifacts

- The [capability registry
  v0.1.0](../../../assets/component-catalog/blazex-capability-registry-v0.1.0.json)
  defines fourteen stable contracts with purpose, lifecycle, security boundary,
  unsupported behavior, `blazex_effects` ownership, and opaque provider rules.
- The [capability, remote, and fallback
  policy](../../../20-notes/blazex-component-capability-remote-and-fallback-policy.md)
  defines required/optional semantics, effect and resource ownership,
  cancellation/timeout/cleanup, five remote states, server revalidation, eight
  fallback outcomes, nine mandatory conditions, and forbidden backend tokens.
- All 83 canonical classifications now assign required/optional capabilities,
  renderer semantics, portable requirement tokens, lifecycle ownership, remote
  authority/rationale, primary fallback/rationale, and every condition-specific
  fallback.

### Capability result

There are 204 required and 77 optional capability references. Every family
requires `BX-CAP-ACCESSIBILITY`. Focus is required by 40, keyboard by 48,
measurement by 12, surface by 14, window by 3, pointer by the 3 pointer-defined
families, and files by FileUpload. Optional enhancements include pointer (45),
network (10), clipboard (6), time (5), measurement/window (4 each), and one
each for notifications, storage, and system theme.

Managed subscriptions and leased resources require cancellation, host timeout
policy, generation invalidation, and idempotent cleanup. Capability and
renderer tokens use only BlazeX semantic vocabulary; validation rejects DOM,
JavaScript, CSS, Phoenix/LiveView socket, native-widget, filesystem, and script
escape tokens.

### Remote and fallback result

| Dimension | Counts |
| --- | --- |
| Remote authority | 73 `local-only`; 7 `optional-remote`; 3 `phoenix-enhanced` |
| Primary fallback | 30 `static-content`; 30 `alternative-interaction`; 14 `in-app-substitute`; 5 `server-round-trip`; 2 `explicit-unavailable`; 1 `nonvisual-representation`; 1 `omission` |

No family intrinsically requires Phoenix or is unavailable in Plug. Form,
FileUpload, and Snackbar may use richer Phoenix adapters while preserving
portable/local or Plug paths. Autocomplete, Select, List, Table, DataGrid,
TreeView, and Virtualize may attach authenticated remote providers. Client
presentation remains untrusted and cannot authorize any action.

All 83 rows explicitly classify no JavaScript, no network, denied permission,
missing capability, unsupported renderer, failed resource, reduced motion,
forced colors, and assistive-technology access. Required capabilities can
never pair with a `not-required` missing-capability fallback; remote rows must
have a no-network fallback.

### Section validation

```text
Component classification validation passed: stage section-4.2; 83 families; 12 exceptions; dispositions {'adapt-concept': 28, 'build-natively': 43, 'renderer-specific-extension': 1, 'replace-with-platform-pattern': 11}; tiers {'F0': 13, 'F1': 26, 'F2': 21, 'F3': 18, 'F4': 5}; packages {'blazex_charts': 1, 'blazex_data': 6, 'blazex_forms': 18, 'blazex_surfaces': 9, 'blazex_ui': 47, 'blazex_ui_tree': 2}; remote {'local-only': 73, 'optional-remote': 7, 'phoenix-enhanced': 3}; fallbacks {'alternative-interaction': 30, 'explicit-unavailable': 2, 'in-app-substitute': 14, 'nonvisual-representation': 1, 'omission': 1, 'server-round-trip': 5, 'static-content': 30}; capability references 204 required/77 optional.
Ran 13 tests ... OK
```

Additional negative tests reject unknown capabilities, unassigned remote
authority, missing required-capability fallback, and backend-specific portable
tokens. Product/package results remain unchanged and all portability/native
fields remain unproven for Section 4.3.

## Remaining Phase 4 work

- Section 4.3 must assign renderer portability, semantic obligations, native
  strategy, visual profile, and future-backend gates.
- Section 4.4 must close coherence, independent high-risk review, determinism,
  nonclaim evidence, and PR delivery.

## Connections

- [Phase 4 plan](phase-04-disposition-capability-fallback-and-portability-classification.md)
- [BH-00 plan](README.md)

## Sources

- [Locked Phase 3 source catalog](../../../assets/component-catalog/blazex-component-catalog-v0.1.0.json)
- [MudBlazor-inspired component system](../../../20-notes/mudblazor-inspired-component-system-for-blazex.md)
