# Profiles

Profiles are executable reference compositions of reusable BlazeX packages.
They prove that a particular runtime, host, renderer, and integration adapter
work together as a supported product.

Unlike libraries under `packages/`, an activated profile may own application
configuration, a lockfile, assets, release settings, deployment examples, and
end-to-end tests. Profiles must not become the source of shared framework
contracts; reusable behavior moves into packages.

The initial profiles are:

- `browser_phoenix` — canonical first browser/Phoenix reference application.
- `browser_plug` — smaller browser host proving Phoenix and LiveView independence.
- `headless` — deterministic nonvisual composition for conformance and tooling.

BH-01 Phase 1 activates only `browser_phoenix` as a dependency-free
experimental skeleton. `browser_plug` and `headless` remain README-only
boundaries so their exclusions stay independently inspectable.
