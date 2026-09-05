# Headless Profile

This executable profile composes BlazeX core, effects and capability contracts,
the semantic UI tree, renderer contracts, the headless renderer, and test
support without a browser or server framework.

It will support deterministic conformance runs, component snapshots, build-time
inspection, and CI environments where no visual host is available.

Status: experimental BH-02 Phase 2 composition. It runs the semantic-kernel
mount, update, keyed reorder, and replacement contract across the activated
package graph. No renderer behavior or profile support is claimed.
