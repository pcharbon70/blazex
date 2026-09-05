# BH-01 Benchmark Reports

`bh01-phase9-deferred-qualification.json` is the governed Phase 9 deferral
ledger for unavailable mobile, operating-system, second-machine, physical
device, and manual assistive-technology evidence. Deferred rows are excluded
from active Linux pass rates, do not block Phase 9 development completion, and
remain mandatory for support or release no later than BH-22.

`bh01-phase9-artifact-economics.json` attributes decoded bytes, Brotli bytes,
requests, cache policy, and observed runtime phases. It identifies the unpruned
application AVM as 84.045% of decoded and 87.504% of Brotli bytes while
explicitly warning that this bundle includes runtime/library modules.

`bh01-phase9-mitigation-assessment.json` records four bounded candidates,
required before/after evidence, owners, tradeoffs, review triggers, and four
rejected shortcuts. No threshold changed and no estimated saving receives
budget credit.

`bh01-phase9-budget-evaluation.json` applies the unchanged quality contract to
52 explicit active, insufficient, inactive, and deferred evaluations. It keeps
per-environment results separate and uses the worst p95 as the conservative
active-Linux aggregate.

`bh01-phase9-stop-decision.json` records a conditional proceed decision. The
unpruned application AVM fails both application-payload thresholds and the
Firefox development-build timer scenario exceeds the local-event p95 target.
Required mitigations have owners and repeat rules; Phase 10 is not authorized.
