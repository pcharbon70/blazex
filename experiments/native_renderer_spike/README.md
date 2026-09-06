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

Status: BH-02 Phase 7 Section 7.3 now materializes the frozen BXN1 fixture
through direct platform adapter sources. The Linux adapter compiled against
the installed GTK 4 runtime ABI and passed under Xvfb with actual GTK controls,
events, focus, selection, role observations, stale rejection, and idempotent
disposal. Windows and macOS sources consume the same batch but compilation and
execution remain `[DEFERRED]` until governed environments are available.

Reproduce the active platform proof with:

```sh
mix run scripts/write_fixture.exs fixtures/representative-v0.1.0.bxn1 fixtures/stale-update-v0.1.0.bxn1
python3 scripts/run_gtk4.py --output gtk4-result-v0.1.0.json
mix test
```

The passed local result remains experimental and unsupported. In particular,
the GTK role observations identify adapter work still needed for exact dialog,
group, list-item, and status semantics; they are not platform accessibility
qualification.
