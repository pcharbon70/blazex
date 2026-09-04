# BlazeX LiveView DOM Renderer Adapter

Adapts the standalone BlazeX DOM renderer to LiveView and LocalLiveView render
data, patching, lifecycle, and transport behavior. All coupling to their private
or version-sensitive implementation details is isolated and version-pinned in
this package.

The adapter may be included by the browser/Phoenix profile, but it is forbidden
from the browser/Plug profile. Portable components and the standalone DOM
renderer must not depend on it.

Status: experimental BH-01 Phase 6 compatibility and isolation fixture. The
project deliberately has no LiveView dependency: it probes an explicit
descriptor for the exact pinned candidate pair, translates only disposable
fixture patch envelopes, and disables itself on mismatch before partial
activation. It does not claim to implement or stabilize LiveView rendering.
Its module root is not a stable public API.
