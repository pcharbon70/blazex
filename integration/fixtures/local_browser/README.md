# BH-01 Local Browser Fixture

This directory owns the disposable, non-public behavior and evidence contracts
for BH-01 Phase 5. It defines values exchanged by the Elixir fixture, browser
host, and standalone DOM adapter. It does not define a BlazeX component,
semantic tree, renderer, capability, effect, or forms API.

All records use opaque fixture identities and JSON-compatible values. DOM and
JavaScript objects, selectors, arbitrary tags, attributes, styles, scripts,
URLs, credentials, and server-authority data are prohibited. Production
packages must not import this directory. The Phase 5 profile may package its
disposable Elixir fixture as an AVM, but shared code may only depend on the
closed operation protocol implemented under `packages/blazex_renderer_dom`.

Run `python3 verify_contracts.py` from this directory to validate the schemas,
catalog coverage, normalization policy, and repository leakage guards.
