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

Status: experimental BH-01 Phase 9 feasibility profile. Active Linux Chrome
and Firefox measurements support a conditional framework-development proceed;
payload, Firefox timer, and representative-rerun reproducibility findings
remain open. All browsers remain unsupported, mobile viability is undecided,
and external qualification is deferred to BH-22. It provides a
manifest-driven browser loader, isolated Popcorn/AtomVM frame, bounded
Elixir/browser bridge, lifecycle and prerequisite checks, deterministic static
profile build, a replaceable fixture-only DOM adapter, and a Phoenix/Bandit
asset endpoint. Run
`assets/phase4/build_profile.py --output priv/static/bh01` before starting the
endpoint. The DOM operation protocol and local behavior are test fixtures, not
a component model, production renderer, deployment support claim, or stable
API.

The Phase 6 profile adds one disposable authenticated counter command. The
browser runtime emits only a typed intent; the profile owns same-origin and
CSRF transport checks, while `blazex_phoenix` owns current session identity,
authorization, state/version checks, idempotency, the effect, and redacted
audit. Test identity and failure controls are loopback-only and active only in
the test environment.

The current fixture additionally records bounded timer/message state, bridge
and lifecycle metrics, DOM ownership counts, the fixed Wasm memory-page
observation, next-paint timings, and accessible names/roles/relationships.
These are preliminary observations only: the parent frame cannot yet observe
the runtime worker count, focus visibility is not styled, and no performance or
accessibility budget is claimed in BH-01 Phase 5.

The Phase 8 fallback surface retains a semantic status and description, exposes
a user-controlled capability recheck, records a bounded public diagnostic code
and correlation identity, and never partially activates the runtime. Automated
keyboard, focus, field, reduced-motion, and forced-color observations do not
replace required physical-device or assistive-technology review.

The generated profile is served at `/bh01/`. `PHX_SERVER=true` enables the
endpoint, and `PORT` selects its localhost port (default 4101). The endpoint
applies the cross-origin isolation and content-security policies required by
the pinned threaded Wasm runtime. `deployment-contract.json` records the exact
feasibility behavior and known security debt.

BH-03 Phase 2 publishes `priv/static/bh01/bh03-runtime-manifest.json` as the
strict experimental profile manifest. It declares exact compatibility,
prerequisite, and artifact metadata while leaving artifact acquisition and
runtime startup to later authorized work. The asset plug serves this manifest
with `no-store`; the declared immutable artifacts remain historical BH-01
outputs until Phase 3 decides how acquisition is implemented.

BH-03 Phase 6 adds a separate generated profile at `/bh03/`. It composes the
strict manifest gate, verified artifact acquisition, isolated AtomVM/Elixir
startup, shared runtime registry, and two independent root lifecycles. Build
the disposable AVM first, then run
`assets/phase6/build_profile.py --output priv/static/bh03`. The profile is an
active Linux Chrome/Firefox development fixture only: its root presentation is
profile-owned diagnostic HTML, not the BH-04 DOM interaction transport, and it
makes no support or stable-API claim. The historical `/bh01/` profile remains
separate and unchanged.

## BH-05 Phase 1 activation

Governance only: existing experimental behavior is preserved, with no new
BH-05 callbacks, facade, process or support claim. Package ownership and API
migration decisions are recorded in `docs/research/assets/bh-05-baseline`.
Runtime/host profiles consume neutral contracts; LiveView and LocalLiveView
integration remain explicitly deferred.
