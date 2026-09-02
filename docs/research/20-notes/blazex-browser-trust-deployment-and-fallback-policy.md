---
title: "BlazeX browser trust, deployment, and fallback policy"
kind: note
created: "2026-09-02"
maturity: stable
tags:
  - bh-00
  - browser
  - deployment
  - fallback
  - security
aliases:
  - "BlazeX browser trust policy"
  - "BH-00 deployment and fallback contract"
---

# BlazeX browser trust, deployment, and fallback policy

## Status and scope

This policy defines the trust boundary, deployment prerequisites, and failure
behavior for the candidate browser product. It is normative product intent but
not proof that the current Popcorn/AtomVM/Phoenix/Plug stack satisfies it. The
[machine-readable browser product
envelope](../assets/browser-product-envelope-v0.1.json) is the matrix source of
truth.

The browser, JavaScript bridge, Wasm memory, AVM/BEAM application bundle, local
state, persisted cache, local events, command payloads, capability results, and
client diagnostics are attacker-controlled from the server's perspective.
Elixir authorship, WebAssembly execution, an iframe, or a BlazeX component does
not change that rule.

## Trust domains and data boundaries

| ID | Boundary | Classification | Required handling |
| --- | --- | --- | --- |
| `TRUST-PUBLIC-BOOTSTRAP` | Public bootstrap state | Server-produced but public and untrusted after delivery | Project only public data; bind schema/build/root/session scope and expiry; size-limit; integrity-protect where it carries security-relevant context; revalidate every returned value. |
| `TRUST-SERVER-STATE` | Trusted domain, identity, authorization, and persistence state | Authoritative only while held/reloaded by trusted server application code | Never serialize implicitly; expose minimum public projection; reload records and policy inputs before mutation. |
| `TRUST-LOCAL-EVENT` | DOM/host event delivered to local component logic | Untrusted local input without server authority | Normalize, size/type-check, bind to active component generation, and use only for local transitions or typed command construction. |
| `TRUST-REMOTE-COMMAND` | Typed command crossing Phoenix/Plug | Untrusted request | Authenticate request/connection, enforce origin/CSRF, decode under limits, validate schema, reload trusted state, authorize resource/action, apply replay/idempotency policy, execute, audit, and return public result. |
| `TRUST-AUTH-PROJECTION` | Client-visible authentication/user/permission projection | Presentation hint only | Use for labels and affordances; never authorize from it; refresh or fail closed when server state changes. |
| `TRUST-CAPABILITY-GRANT` | Host capability grant/result/resource identity | Local authority scoped to one root/generation, never server authority | Grant least privilege, validate inputs/results, bind lifetime, cancel/timeout, redact diagnostics, and dispose opaque resources. |
| `TRUST-CONTENT-ASSET` | Runtime, code, script, style, font, and data assets | Executable/content supply-chain input | Deliver over authenticated transport; bind hashes/build manifest; apply CSP and correct MIME; reject version mixing; record provenance. |
| `TRUST-LOCAL-CACHE` | Browser cache/storage and persisted drafts | Attacker-modifiable, stale, and potentially sensitive | Classify fields, exclude secrets, schema/version/expiry-check, limit size, and treat restored data as new untrusted input. |
| `TRUST-DIAGNOSTIC` | Client/server logs, traces, crash reports, and support bundles | Potentially attacker-controlled and sensitive | Structured fields, escaping, size/rate limits, secret/token/PII redaction, audience controls, and correlation IDs without raw payload retention by default. |

## Bootstrap and authentication projection

A public bootstrap envelope may contain only what the initial browser root is
allowed to disclose: build/profile/mode identifiers, root identity, public
props, localization/theme hints, capability offer names, endpoint identifiers,
and a bounded session/view token where required. It never contains server
secrets, signing keys, database credentials, unrestricted bearer credentials,
private domain records, arbitrary module/function names, or server-only
configuration.

An authentication projection such as user name, role label, or a list of
visible actions improves presentation but is not authorization. Visibility and
disabled state are advisory UI. The server reloads authenticated identity,
tenant, resource, policy, and current domain state before every authoritative
command.

## Remote command contract

Every remote command has a stable name, versioned request/result/error schema,
maximum encoded size/depth/list limits, idempotency classification, required
authentication, authorization action/resource resolver, audit classification,
and redaction policy. The server processes it in this order:

1. authenticate the request or transport and establish trusted server identity;
2. enforce allowed origin, session binding, and transport-appropriate CSRF;
3. validate bootstrap/view/build scope and expiry where the command uses it;
4. decode under byte, nesting, collection, string, and time limits;
5. map the declared command name to an allowlisted handler—never a client-named
   module/function;
6. validate the versioned command schema and reject unknown fields by policy;
7. reload trusted identity, tenant, resource, and relevant domain state;
8. authorize the exact action against those trusted records;
9. apply nonce, sequence, idempotency-key, duplicate, and conflict policy;
10. execute through ordinary application/domain services and transaction rules;
11. return only the public result/error schema; and
12. emit bounded audit/telemetry with correlation identifiers and redaction.

Retries are allowed only when the command's idempotency record says how
duplicates are recognized. A network retry never implies safe mutation replay.

## Capability and origin policy

- Capability providers grant named operations to a component root/generation,
  not ambient browser authority. Grants can be absent, denied, revoked, timed
  out, cancelled, and disposed.
- Capability inputs and results remain untrusted for server decisions. File,
  clipboard, location, storage, and similar handles are opaque and
  generation-scoped.
- State-changing cookie-authenticated HTTP commands require a server-issued
  CSRF mechanism plus same-origin/site policy appropriate to deployment.
- Persistent/realtime transports authenticate their connection and enforce
  allowed origins; each command still performs resource authorization.
- Cross-origin deployments must explicitly list allowed origins, credential
  behavior, preflight/cache policy, embedding policy, and token exposure risk.
  Wildcard credentialed origins are forbidden.

## Content integrity and secret exclusion

Production assets use HTTPS, exact build manifests, content-addressed or hashed
immutable runtime/code assets, correct Wasm/JavaScript MIME types, and a CSP
whose script/worker/connect sources are no broader than the selected profile.
Subresource Integrity is used where applicable to the loading shape; equivalent
manifest hash verification is required when SRI cannot cover a fetched asset.
Mixed runtime/application builds fail closed rather than attempting partial
boot.

The build pipeline must prove that client reachability excludes secrets,
server-only configuration, Ecto repositories, privileged endpoint internals,
signing material, unrestricted environment access, and accidental native-only
dependencies. A secret scan supplements but does not replace entrypoint and
reachability analysis.

## Absolute authorization invariants

None of the following is evidence of server authorization or a trusted
mutation:

- a component, button, route, or field being visible or hidden;
- a local control being enabled, disabled, selected, or validated;
- a cached identity, role, permission, record, or prior command result;
- a signed bootstrap token beyond its narrow declared scope;
- successful browser capability use;
- successful JavaScript, AtomVM, BEAM, or WebAssembly execution;
- matching client-side schema, state, or optimistic result; or
- an event originating from BlazeX-authored code.

## Deployment prerequisite status

**Required** means the claimed production mode cannot be supported without it.
**Conditional** means BH-01 or a later mode must determine whether the selected
implementation needs it. **Recommended** improves performance or defense in
depth but is not the mode's semantic precondition. **Not applicable** means the
mode has no browser deployment behavior for that prerequisite.

## Deployment prerequisite matrix

| Prerequisite | Static fallback | Server-rendered | Prerendered | Browser-local | Activated | Headless |
| --- | --- | --- | --- | --- | --- | --- |
| HTTPS/authenticated transport | required in production | required | required | required | required | not applicable |
| Correct HTML/JS/Wasm MIME | required | required | required | required | required | not applicable |
| Content Security Policy | recommended | recommended | recommended | required | required | not applicable |
| Cross-origin isolation | not applicable | not applicable | conditional | conditional | conditional | not applicable |
| COOP | not applicable | not applicable | conditional | conditional | conditional | not applicable |
| COEP | not applicable | not applicable | conditional | conditional | conditional | not applicable |
| Cache/version policy | recommended | recommended | required | required | required | not applicable |
| Compression | recommended | recommended | recommended | recommended | recommended | not applicable |
| Integrity/build manifest | recommended | recommended | required | required | required | not applicable |
| Worker availability/policy | not applicable | not applicable | conditional | conditional | conditional | not applicable |
| Browser storage | not applicable | not applicable | conditional | conditional | conditional | not applicable |
| HTTP/realtime transport | not applicable | required | required | conditional | conditional | test-provided |

### Prerequisite details

- **HTTPS:** local development exceptions are explicitly marked and never
  become production support evidence. Secure-context APIs are inventoried.
- **MIME:** Wasm streaming failure may use a declared buffered fallback only if
  integrity, diagnostics, and performance budgets remain truthful.
- **CSP:** record script, worker, connect, frame, style, font, image, and media
  sources; forbid string-to-code evaluation unless a separately accepted risk
  record exists.
- **Isolation/COOP/COEP:** BH-01 determines whether the selected runtime requires
  `SharedArrayBuffer`/cross-origin isolation. If required, third-party assets,
  OAuth/payment popups, embedding, analytics, and CDN/proxy headers must pass an
  application inventory. Missing isolation selects fallback; it never silently
  starts an incompatible runtime.
- **Caching:** bootstrap/public state is private/no-store or explicitly scoped;
  hashed immutable artifacts may be long-lived; HTML/manifest version mixing is
  prevented; service-worker policy cannot retain incompatible builds.
- **Compression:** avoid double compression and decompression bombs; measure
  compressed and decoded sizes later under Phase 5 budgets.
- **Integrity:** every executable/runtime artifact maps to one build identity
  and provenance record. Unknown or mixed hashes block activation.
- **Workers:** document main-thread fallback only if it passes the same support,
  responsiveness, CSP, lifecycle, and cleanup gates.
- **Storage:** state what is stored, sensitivity, quota/denial behavior, schema,
  expiry, migration, and deletion. Storage absence is a normal capability path.
- **Transport:** declare HTTP, WebSocket, SSE, or other protocol, credentials,
  origin/CSRF, reconnect, backpressure, message limits, and server-loss policy.

## Fallback categories

Every fallback has a stable trigger, bounded user-visible output, accessible
status, fail-closed security behavior, structured diagnostic code, explicit
retry policy, resource cleanup, and support-status message. Silent partial boot
is forbidden.

### `FB-CAPABILITY-UNAVAILABLE`

- **Trigger:** required Web/renderer/host capability is missing, denied, revoked,
  or fails its probe.
- **Response:** use the component/profile-declared alternative, disable only the
  bounded dependent operation, or retain static content; never fabricate the
  capability.
- **Retry/cleanup:** retry only after a user action or capability-change event;
  cancel probes/effects and dispose partial resources.

### `FB-INCOMPATIBLE-BUILD`

- **Trigger:** runtime, manifest, component schema, asset hash, prerender root,
  or activation build identity does not match.
- **Response:** do not attach or execute mixed artifacts. Keep safe static
  output, request a coherent reload, and prevent retry loops through a bounded
  attempt/version policy.
- **Retry/cleanup:** evict only the incompatible scoped cache, dispose the old
  generation, and offer a user-controlled reload with diagnostic build IDs.

### `FB-NO-JAVASCRIPT`

- **Trigger:** scripts are disabled, blocked, or fail before the loader can run.
- **Response:** deliver the declared static/server-rendered bounded content and
  ordinary links/forms where supported. Do not render a permanent empty mount.
- **Retry/cleanup:** no client retry assumption; server output explains which
  interaction requires scripting without blaming the user.

### `FB-UNSUPPORTED-BROWSER`

- **Trigger:** browser row/version/channel is outside the current support matrix
  or fails a required feature probe.
- **Response:** do not start an incompatible runtime. Preserve bounded content,
  name the unsupported configuration and supported alternatives truthfully,
  and avoid misleading “upgrade” advice when the issue is policy/capability.
- **Retry/cleanup:** rerun detection only after navigation/reload or material
  environment change; remove loader/worker resources.

### `FB-RUNTIME-UNAVAILABLE`

- **Trigger:** runtime/Wasm/AVM artifact fetch, integrity, compilation,
  instantiation, boot, bundle load, or initial root start fails or times out.
- **Response:** keep static/prerendered content or use a separately supported
  server mode; expose a stable error code and correlation ID, not raw internals.
- **Retry/cleanup:** bounded exponential/user-controlled retry by failure class;
  terminate workers/iframes, abort fetches, and dispose partial generations.

### `FB-NETWORK-LOSS`

- **Trigger:** asset or command transport becomes unavailable, interrupted, or
  too stale while the server itself is not known to be permanently unavailable.
- **Response:** local interactions that need no server may continue; commands
  are queued only when their schema/idempotency policy allows it; stale or
  authoritative data is labeled; unsafe mutations fail closed.
- **Retry/cleanup:** connectivity-driven bounded retry with backoff/jitter and
  cancellation; no duplicate mutation replay; clear queues on disposal/logout.

### `FB-SERVER-LOSS`

- **Trigger:** authenticated server session/transport is unavailable, expired,
  revoked, or rejects the current build/session.
- **Response:** preserve safe local/static state, stop authoritative actions,
  mark disconnected/session-expired status accessibly, and require
  reauthentication or explicit reconnection as appropriate.
- **Retry/cleanup:** close stale transports, revoke scoped grants/tokens, cancel
  pending commands, resolve queue policy, and never loop credentials.

## Universal fallback obligations

| Obligation | Required behavior |
| --- | --- |
| Bounded content | Preserve meaningful safe content or a finite unavailable state; no indefinite blank/spinner-only surface. |
| Accessibility | Announce status once appropriately, retain logical focus/order, expose retry controls, respect motion/contrast, and avoid announcement loops. |
| Security | Fail closed for authority, integrity, origin, build, and capability errors; never weaken policy to make boot succeed. |
| Diagnostics | Stable public error code, layer, build/profile/mode, correlation ID, redacted cause, and support-data action where appropriate. |
| Retry | Explicit automatic/user/event trigger, maximum/backoff, idempotency requirement, cancellation, and terminal state. |
| Cleanup | Abort fetches, stop workers/iframes/transports/timers, cancel effects/commands, dispose generations/resources, and remove stale listeners. |
| Truthful messaging | Name unsupported/unavailable/degraded status without claiming support, data safety, authorization, or transparent recovery that was not proved. |

## Change control

Trust changes require security, product, server-adapter, component, capability,
and privacy owners. Deployment/fallback changes additionally require browser
host, build/release, accessibility, operations, and affected profile owners.
Update this policy, the machine-readable envelope, threat model, command and
bootstrap schemas, profile matrix, deployment guide, diagnostics, fallback
catalog, and acceptance records together.

## Connections

- [Browser and toolchain support policy](blazex-browser-and-toolchain-support-policy.md)
- [Browser rendering and profile modes](blazex-browser-rendering-and-profile-modes.md)
- [Canonical vocabulary](blazex-canonical-vocabulary.md)
- [ADR-0003 — Host-neutral effects, capabilities, and resources](architecture-decisions/adr-0003-host-neutral-effects-capabilities-and-resources.md)
- [ADR-0005 — Server adapter and trust boundary](architecture-decisions/adr-0005-server-adapter-and-trust-boundary.md)
- [BH-00 Phase 2 plan](../60-planning/01-browser-host/bh-00-product-boundary-catalog-and-acceptance-contract/phase-02-browser-product-and-support-envelope.md)

## Sources

- [Cross-origin isolation documentation notes](../30-sources/mozilla-2026-cross-origin-isolation-documentation.md)
- [Phoenix documentation notes](../30-sources/phoenix-framework-2026-phoenix-1-8-documentation.md)
- [Plug documentation notes](../30-sources/elixir-plug-team-2026-plug-1-20-documentation.md)
- [WebAssembly JavaScript and Web API notes](../30-sources/webassembly-community-group-2026-javascript-and-web-api.md)
