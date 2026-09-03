# JavaScript

This directory contains browser-side JavaScript packages that support, but do
not define, BlazeX component semantics. JavaScript should remain a narrow host
bridge for facilities that WebAssembly cannot access directly.

BH-01 Phase 1 initializes `blazex_runtime` as a private, dependency-free
experimental package with a pinned npm declaration and boundary test. It does
not yet load WebAssembly or implement browser facilities.
