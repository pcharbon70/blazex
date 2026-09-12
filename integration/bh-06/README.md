# BH-06 build-pipeline evidence

Phase 1 owns the first continuous browser-Wasm vertical slice. Phase 2 adds an
explicit, deterministic entrypoint-rooted BEAM inventory to that candidate build.

- [`vertical_slice`](vertical_slice/README.md) contains the public Elixir
  counter, candidate package task, integrity-verifying host, and browser matrix.
- [`candidate-build-manifest-v0.1.0.json`](candidate-build-manifest-v0.1.0.json)
  records five governed outputs and their exact content identities.
- [`browser-slice-v0.1.0.json`](browser-slice-v0.1.0.json) records matching
  Chrome/Firefox lifecycle results and the fail-closed integrity case.
- [`phase-02-build-manifest-v0.1.0.json`](phase-02-build-manifest-v0.1.0.json)
  and [`phase-02-browser-replay-v0.1.0.json`](phase-02-browser-replay-v0.1.0.json)
  bind the exact Phase 2 package and its repeated Chrome/Firefox replay.
- [`reachability-v0.1.0.json`](reachability-v0.1.0.json) records the Phase 2
  entrypoint-rooted module inventory, external references, and deliberately
  excluded unused sentinel; its schema is
  [`reachability.schema.json`](reachability.schema.json).
- [`client-safety-policy-v0.1.0.json`](client-safety-policy-v0.1.0.json)
  activates the exact Phase 3 classifications and forbidden-import rules.
- [`client-safety-v0.1.0.json`](client-safety-v0.1.0.json) records the passing
  Phase 3 classification result and its exact normalized policy identity.
- [`phase-03-build-manifest-v0.1.0.json`](phase-03-build-manifest-v0.1.0.json)
  and [`phase-03-browser-replay-v0.1.0.json`](phase-03-browser-replay-v0.1.0.json)
  bind the exact safety-gated package and Chrome/Firefox replay.
- [`compatibility-requirements-v0.1.0.json`](compatibility-requirements-v0.1.0.json)
  declares the exact runtime, ABI, protocols, and features required by the slice.
- [`compatibility-v0.1.0.json`](compatibility-v0.1.0.json) records the exact
  Phase 4 match against the runtime-owned profile.
- [`phase-04-build-manifest-v0.1.0.json`](phase-04-build-manifest-v0.1.0.json)
  and [`phase-04-browser-replay-v0.1.0.json`](phase-04-browser-replay-v0.1.0.json)
  bind the compatibility-gated package and deterministic Chrome/Firefox replay.
- [`secret-policy-v0.1.0.json`](secret-policy-v0.1.0.json) freezes fixed
  signatures, public-config key fragments, and explicit scaling limits.
- [`secret-audit-v0.1.0.json`](secret-audit-v0.1.0.json) accounts for every
  Phase 5 bundle/browser input by path-free label, size, and digest with no findings.
- [`phase-05-build-manifest-v0.1.0.json`](phase-05-build-manifest-v0.1.0.json)
  and [`phase-05-browser-replay-v0.1.0.json`](phase-05-browser-replay-v0.1.0.json)
  bind the secret-gated package and deterministic Chrome/Firefox replay.
- [`license-policy-v0.1.0.json`](license-policy-v0.1.0.json) freezes the Phase 6
  component, license-record, notice-integrity, lineage, and scaling authority;
  its schema is [`license-policy.schema.json`](license-policy.schema.json).
- [`license-inventory.schema.json`](license-inventory.schema.json) freezes the
  normalized input-accounting result contract before Phase 6 claims a pass.
- [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) summarizes the candidate's
  shipped and build-only third-party lineage without granting BlazeX rights.
- [`license-inventory-v0.1.0.json`](license-inventory-v0.1.0.json) binds every
  Phase 6 input to one shipped component, license records, and verified notices.
- [`phase-06-build-manifest-v0.1.0.json`](phase-06-build-manifest-v0.1.0.json)
  and [`phase-06-browser-replay-v0.1.0.json`](phase-06-browser-replay-v0.1.0.json)
  bind the inventory-gated package and exact Chrome/Firefox Wasm replay.
- [`phase-06-secret-audit-v0.1.0.json`](phase-06-secret-audit-v0.1.0.json)
  binds the exact predecessor input identities used by the inventory parity gate.
- [`bundle-policy-v0.1.0.json`](bundle-policy-v0.1.0.json) freezes Phase 7 base,
  startup, feature membership, and scaling authority; its schema is
  [`bundle-policy.schema.json`](bundle-policy.schema.json).
- [`bundle-plan.schema.json`](bundle-plan.schema.json) freezes the normalized,
  path-free ownership result before Phase 7 claims a pass.
