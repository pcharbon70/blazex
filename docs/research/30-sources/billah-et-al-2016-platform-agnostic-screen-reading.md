---
title: "A Platform Agnostic Remote Desktop System for Screen Reading"
kind: source
created: "2026-09-03"
authors:
  - "Syed Masum Billah"
  - "Vikas Ashok"
  - "Donald E. Porter"
  - "I. V. Ramakrishnan"
published: 2016
citation_key: "billah-et-al-2016-sinter"
container: "Proceedings of the 18th International ACM SIGACCESS Conference on Computers and Accessibility (ASSETS '16)"
edition: null
isbn: null
doi: "10.1145/2982142.2982151"
url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC5536099/"
accessed: "2026-09-03"
tags:
  - accessibility
  - cross-platform
  - research-paper
  - screen-readers
  - semantic-ir
aliases:
  - "Sinter accessibility IR paper"
---

# A Platform Agnostic Remote Desktop System for Screen Reading

## Reference

Syed Masum Billah, Vikas Ashok, Donald E. Porter, and I. V. Ramakrishnan. “A
Platform Agnostic Remote Desktop System for Screen Reading.” *ASSETS '16*,
2016, 283–284. [doi:10.1145/2982142.2982151](https://doi.org/10.1145/2982142.2982151).
[Open full text](https://pmc.ncbi.nlm.nih.gov/articles/PMC5536099/).

## Research question or contribution

Can semantic accessibility information be translated between different OS
accessibility APIs so a screen reader on one platform can operate a remote UI
from another?

## Method

The Sinter demonstration extracts platform accessibility information,
translates it through a generic representation, and presents it through
native widgets/semantics on another platform instead of transmitting pixels
alone.

## Findings

- Framebuffer pixels lose the text, hierarchy, roles, and relationships that
  screen readers require.
- Windows, Apple, and GNOME accessibility APIs differ enough to prevent a
  trivial direct bridge.
- A platform-neutral semantic representation can mediate those APIs and
  support heterogeneous client and remote OS combinations.

## Relevance

Sinter provides direct prior evidence for BlazeX's semantic-tree approach: a
portable IR can preserve meaning while platform adapters materialize the
local accessibility contract. It also confirms that the scene bitmap cannot
be the accessibility model.

## Limits

This is a short demonstration paper, not a broad production evaluation of
modern UIA, NSAccessibility, AT-SPI, AccessKit, or complex editable controls.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)

