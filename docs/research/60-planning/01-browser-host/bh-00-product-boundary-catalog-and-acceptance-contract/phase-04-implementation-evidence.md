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

## Section 4.3 — Renderer portability and native strategy

### Delivered artifacts

- The [portability, native, and visual-profile
  policy](../../../20-notes/blazex-component-portability-native-and-visual-profile-policy.md)
  defines eight portability states, seven semantic dimensions, six native
  strategies, four visual profiles, platform-versus-BlazeX visual conflicts,
  and the future backend support gate.
- Every family now records semantic nodes, events, capability effects,
  accessibility, layout, focus, resources, renderer extensions, portability
  rationale, native strategy, visual-profile rationale, and six backend-gate
  requirements.

### Portability and native result

| Dimension | Counts |
| --- | --- |
| Portability | 24 `portable-semantic`; 57 `portable-with-capabilities`; 1 `renderer-extension`; 1 `custom-scene` |
| Native strategy | 15 `native-preferred`; 58 `native-composite`; 2 `custom-drawn`; 8 `not-applicable` |
| Visual profile | 15 `platform-native`; 58 `hybrid`; 2 `blazex-material`; 8 `not-applicable` |

No family is classified DOM/WebView-only, native-only, unsupported, or
unproven. `Element` is the bounded renderer extension with an omission
fallback, not a portable arbitrary-tag API. `Chart` is the custom scene and
requires scene drawing plus a nonvisual assistive-technology representation.
Skeleton is the second intended custom-drawn native strategy but remains a
portable semantic family.

Standard form/action/media controls with credible stock equivalents are
native-preferred and prioritize OS semantics/accessibility over MudBlazor
appearance. Compound families are native-composite and use a hybrid visual
profile. Contexts, semantic internals, and the bounded renderer extension have
no direct widget mapping.

### Future backend gate

Every non-extension family requires headless traces, DOM evidence, the BH-02
native spike before a portable/native claim, backend accessibility, fallback,
and documentation. The renderer extension requires per-backend evidence but
cannot imply cross-backend native proof. Thus headless plus DOM success is
machine-insufficient for native support.

The gate records obligations only. No renderer coverage cell is marked passed,
no toolkit is selected, and no native/platform support state is created.

### Section validation

```text
Component classification validation passed: stage section-4.3; 83 families; 12 exceptions; dispositions {'adapt-concept': 28, 'build-natively': 43, 'renderer-specific-extension': 1, 'replace-with-platform-pattern': 11}; tiers {'F0': 13, 'F1': 26, 'F2': 21, 'F3': 18, 'F4': 5}; packages {'blazex_charts': 1, 'blazex_data': 6, 'blazex_forms': 18, 'blazex_surfaces': 9, 'blazex_ui': 47, 'blazex_ui_tree': 2}; remote {'local-only': 73, 'optional-remote': 7, 'phoenix-enhanced': 3}; fallbacks {'alternative-interaction': 30, 'explicit-unavailable': 2, 'in-app-substitute': 14, 'nonvisual-representation': 1, 'omission': 1, 'server-round-trip': 5, 'static-content': 30}; capability references 204 required/77 optional; portability {'custom-scene': 1, 'portable-semantic': 24, 'portable-with-capabilities': 57, 'renderer-extension': 1}; native {'custom-drawn': 2, 'native-composite': 58, 'native-preferred': 15, 'not-applicable': 8}; visual profiles {'blazex-material': 2, 'hybrid': 58, 'not-applicable': 8, 'platform-native': 15}.
Ran 17 tests ... OK
```

Additional negative tests reject unproven status, portable-semantic rows with
specialized capabilities, an extension without its allowlisted extension ID,
backend-specific semantic tokens, and any attempt to let headless/DOM coverage
skip the native-spike gate.

## Section 4.4 — Integration and phase completion evidence

### Reproducible verification

| Check | Command or method | Result |
| --- | --- | --- |
| Complete classification/schema/source join | `python3 validate_component_classification.py` | Passed: 83 families, 12 exceptions, all locked product/capability/fallback/portability counts. |
| Classification positive/negative paths | `python3 -m unittest test_validate_component_classification.py` | Passed: 21 tests. |
| Generated view freshness | `python3 generate_component_classification.py --check` | Passed: stage complete, 83 families, 12 exceptions. |
| Clean deterministic generation | Generate to two `/tmp` outputs and `cmp -s` | Byte-identical; both SHA-256 `297fbf6946cf340675064a78efcdc4791f18e60d8ba85042217e4908001039e8`. |
| Phase 3 source/catalog regression | Catalog validator and 17 tests | Passed: exact lock, 83 families, 168 identifiers, 15 exception paths, fresh source-catalog view. |
| Browser envelope regression | Browser-envelope validator and 17 tests | Passed; classification did not alter browser/profile/trust policy. |
| Corpus structure and links | Archive validator and 8 tests | Passed: 92 completed documents, 15 directories, 604 links, 28 source notes. |
| Patch hygiene | `git diff --check` | Passed with no whitespace errors. |

### Locked classification invariants

| Invariant | Locked result |
| --- | --- |
| Source binding | Phase 3 catalog SHA-256 `ec0f413c9968b92878e71c1aae9570286dd68ec538938ad880d8908cf7ea70a3` |
| Classification artifact | SHA-256 `613de39b6dda7512dfb98306bc53594b137cc484e8dcaf33c10eb0f0d3379b58` |
| Stable coverage | 83/83 family IDs; 12/12 exception IDs; no missing, extra, or duplicate records |
| Product graph | 39 prerequisite edges; acyclic, same/earlier tier, legal package direction |
| Capability/fallback | 204 required + 77 optional references; 747/747 condition cells assigned |
| Completion values | Zero `unassigned`, `unproven`, or `unresolved` values |
| Evidence states | 83 accepted classifications; 83 unknown implementations; zero implementation evidence IDs |

The locked count tables remain those recorded in Sections 4.1 through 4.3.
Validation now rejects any drift in disposition, tier, package, remote,
fallback, capability-reference, portability, native, visual-profile,
prerequisite-edge, or exception-outcome totals unless a future version updates
the reviewed contract deliberately.

### Independent category and high-risk review

The [classification review
report](../../../assets/component-catalog/blazex-component-classification-v0-1-0-review.md)
checks every source category and the high-risk family set: Form, Autocomplete,
FileUpload, TextField, Picker, Dialog, NavMenu, PageContentNavigation,
ExitPrompt, DropZone, SplitPanel, SwipeArea, DataGrid, Table, Virtualize, Chart,
and Element.

Principal decisions confirmed:

- file selection uses opaque file capabilities and no filesystem/browser
  object; upload commands remain server-authoritative;
- surfaces explicitly own focus, measurement, stacking, dismissal, resources,
  cleanup, and inline/in-app alternatives;
- navigation/window behavior uses semantic intents and window capability, not
  DOM events or Phoenix routing types;
- drag, split, and swipe retain keyboard/direct-action alternatives;
- DataGrid/Virtualize remain F4 optional/runtime-heavy with optional remote
  providers and server-round-trip/nonvirtualized fallbacks;
- Chart remains a separate asset-heavy custom scene with nonvisual data; and
- Element remains a bounded renderer extension with omission fallback rather
  than a portable escape hatch.

The report also records all twelve accepted exception outcomes and the exact
changes from prior tier ranges/descriptive targets to one tier, package,
disposition, capability, fallback, and portability contract per family.

### Contradiction and compatibility audit

The schema and validator reject omitted-but-tiered/package rows, missing
rationales, duplicate identities, dependency cycles, illegal package edges,
backend tokens in portable requirements, required capabilities without
fallback, remote needs without no-network behavior, unmanaged resource
lifecycle, renderer-extension mismatch, inaccessible custom scenes, and
portable/native intent without the native-spike gate.

No family is intrinsically unavailable in Plug, carries a LiveView/Phoenix
socket requirement, or puts component behavior in an adapter/profile. No row
is DOM-only, native-only, unsupported, implemented, evidenced, supported,
native-compatible, MudBlazor-compatible, or .NET/API-compatible. Accepted
classification is not delivery evidence.

### Revision and review record

- Section 4.1 disposition/tier/package revision: `f3393f2`.
- Section 4.2 capability/remote/fallback revision: `5cba122`.
- Section 4.3 portability/native/visual revision: `344fd75`.
- Classification/schema/capability-registry versions: `0.1.0` / `1.0.0` /
  `0.1.0`.
- Product, package, capability, fallback, portability, native, visual-profile,
  accessibility/security-boundary, and integration review: Codex under the
  repository owner's instruction.
- Independent second-party review remains the Phase 6 BH-00 acceptance gate.
- Phase delivery: [PR #7](https://github.com/pcharbon70/blazex/pull/7),
  containing one final commit for each of Sections 4.1 through 4.4.
- The repository owner authorized creation and immediate merge of the single
  Phase 4 PR, followed by main synchronization and feature-branch deletion.

### Scope boundary

Phase 4 changed research policy, machine classifications, deterministic views,
validation, and review evidence only. It created no Mix/JavaScript project,
runtime, renderer, component implementation, native toolkit selection,
quality budget, acceptance threshold, browser support record, or Phase 5 work.

### Section result

All local Phase 4 integration gates pass and classification v0.1.0 is locked.
PR #7 contains exactly four coherent section commits, and no Phase 5 work has
begun.

## Phase 4 delivery status

- Complete in PR #7; quality budgets, acceptance traceability, executable
  evidence, and independent BH-00 acceptance remain assigned to later phases
  and milestones.

## Connections

- [Phase 4 plan](phase-04-disposition-capability-fallback-and-portability-classification.md)
- [BH-00 plan](README.md)

## Sources

- [Locked Phase 3 source catalog](../../../assets/component-catalog/blazex-component-catalog-v0.1.0.json)
- [MudBlazor-inspired component system](../../../20-notes/mudblazor-inspired-component-system-for-blazex.md)
