# Native Renderer Spike

This bounded BH-02 experiment must create actual toolkit controls for the same
small semantic interaction set exercised by the headless and DOM renderers. It
exists to expose browser, HTML, CSS, JavaScript, and event-model leakage before
the public component contracts stabilize.

The selected toolkit is disposable and does not choose the production desktop
backend. Shared traces and assertions belong in `integration/conformance`;
portable contracts and fixes belong in host-neutral packages. No production
native-renderer support may be claimed from this experiment alone.

Status: directory scaffold only; activate during BH-02 and retire or replace it
after its evidence has been captured.

