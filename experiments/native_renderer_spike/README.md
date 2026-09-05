# Native Renderer Spike

This bounded BH-02 experiment must create direct Win32, AppKit, and GTK
controls for the same small semantic interaction set exercised by the
headless and DOM renderers. It exists to expose browser, HTML, CSS, JavaScript,
platform-object, and event-model leakage before the public component contracts
stabilize. Qt and wxWidgets are excluded directly and transitively.

Each platform adapter is disposable and does not choose the production desktop
backend. Shared traces and assertions belong in `integration/conformance`;
portable contracts and fixes belong in host-neutral packages. No production
native-renderer support may be claimed from this experiment alone.

Status: BH-02 Phase 7 has activated an experimental Mix backend that lowers
the existing semantic slice to deterministic, platform-neutral native-control
batches and the strict BXN1 line protocol. No platform object crosses into
that backend. Direct adapter implementation and GTK execution follow in
Section 7.3; Windows and macOS execution remain `[DEFERRED]` until governed
environments are available.
