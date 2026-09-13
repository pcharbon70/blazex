# Browser + Phoenix Profile

This is the canonical first executable BlazeX profile. It will assemble the core
and component packages, Popcorn/AtomVM runtime, browser host, DOM renderer,
Phoenix server adapter, and JavaScript runtime
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

## BH-07 Phase 1 activation

The `/bh07/` route serves only public artifacts from an accepted BH-06 build
manifest and matching entrypoint attestation. The profile verifies the entire
inventory before delivery, preserves declared content types and cache policy,
and provides strong SHA-256 ETags with GET/HEAD/conditional-request parity.
Private evidence, undeclared paths, changed files, and invalid attestations fail
closed. Configure `:bh07_static_root` and `:bh07_attestation_path` to the accepted
build output and attestation. This phase does not add session bootstrap,
commands, pushes, reconnect, deployment qualification, or support claims.
LiveView and LocalLiveView are explicitly deferred and are absent from the
active profile dependency graph.

## BH-07 Phase 2 activation

`/bh07/bootstrap.json` publishes a deterministic public-only envelope bound to
the accepted manifest and entrypoint attestation. Optional public values come
only from `:bh07_public_bootstrap` and are recursively constrained by key,
type, depth, width, node, string, integer, and final-byte limits. Secret- and
authority-like keys fail closed. The response is untrusted browser input and
cannot grant a session, role, permission, command, or server mutation.

The route supports GET, HEAD, and conditional ETags with `no-store`; other
methods return 405. Sessions, authentication projection, CSRF, commands,
pushes, reconnect, production support, LiveView, and LocalLiveView remain
deferred.

## BH-07 Phase 3 activation

`/bh07/session` exposes only an anonymous or minimal authenticated projection
backed by a bounded server-owned opaque-session registry. The encrypted and
signed host cookie is HTTP-only and `SameSite=Strict`; rotation and replacement
renew the cookie, expiry and restart invalidate server state, and logout is
same-origin and idempotent. Test-only issuance/reset routes require loopback,
same-origin, test mode, and the explicit `x-bh07-test-control: enabled` header.

The projection never includes the opaque identifier, credentials, roles,
permissions, allowed actions, CSRF material, or mutation authority. Credentials,
a login provider, CSRF, commands, effects, pushes, reconnect, production
support, LiveView, and LocalLiveView remain deferred.

## BH-07 Phase 4 activation

Authenticated BH-07 sessions now carry a 32-byte anti-CSRF proof inside the
encrypted host cookie and expose it only through their no-store authentication
projection. The server registry retains only its digest, verifies it in
constant time, and rotates it atomically at `POST /bh07/csrf/rotate` without
extending the session. Authenticated logout and rotation require one canonical
same-origin header and the exact `x-blazex-csrf` proof.

Credentials, production identity, roles, permissions, commands, effects,
pushes, reconnect, production deployment/support, LiveView, and LocalLiveView
remain deferred.

## BH-07 Phase 5 activation

`POST /bh07/commands/admit` accepts only one bounded, exact JSON command intent
behind the Phase 4 origin, encrypted-session, and CSRF checks. The reusable
authority repeats authentication, resolves a static declaration, validates its
closed payload schema, applies a private subject grant, and returns a bounded
idempotent admission receipt. Receipts explicitly report `executed: false`.

No handler, arbitrary module/function resolution, application resource mutation,
or effect is available. Credentials, generalized roles/permissions, pushes,
reconnect, production deployment/support, LiveView, and LocalLiveView remain
deferred.

## BH-07 Phase 6 activation

`POST /bh07/commands/execute` performs the one closed
`counter.increment` development operation after repeating current origin,
encrypted-session, CSRF, schema, and private-grant checks. The package owns the
serialized in-memory resource revision, exact success/stale replay records, and
bounded redacted audit. The browser supplies only the Phase 5 typed intent.

This is not a general command handler or browser effect system. Persistence,
distributed idempotency, dynamic resolution, external resource mutation,
credentials, generalized roles/permissions, pushes/reconnect, production
deployment/support, LiveView, and LocalLiveView remain deferred.
