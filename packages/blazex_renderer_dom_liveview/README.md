# BlazeX LiveView DOM Renderer Adapter

Adapts the standalone BlazeX DOM renderer to LiveView and LocalLiveView render
data, patching, lifecycle, and transport behavior. All coupling to their private
or version-sensitive implementation details is isolated and version-pinned in
this package.

The adapter may be included by the browser/Phoenix profile, but it is forbidden
from the browser/Plug profile. Portable components and the standalone DOM
renderer must not depend on it.

Status: experimental BH-01 optional-adapter Mix skeleton. The project has no
dependencies and contains no LiveView or LocalLiveView implementation; those
candidate APIs are qualified later. Its module root is not a stable public API.
