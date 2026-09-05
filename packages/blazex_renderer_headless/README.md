# BlazeX Headless Renderer

Provides a deterministic renderer for semantic-tree inspection, conformance
testing, golden traces, and environments without a visual surface. It will be
the reference oracle for component and renderer-contract behavior.

It should depend only on the core, UI-tree, and renderer contracts, keeping it
usable outside browser and desktop profiles.

Status: experimental BH-02 Phase 5 deterministic oracle. Canonical semantic
snapshots, SHA-256 digests, and ordered mount/update/replace/dispose traces are
implemented without geometry, host access, drawing, or a support claim.
