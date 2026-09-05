# BlazeX UI Tree

Defines the versioned semantic UI tree exchanged between component evaluation
and renderer backends. Its vocabulary will cover semantic nodes, layout,
styling tokens, accessibility, resources, identity, and incremental changes.

The representation must describe intent without embedding HTML, CSS, DOM, or
native-toolkit objects. Renderer-specific lowering belongs in renderer
packages. The tree may refer to opaque resource identities, but effect and
resource lifecycle belongs to `blazex_effects`.

Status: experimental BH-02 Phase 2 implementation. Version-1 nodes, structural
identity checks, sibling uniqueness, ancestry validation, and deterministic
preorder traversal are implemented. Later semantic fields and stable public
APIs remain deferred.
