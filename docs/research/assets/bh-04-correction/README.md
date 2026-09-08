---
title: "BH-04 corrective acceptance captures"
kind: map
created: "2026-09-08"
tags: [bh-04, acceptance, benchmarks]
aliases: []
---

# BH-04 corrective acceptance captures

## Purpose

Retain local corrective measurements, including unsuccessful attempts. These
are development evidence, not acceptance or release-support claims.

## What belongs here

Complete generated native traces and transaction observations from fresh,
headless test browsers. Traces are not anonymous: they include process IDs,
browser/environment metadata, localhost addresses, local executable/library
paths identifying `/home/ducky`, and standard Firefox service preference URLs.
Independent scanning found no common credential patterns or user-content URLs;
that is not an exhaustive secrecy guarantee.

## Index

- [First Chrome native trace](first-chrome-native.json.gz)
- [First Firefox native profile](first-firefox-native.json.gz)
- [First measurement report](first-presentation.json) — original failed parser
  attempt; retained negative raw evidence, not exact first-harness replay.
- [Verified Chrome native trace](chrome-native.json.gz)
- [Verified Firefox native profile](firefox-native.json.gz)
- [Verified measurement report](presentation.json) — 100 measured samples plus
  setup per browser, draft regressions and injected-cleanup failure retention.
- [Stale and queue observations](stale-queue.json.gz) — before/after state,
  seeded delayed generations and acknowledgement identity evidence.

## Maintaining this index

Add every direct artifact. Never overwrite failed attempts or historical
Phase 10 evidence. See the [corrective plan](../../60-planning/01-browser-host/bh-04-dom-renderer-and-interaction-transport/acceptance-correction-plan.md).
