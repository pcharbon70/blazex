---
title: "Development Environment and Deferred Qualification Policy"
kind: note
created: "2026-09-04"
maturity: stable
tags:
  - browser
  - deferred-qualification
  - implementation-planning
  - linux
aliases:
  - "BlazeX development matrix policy"
  - "Deferred browser qualification policy"
---

# Development Environment and Deferred Qualification Policy

## Decision

BlazeX framework development must be able to proceed using the environments
actually available to the project. The current active development matrix is
Linux with Chrome and Firefox. Missing access to macOS, Windows, Android,
iOS/iPadOS, Safari, device laboratories, or unavailable manual assistive-
technology pairings is a deferred qualification obligation, not a blocker for
feasibility, architecture, framework, component, or integration development.

This policy separates development confidence from product support. A deferred
row is not passed, compatible, supported, waived, or silently omitted. It must
remain visible with its required environment, evidence, owner, and the
milestone at which it becomes mandatory.

## Active development matrix

The following evidence can gate current development:

- reproducible builds and tests on the controlled Linux development host;
- automated Chrome execution against pinned artifacts;
- Firefox execution on Linux through automation where the installed browser
  and driver permit it, otherwise a bounded manual smoke result with the
  automation limitation recorded;
- deterministic headless, unit, integration, security, resource, and contract
  checks that do not require an unavailable external platform;
- automated accessibility semantics, keyboard/focus behavior, reduced-motion,
  forced-color, and fallback checks available in the local browsers; and
- actual product, architecture, security, data-integrity, or reproducibility
  failures observed in this active matrix.

A failure in an available, applicable development environment remains a real
failure and can block dependent work. This policy does not convert failing
evidence into a deferral.

## Deferred qualification matrix

Until the required infrastructure is available, the following are explicitly
deferred:

- Windows and macOS desktop execution;
- Safari and WebKit product qualification;
- Android Chrome on phones and tablets;
- Safari on iPhone and iPad;
- current/previous browser and operating-system support-window matrices;
- physical-device touch, rotation, virtual-keyboard, background/resume,
  power, thermal, and memory-pressure observations;
- screen-reader/browser pairings and other manual assistive-technology reviews
  that cannot be performed with the available environment;
- cross-browser and cross-device performance comparison; and
- final browser-support, accessibility-conformance, mobile-compatibility, and
  release claims derived from those environments.

These obligations become release-gating no later than BH-22, Production Quality
and Release-Candidate Gates. A later milestone may pull a deferred item forward
when infrastructure becomes available, but an unavailable item cannot prevent
earlier framework learning or invalidate otherwise sound local evidence.

## Planning and evidence rules

1. Plans must label unavailable external-platform work `[DEFERRED]` and name
   the milestone or condition that reactivates it.
2. Deferred items are excluded from development-phase completion calculations
   but remain included in qualification and release ledgers.
3. Development reports aggregate only active, applicable environments. They
   list deferred rows separately and never calculate them as passes.
4. Browser or device emulation may provide exploratory evidence but cannot
   close a deferred product-browser or physical-device obligation.
5. Historical evidence and decisions remain immutable. A planning amendment
   may change the downstream effect of a prior blocker without rewriting what
   was observed.
6. No development result promotes a browser to supported status. Support is a
   separately reviewed product decision backed by the then-required matrix.
7. Security, authority, artifact integrity, deterministic behavior, resource
   cleanup, and host-neutral architecture remain active gates wherever they can
   be evaluated locally.

## Effect on BH-01

The BH-01 Phase 8 record remains a truthful historical blocked matrix result:
four required external rows and manual accessibility evidence were unavailable.
This policy changes the planning consequence of that result. The unavailable
rows are carried as deferred qualification work, the successful local evidence
is retained, and Phase 9 becomes eligible for explicit authorization.

Phase 9 may implement measurement infrastructure and collect Linux Chrome and
Firefox evidence. Its unavailable mobile and cross-platform measurements must
be published as deferred, not used to block continuation or represented as
product viability evidence. BH-01 may proceed to its final feasibility decision
using the active development matrix while carrying these exact limitations into
BH-02 and the BH-22 release gate.

## Amendment binding

This document is the explicit planning amendment for the BH-00 roadmap source
binding `BX-BH00-SOURCE-ROADMAP`.

- Historical accepted roadmap SHA-256:
  `5c09ad3dd07dc0adadc48ba67e8cdd40c823a9e73d4405808d892315f6894b9a`.
- Amended roadmap SHA-256:
  `a23f08ce1bf6021a6d1e9d1dd5998f85e37a7604d23bc032e0618f1c5facddb0`.
- Amendment scope: development sequencing and the downstream effect of
  unavailable external browser/device/manual evidence only.
- Unchanged gates: architecture, host neutrality, trust, security, artifact
  integrity, reproducibility, active-environment behavior, and explicit
  authorization boundaries.
- Reactivation milestone: BH-22 production quality and release-candidate gates.

The original roadmap blob and all evidence derived from it remain valid
historical inputs. Any further roadmap change requires a new explicit binding;
this amendment is not an open-ended stale-source exception.

## Connections

- [Implementation planning index](README.md)
- [Browser host planning stream](01-browser-host/README.md)
- [BH-01 plan](01-browser-host/bh-01-reproducible-browser-feasibility-baseline/README.md)
- [Browser host implementation milestones](../20-notes/browser-host-implementation-milestones.md)
