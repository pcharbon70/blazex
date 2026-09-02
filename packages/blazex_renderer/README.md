# BlazeX Renderer

Defines the renderer behaviour and protocol shared by all visual and headless
backends. It will cover capability negotiation, mounting, updates, generations,
error reporting, resource ownership, and disposal.

This package contains no concrete rendering implementation and must not assume
a DOM, WebView, native toolkit, or server framework.

Status: directory scaffold only; create the Mix project when its implementation
milestone begins.

