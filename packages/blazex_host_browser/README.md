# BlazeX Browser Host

Provides browser-specific host capabilities and lifecycle integration to a
BlazeX runtime, including capability negotiation, resource access, scheduling,
transport attachment, and browser diagnostics.

The package must not require Phoenix. Phoenix and Plug profiles attach their
own transports and server facilities through separate adapters. It implements
browser capabilities declared by `blazex_effects` without exposing Web API
handles to portable components.

Status: experimental BH-03 Phase 4 shared-runtime and root-lifecycle boundary.
The dependency-free package publishes the host's eight exact required
identities and the closed root lifecycle vocabulary. The browser runtime
package implements compatible runtime sharing and independent root queues;
shutdown and runtime-loss behavior remain unimplemented. Its modules are not a
stable public API.
