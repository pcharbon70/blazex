# Browser/Phoenix Profile Assets

This location owns profile entrypoints, static composition sources, and
deterministic builders. `phase4/` retains the BH-01 feasibility profile source;
`phase6/` assembles the separate BH-03 `/bh03/` development profile from exact
runtime artifacts, the disposable AVM fixture, and the reusable
`js/blazex_runtime` sources. Generated profiles remain ignored build output.
Shared browser lifecycle behavior continues to belong to `js/blazex_runtime`.
