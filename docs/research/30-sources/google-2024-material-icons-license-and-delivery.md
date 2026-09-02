---
title: "Google Material Icons licensing and delivery"
kind: source
created: "2026-09-02"
authors:
  - "Google Fonts team"
published: 2024
citation_key: "google-2024-material-icons-license-delivery"
container: "Google Fonts documentation"
edition: null
isbn: null
doi: null
url: "https://developers.google.com/fonts/docs/material_icons"
accessed: "2026-09-02"
tags:
  - assets
  - icons
  - licensing
  - material-design
aliases:
  - "Material Icons source note"
---

# Google Material Icons licensing and delivery

## Reference

Google Fonts team. [*Material Icons Guide*](https://developers.google.com/fonts/docs/material_icons),
last updated 2024-07-23. Accessed 2026-09-02. The corresponding
[Google icon repository license](https://github.com/google/material-design-icons/blob/master/LICENSE)
is Apache License 2.0.

## Research question or contribution

Can BlazeX reuse the Material icon vocabulary represented in MudBlazor, and
what packaging/licensing boundary should apply?

## Findings

- Google publishes Material Icons for use in web and other products under the
  Apache License 2.0.
- The icons are available as individual SVG/PNG assets, an icon font, and a
  source repository. Material Symbols provide a newer variable-font family.
- MudBlazor's inspected source contains five generated Material icon families
  plus custom icon groups. Including those generated C# constants wholesale
  would be especially costly in a browser AtomVM bundle.

## Relevance

BlazeX should make icons an asset/build concern rather than thousands of BEAM
string constants. A build manifest can retain only referenced SVG symbols,
use a separately cached sprite, or allow an application-selected icon font.
The Material icon license and notices should be tracked independently from
MudBlazor's MIT license, and custom/brand icon provenance requires its own
audit.

## Limits

This note is an engineering provenance summary, not legal advice. It does not
audit every custom icon in MudBlazor, trademarks, or the licensing of fonts
and assets supplied by an application's own design system.

## Derived work

- [MudBlazor-inspired component system for BlazeX](../20-notes/mudblazor-inspired-component-system-for-blazex.md)
