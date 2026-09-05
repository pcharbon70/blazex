# Headless Profile

This executable profile composes BlazeX core, effects and capability contracts,
the semantic UI tree, renderer contracts, the headless renderer, and test
support without a browser or server framework.

It will support deterministic conformance runs, component snapshots, build-time
inspection, and CI environments where no visual host is available.

Status: experimental BH-02 Phase 1 Mix skeleton. It composes only the approved
host-neutral boundaries; no component or renderer behavior is implemented and
no profile support is claimed.
