---
title: "BH-06 Phase 1 Completion Evidence"
kind: note
created: "2026-09-11"
maturity: developing
tags: [bh-06, browser, build, completion, evidence, wasm]
aliases: []
---

# BH-06 Phase 1 Completion Evidence

Back to the [plan](phase-01-first-continuous-browser-wasm-vertical-slice.md)
and [review](phase-01-review-and-reconciliation.md).

## Outcome

Phase 1 is complete with decision **accept**. The first BH-06 candidate
entrypoint-to-browser path is continuous: public Elixir component source is
compiled into one AVM bundle, assembled with AtomVM/Wasm and integrity metadata,
loaded from the versioned manifest, interacted with in the browser, and disposed.
This directly replaces the earlier JavaScript-only demo limitation as milestone
evidence without converting the demo gallery itself in this phase.

## Reproduction

Two absent-output builds produced byte-identical trees and manifest SHA-256
`c7ce6a4c1fdb84debfa8adeef5c867479f5cf0fd2d83338fbebe76933db06ba1`.
Two complete Chrome/Firefox runs were also byte-identical after removing no
fields: raw report SHA-256 was
`bbce545c8e86d75867e5bb59b553e889c05ea092262f1bec096a6cb95891ab2b`.
The committed normalized evidence is [browser-slice-v0.1.0.json](../../../../../integration/bh-06/browser-slice-v0.1.0.json).

Package tests pass: Build 3, Core 123, Effects 15, UI Tree 68, Renderer 8,
Headless 6, DOM 116, Host 4, Popcorn runtime 4, Phoenix 10, deferred LiveView
adapter 4, Test 7, integration conformance 93, native spike 9, and headless
profile 6, all with zero failures. JavaScript runtime 31, DOM driver 7, and
browser demo 7 tests pass. The Phase 1 validator and five mutation tests pass,
as do archive, JSON, syntax, dependency-boundary, and patch-hygiene checks.

The pinned Elixir 1.17.3 image was required for exact-version packages. The
browser Phoenix profile test could not be repeated in that clean container
because its Hex SCM archive was unavailable; the new slice does not import or
execute Phoenix, and its direct Chrome/Firefox profile passed. Pre-existing
formatter drift in unchanged DOM and Phoenix test files was not rewritten.

## Bound evidence

- Candidate build manifest SHA-256: `c7ce6a4c1fdb84debfa8adeef5c867479f5cf0fd2d83338fbebe76933db06ba1`.
- Browser evidence SHA-256: `b2dfecfbe1a09c3607892acd3e108d18084d539aab1cb9a69602547d7371e246`.
- Build pipeline SHA-256: `de4ebf41ad9a0831109ecb02f2ab5f93a7d34c54980ec56ec366c5240b015a16`.
- Public counter SHA-256: `a1ccc63bff5f6aad2ff86c136b5f745bb322b4e58777a97705cc6a2d84a26dba`.
- Browser host SHA-256: `d31450edbb54f2338b742956dfbf5bffef2963cf82f1eb556a16114b0403781b`.
- Section 1.3 revision: `da912fa16b9da3ba534d09e5ed7acfde401e1fbb`.

Further BH-06 decomposition and implementation remain separately unauthorized.
LiveView and LocalLiveView remain deferred; BH-07 and support promotion remain
unauthorized.
