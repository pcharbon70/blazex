---
title: "Fast GPU bounding boxes on tree-structured scenes"
kind: source
created: "2026-09-03"
authors:
  - "Raph Levien"
published: 2022
citation_key: "levien-2022-gpu-bounding-boxes"
container: "arXiv"
edition: null
isbn: null
doi: "10.48550/arXiv.2205.11659"
url: "https://arxiv.org/abs/2205.11659"
accessed: "2026-09-03"
tags:
  - drawing
  - gpu
  - rendering
  - research-paper
  - scene-graph
aliases:
  - "Vello GPU scene research"
---

# Fast GPU bounding boxes on tree-structured scenes

## Reference

Raph Levien. “Fast GPU bounding boxes on tree-structured scenes.” arXiv,
2022. [doi:10.48550/arXiv.2205.11659](https://doi.org/10.48550/arXiv.2205.11659).

## Research question or contribution

How can bounding boxes for tree-structured clip and blend scenes be computed
efficiently in parallel on real GPU hardware?

## Method

The paper derives a parallel algorithm around parentheses matching, maps it
to GPU thread/workgroup/dispatch levels through portable compute shaders, and
compares performance with a sequential CPU implementation.

## Findings

- Tree-structured clips and blends require intersection and union of bounds,
  making the retained scene structure relevant to culling and binning.
- The proposed portable compute implementation achieved a dramatic speedup
  over the sequential CPU version in the reported evaluation and reached a
  meaningful fraction of theoretical GPU throughput.
- The work was motivated by 2D rendering and informed the Vello renderer
  direction.

## Relevance

The paper supports a retained, tree-structured, GPU-capable BlazeX display
list rather than immediate drawing calls embedded in components. It justifies
keeping Vello/wgpu as a research path while the first implementation uses a
mature backend.

## Limits

This is a preprint focused on one rendering algorithm. It does not establish
Vello's production readiness or solve paths, text, windowing, accessibility,
input, or desktop packaging.

## Derived work

- [Cross-platform native host and renderer architecture](../20-notes/cross-platform-native-host-and-renderer-architecture.md)
- [Native renderer architecture map](../10-maps/host-neutral-and-native-renderer-architecture.md)
