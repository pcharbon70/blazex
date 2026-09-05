# BlazeX Renderer

Defines the renderer behaviour and protocol shared by all visual and headless
backends. It will cover capability negotiation, mounting, updates, generations,
error reporting, resource ownership, and disposal.

This package contains no concrete rendering implementation and must not assume
a DOM, WebView, native toolkit, or server framework.

Status: experimental BH-02 Phase 1 Mix skeleton. Renderer lifecycle and
capability-negotiation contracts remain unimplemented.
