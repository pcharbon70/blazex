# BlazeX UI Tree

Defines the versioned semantic UI tree exchanged between component evaluation
and renderer backends. Its vocabulary will cover semantic nodes, layout,
styling tokens, accessibility, resources, identity, and incremental changes.

The representation must describe intent without embedding HTML, CSS, DOM, or
native-toolkit objects. Renderer-specific lowering belongs in renderer
packages. The tree may refer to opaque resource identities, but effect and
resource lifecycle belongs to `blazex_effects`.

Status: experimental BH-02 Phase 1 Mix skeleton. Semantic tree data and APIs
remain unimplemented until their later authorized phase.
