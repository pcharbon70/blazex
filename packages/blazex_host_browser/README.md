# BlazeX Browser Host

Provides browser-specific host capabilities and lifecycle integration to a
BlazeX runtime, including capability negotiation, resource access, scheduling,
transport attachment, and browser diagnostics.

The package must not require Phoenix. Phoenix and Plug profiles attach their
own transports and server facilities through separate adapters. It implements
browser capabilities declared by `blazex_effects` without exposing Web API
handles to portable components.

Status: experimental BH-03 Phase 2 compatibility boundary. The dependency-free
package publishes the host's eight exact required identities and rejects
missing, unknown, duplicate, malformed, or mismatched input before artifact
acquisition. Discovery and Web API prerequisite checks remain browser-loader
work; lifecycle behavior is still unimplemented. Its modules are not a stable
public API.
