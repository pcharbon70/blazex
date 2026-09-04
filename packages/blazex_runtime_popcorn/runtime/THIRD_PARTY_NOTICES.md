# BH-01 runtime third-party notices

This Phase 3 feasibility build is not a distribution bundle. The records below
identify every direct runtime and fixture build input, its exact provenance,
license disposition, reachability, and the notice material that a future
distribution process must retain. Full upstream license text remains in each
checksum-qualified source archive and must be copied into any distributed
artifact set.

| Stable license record | Input | Version / identity | License disposition | Reachability | Required retained material |
| --- | --- | --- | --- | --- | --- |
| `BX-BH01-LICENSE-FISSIONVM` | software-mansion-labs/FissionVM | commit `6c3208c7b3dbc7dacc35a19f8de1fa80b358ac73` | Apache-2.0 selected from Apache-2.0 OR LGPL-2.1-or-later | linked runtime | `LICENSE`, `LICENSES/`, REUSE metadata, and file-level notices |
| `BX-BH01-LICENSE-MBEDTLS` | Mbed TLS | 3.6.3.1 | Apache-2.0 | linked runtime | license and source notices |
| `BX-BH01-LICENSE-EMSCRIPTEN` | Emscripten SDK image | 4.0.8, image digest `sha256:92c97951b9a6835cb5da9592e9d95226f67e09ecd01a541d817a5b4801f235a4` | MIT plus bundled LLVM/Binaryen notices | build toolchain and generated glue | Emscripten, LLVM, Binaryen, and bundled-tool notices |
| `BX-BH01-LICENSE-NINJA` | Ninja | 1.12.1 | Apache-2.0 | build-only | license and attribution |
| `BX-BH01-LICENSE-GPERF` | GNU gperf | 3.1-1build1 | GPL-3.0-or-later | build-only generated BIF tables | license and generated-output review record |
| `BX-BH01-LICENSE-ZLIB` | zlib | 1.3.1 | Zlib | linked runtime port | zlib license notice |
| `BX-BH01-LICENSE-POPCORN` | Popcorn Hex package | 0.3.3 | Apache-2.0 | fixture packaging and selected runtime bridge modules | `LICENSE` and package attribution |
| `BX-BH01-LICENSE-JASON` | Jason Hex package | 1.4.5 | Apache-2.0 | selected runtime JSON bridge modules | `LICENSE` and package attribution |

No BlazeX source patch is applied in this phase. The stable patch record is
`BX-BH01-RUNTIME-PATCHES-0.1` in `patches/manifest.json`; it must be reassessed
whenever a runtime input changes.
