# Browser + Phoenix Profile

This is the canonical first executable BlazeX profile. It will assemble the core
and component packages, Popcorn/AtomVM runtime, browser host, DOM renderer,
optional LiveView DOM adapter, Phoenix server adapter, and JavaScript runtime
into a reference application.

The profile will eventually provide the component gallery, integration test
target, development workflow, production build example, and deployment proof.
It is the leading supported composition, not the universal container for BlazeX.
Shared browser, renderer, and component behavior must remain in reusable
packages rather than this profile.

Status: experimental BH-01 dependency-free Mix skeleton. Composition,
endpoint, assets, environment configuration, release, and teardown locations
exist, but Phoenix and every candidate dependency remain uninstalled and all
runtime/browser behavior remains unexecuted. No profile module is a stable API.
