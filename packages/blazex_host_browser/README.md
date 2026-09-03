# BlazeX Browser Host

Provides browser-specific host capabilities and lifecycle integration to a
BlazeX runtime, including capability negotiation, resource access, scheduling,
transport attachment, and browser diagnostics.

The package must not require Phoenix. Phoenix and Plug profiles attach their
own transports and server facilities through separate adapters. It implements
browser capabilities declared by `blazex_effects` without exposing Web API
handles to portable components.

Status: experimental BH-01 Mix skeleton. The project has no dependencies and
contains no browser implementation; capability and lifecycle behavior remains
unexecuted. Its module root is not a stable public API.
