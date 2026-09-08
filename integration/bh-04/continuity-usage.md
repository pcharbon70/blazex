# Experimental Phase 6 continuity

Author `FormState` values and option identities inside a `FormOutput` around an
unchanged `IntentSet`. Text/check owners are leaf fields; single/multiple owners
are collections with descendant leaf selection choices. The current reference
lowering uses checkbox accessibility intent on choice nodes. Choice values are
explicit unique binary keys, not child indexes. Missing selections reject.

Use `FormEvaluator` and `ContinuitySession`, not a legacy consumer that would
drop this additive wrapper. Existing component callbacks are unchanged: the
first `handle_event/4` argument is the existing semantic Event. Return each
control's handled `event.sequence` as `edit_sequence`; future acknowledgements
are rejected. Components can explicitly accept or replace a submitted value.

`ContinuityRenderer` binds the complete control manifest and immutable v2
transaction in `blazex.dom-continuity/1`. Each acknowledgement contains `state`,
the original v2 `ack`, and `continuity_digest`. Runtime state remains provisional
until both digest and DOM acknowledgement agree. Failed renders do not promote
candidate state. Dispose/re-establish a root after uncertain results; no input
retry is implied.

The browser adapter opts into `blazex.host-bridge/3` and
`AtomicDOMRoots.attach(..., {continuity: true, interactions, ...})`. Pass the
whole continuity envelope to `submit`; legacy roots reject it. V1 lifecycle and
v2 interaction/renderer consumers retain their original formats. The executable
[scenarios](continuity-scenarios.js) demonstrate exact setup and acknowledgement.
The existing Wasm profile/demo has not been upgraded to this endpoint.

Newer local edits survive older accepted renders. Composition is local and
does not synthesize semantic input; after composition ends, the unsubmitted
draft survives until a genuine input event. Blur clears composition tracking;
replacement, rejection, disposal and runtime loss clear owned tracking.
Files and metadata remain unsupported and uninspected. Readonly/disabled input
is rejected before delivery. Native properties and accessibility flags have
distinct ownership; form flags govern the corresponding rendered control flags.

Focus/selection capture occurs immediately before the synchronous commit, not
when an asynchronous request begins. Unchanged keyed nodes retain ranges;
new explicit text-range intent clamps to the current value. Only new autofocus
intent runs. Sibling focus is never stolen, disabled/hidden targets are skipped,
and recovery follows an authored restore-previous scope without trapping Tab.
No post-commit effects are introduced.

Run from the repository root:

```sh
node integration/bh-04/continuity-browser.mjs /tmp/bh04-continuity.json
node integration/bh-04/continuity-conformance.mjs /tmp/bh04-continuity.json
```

This executes real Elixir in offline ERTS via test-only DevTools/stdio. Browser
keyboard and pointer input is automated; composition is programmatic native
event automation, not a physical IME or manual assistive-technology pass.
See the research evidence and validation log for exact versions and deferrals.
