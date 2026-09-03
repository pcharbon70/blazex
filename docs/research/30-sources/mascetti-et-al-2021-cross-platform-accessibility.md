---
title: "Developing Accessible Mobile Applications with Cross-Platform Development Frameworks"
kind: source
created: "2026-09-03"
authors:
  - "Sergio Mascetti"
  - "Mattia Ducci"
  - "Niccolò Cantù"
  - "Paolo Pecis"
  - "Dragan Ahmetovic"
published: 2021
citation_key: "mascetti-et-al-2021-accessible-cross-platform"
container: "Proceedings of the 23rd International ACM SIGACCESS Conference on Computers and Accessibility (ASSETS '21)"
edition: null
isbn: "978-1-4503-8306-6"
doi: "10.1145/3441852.3476469"
url: "https://arxiv.org/abs/2005.06875"
accessed: "2026-09-03"
tags:
  - accessibility
  - cross-platform
  - research-paper
  - screen-readers
aliases:
  - "Mascetti cross-platform accessibility study"
---

# Developing Accessible Mobile Applications with Cross-Platform Development Frameworks

## Reference

Sergio Mascetti, Mattia Ducci, Niccolò Cantù, Paolo Pecis, and Dragan
Ahmetovic. “Developing Accessible Mobile Applications with Cross-Platform
Development Frameworks.” *ASSETS '21*, 2021, 1–5.
[doi:10.1145/3441852.3476469](https://doi.org/10.1145/3441852.3476469).
[Preprint](https://arxiv.org/abs/2005.06875).

## Research question or contribution

How completely do cross-platform frameworks expose the accessibility
functions available from native platform screen-reader APIs?

## Method

The authors systematically compared native iOS and Android screen-reader APIs
with the functions exposed through Xamarin and React Native, then implemented
representative missing functions through native platform code.

## Findings

- Native platforms shared many accessibility concepts, but the examined
  cross-platform frameworks exposed only subsets.
- Even some basic functions were missing, requiring developers to understand
  and invoke native APIs.
- Cross-platform abstraction therefore did not eliminate platform-specific
  accessibility work and could partially negate the promised portability.

## Relevance

The platforms are mobile rather than desktop, but the result directly warns
against treating AccessKit, Qt, wxWidgets, or a BlazeX role vocabulary as
automatically complete. BlazeX needs platform escapes and OS-by-screen-reader
acceptance tests.

## Limits

The evaluated versions and mobile APIs differ from current desktop UIA,
NSAccessibility, and AT-SPI. The paper does not evaluate the candidate stacks
in this research or prove current framework deficiencies.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Cross-renderer portability inquiry](../40-inquiries/can-one-blazex-component-model-target-dom-and-native-controls.md)

