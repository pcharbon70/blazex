---
title: "BH-06 Secret-Exclusion Contract"
kind: note
created: "2026-09-12"
maturity: developing
tags: [bh-06, build, client-safety, contract, secrets, security]
aliases: []
---

# BH-06 Secret-Exclusion Contract

Back to the [Phase 5 plan](phase-05-secret-bearing-input-exclusion.md).

## Inputs and ownership

The build receives logical input labels and bytes for every file that may enter
the application AVM plus the browser document and host source. Labels are stable,
path-free identities; the report stores their size and SHA-256, never a source
path. Public configuration is an explicit JSON-safe map. Environment variables,
application environment, and server configuration are not implicit inputs.

Security owners maintain fixed UTF-8 literal signatures and normalized config-key
fragments in a versioned policy. Arbitrary regular expressions, entropy guesses,
network services, and inferred allowlists are outside this deterministic gate.

## Detection and redaction

Every literal occurrence is reported by rule ID, logical subject, and byte offset.
Config keys are compared case-insensitively after ASCII normalization and report
the key path plus rule ID. Reports and exception messages never include matched
bytes or configuration values. Input digests permit exact accounting without
turning secret material into evidence.

Policies, input counts, aggregate bytes, individual bytes, nesting, string sizes,
and finding counts are bounded. Exceeding a bound rejects explicitly rather than
truncating a clean-looking report. Duplicate labels, rule IDs, literals, or key
fragments reject. Equivalent unordered input produces identical reports.

## Enforcement and boundary

Client safety runs first, compatibility second, secret audit third, and AVM
assembly only after all pass. The manifest binds the passing audit as a
content-addressed artifact. This gate reduces accidental credential packaging;
it is not proof that arbitrary bytes contain no undisclosed secret and is not a
replacement for server authorization, incident response, or production scanning.

LiveView and LocalLiveView are **[DEFERRED]** and are not scan inputs or gates.
