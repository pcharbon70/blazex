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
  stream, beginning with the phased BH-00 product-boundary, catalog, and
  acceptance-contract plan.

### Documents

- None yet.

## Maintaining this index

Assign the next unused two-digit prefix when a new planning stream is added.
Link every stream through its README, keep its status current, and move
obsolete plans to `90-archive` without reusing their sequence numbers. Every
stream must identify the monorepo projects it activates without making an
executable profile the owner of reusable framework contracts.
