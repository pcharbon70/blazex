---
title: "Accessibility of UI Frameworks and Libraries for Programmers with Visual Impairments"
kind: source
created: "2026-09-03"
authors:
  - "Maulishree Pandey"
  - "Sharvari Bondre"
  - "Sile O'Modhrain"
  - "Steve Oney"
published: 2022
citation_key: "pandey-et-al-2022-ui-framework-accessibility"
container: "2022 IEEE Symposium on Visual Languages and Human-Centric Computing (VL/HCC)"
edition: null
isbn: null
doi: "10.1109/VL/HCC53370.2022.9833098"
url: "https://pandeymauli.github.io/research/documents/pandey_vlhcc_fullpaper_2022.pdf"
accessed: "2026-09-03"
tags:
  - accessibility
  - research-paper
  - screen-readers
  - toolkit
aliases:
  - "Pandey UI framework accessibility study"
---

# Accessibility of UI Frameworks and Libraries for Programmers with Visual Impairments

## Reference

Maulishree Pandey, Sharvari Bondre, Sile O'Modhrain, and Steve Oney.
“Accessibility of UI Frameworks and Libraries for Programmers with Visual
Impairments.” *IEEE VL/HCC 2022*, 1–10.
[doi:10.1109/VL/HCC53370.2022.9833098](https://doi.org/10.1109/VL/HCC53370.2022.9833098).
[Author PDF](https://pandeymauli.github.io/research/documents/pandey_vlhcc_fullpaper_2022.pdf).

## Research question or contribution

How do UI frameworks and libraries shape the work, testing, and collaboration
of programmers who use screen readers or other nonvisual interaction?

## Method

The authors used a mixed-methods design: analysis of 96 randomly sampled
archived Program-L mailing-list threads and interviews with 18 programmers
with visual impairments.

## Findings

- Framework choice affected both application accessibility and the
  accessibility of development, debugging, and testing workflows.
- Participants encountered differing control behavior and accessibility
  across operating systems and frameworks.
- Semantic order, keyboard behavior, accessible components, documentation,
  and practical testing support materially influenced whether a framework
  could be used effectively.

## Relevance

BlazeX must test the actual OS, toolkit, and screen-reader combinations and
make its semantic/accessibility traces inspectable. A theoretical mapping or
visual screenshot is insufficient evidence.

## Limits

The study focuses on developer experience rather than measuring the candidate
BlazeX stacks. Findings are qualitative and reflect the versions used by
participants at the time.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)

