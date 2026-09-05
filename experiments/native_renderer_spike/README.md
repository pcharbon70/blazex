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

Status: BH-02 Phase 1 activates only the governed experiment boundary. No
control is implemented. Windows and macOS execution are `[DEFERRED]` until
governed environments are available; Linux GTK work remains unexecuted and
unauthorized until Phase 7.
