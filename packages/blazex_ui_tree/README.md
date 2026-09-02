# BlazeX UI Tree

Defines the versioned semantic UI tree exchanged between component evaluation
and renderer backends. Its vocabulary will cover semantic nodes, layout,
styling tokens, accessibility, resources, identity, and incremental changes.

The representation must describe intent without embedding HTML, CSS, DOM, or
native-toolkit objects. Renderer-specific lowering belongs in renderer
packages.

Status: directory scaffold only; create the Mix project when its implementation
milestone begins.

