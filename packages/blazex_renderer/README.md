# BlazeX Renderer

Defines the renderer behaviour and protocol shared by all visual and headless
backends. It will cover capability negotiation, mounting, updates, generations,
error reporting, resource ownership, and disposal.

This package contains no concrete rendering implementation and must not assume
a DOM, WebView, native toolkit, or server framework.

Status: experimental BH-02 Phase 5 contract. Exact current-feature
capabilities, derived requirements, deny-by-default negotiation, stable
diagnostics, backend callbacks, and immutable mount/update/replace/dispose
sessions are implemented. No concrete visual renderer or support claim exists.
