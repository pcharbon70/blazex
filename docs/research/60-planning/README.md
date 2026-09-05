---
title: "Implementation Planning"
kind: map
created: "2026-09-02"
tags:
  - archive-navigation
  - directory-index
  - implementation-planning
aliases:
  - "Planning index"
---

# Implementation Planning (`60-planning`)

## Purpose

This directory turns BlazeX research conclusions into staged, testable
implementation roadmaps with explicit dependencies, completion gates, and
evidence requirements.

## What belongs here

- Numbered planning streams in the order they are introduced.
- Planning-stream indexes that define scope, status, dependencies, and future
  phase organization.
- Indexed milestone-plan subdirectories when one planning stream spans multiple
  roadmap milestones.
- Future phase documents containing implementation tasks and completion
  evidence.
- The active development-environment policy and explicit deferred qualification
  obligations for environments the project cannot currently access.
- Explicit package, profile, integration-suite, and experiment ownership for
  every phase, including forbidden dependency directions.
- Links back to the research notes and inquiries whose claims implementation
  must test.

Planning-stream directories use a permanent, zero-padded sequence number and
a descriptive kebab-case name. Existing numbers are never reused or
renumbered.

## Index

### Subdirectories

- [01 — Browser host](01-browser-host/README.md) — active first implementation
  stream: BH-00 and BH-01 are complete, BH-02 Phase 1 has activated and
  validated the host-neutral foundation, and Phase 2 is eligible but not
  authorized.

### Documents

- [Development environment and deferred qualification policy](development-environment-and-deferred-qualification-policy.md)
  — makes Linux Chrome and Firefox the active development matrix while keeping
  unavailable platforms, browsers, devices, and manual assistive-technology
  evidence visible and deferred until production qualification.

## Maintaining this index

Assign the next unused two-digit prefix when a new planning stream is added.
Link every stream through its README, keep its status current, and move
obsolete plans to `90-archive` without reusing their sequence numbers. Every
stream must identify the monorepo projects it activates without making an
executable profile the owner of reusable framework contracts. Do not make an
unavailable operating system, browser, device, service, or manual test a
development blocker: mark it `[DEFERRED]`, retain its eventual qualification
owner, and reactivate it at the declared product-quality milestone.
