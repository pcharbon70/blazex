# BH-06 candidate third-party notices

This development candidate combines project-owned BlazeX code with the inputs
below. This inventory records observed licensing; it does not replace upstream
license texts or grant redistribution rights for BlazeX itself.

| Record | Component | Version/source | Observed license | Scope |
| --- | --- | --- | --- | --- |
| `BX-BH06-LICENSE-ELIXIR` | Elixir | 1.18.4 | Apache-2.0 | shipped BEAM modules |
| `BX-BH06-LICENSE-ERLANG-OTP` | Erlang/OTP | 27 / ERTS 15.2.3 | Apache-2.0 | shipped BEAM modules |
| `BX-BH01-LICENSE-POPCORN` | Popcorn | 0.3.3 | Apache-2.0 | shipped bridge/build modules |
| `BX-BH01-LICENSE-JASON` | Jason | 1.4.5 | Apache-2.0 | shipped JSON modules |
| `BX-BH01-LICENSE-FISSIONVM` | FissionVM | commit `6c3208c7b3dbc7dacc35a19f8de1fa80b358ac73` | Apache-2.0 selected from Apache-2.0 OR LGPL-2.1-or-later | runtime and AtomVM-derived patches |
| `BX-BH01-LICENSE-MBEDTLS` | Mbed TLS | 3.6.3.1 | Apache-2.0 | linked runtime |
| `BX-BH01-LICENSE-EMSCRIPTEN` | Emscripten SDK image | 4.0.8 / pinned image digest | MIT plus bundled LLVM/Binaryen notices | generated runtime glue |
| `BX-BH01-LICENSE-ZLIB` | zlib | 1.3.1 | Zlib | linked runtime port |
| `BX-BH01-LICENSE-NINJA` | Ninja | 1.12.1 | Apache-2.0 | build-only lineage |
| `BX-BH01-LICENSE-GPERF` | GNU gperf | 3.1-1build1 | GPL-3.0-or-later | build-only generated BIF tables |

The exact upstream runtime notice and retention obligations remain in
`packages/blazex_runtime_popcorn/runtime/THIRD_PARTY_NOTICES.md`. Popcorn and
Jason license texts are retained in their fetched package sources during the
reproducible fixture build. Elixir and Erlang/OTP license texts are supplied by
their respective upstream distributions.

BlazeX-owned records use `NOASSERTION` with a
`private-development-only` disposition because this repository has no
repository-level public license at this phase.
