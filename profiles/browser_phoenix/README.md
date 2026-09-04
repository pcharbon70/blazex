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

Status: experimental BH-01 Phase 4 feasibility profile. It now provides a
manifest-driven browser loader, isolated Popcorn/AtomVM frame, bounded
Elixir/browser bridge, lifecycle and prerequisite checks, deterministic static
profile build, and a Phoenix/Bandit asset endpoint. Run
`assets/phase4/build_profile.py --output priv/static/bh01` before starting the
endpoint. This is not a component renderer, production deployment, support
claim, or stable API.

The generated profile is served at `/bh01/`. `PHX_SERVER=true` enables the
endpoint, and `PORT` selects its localhost port (default 4101). The endpoint
applies the cross-origin isolation and content-security policies required by
the pinned threaded Wasm runtime. `deployment-contract.json` records the exact
feasibility behavior and known security debt.
