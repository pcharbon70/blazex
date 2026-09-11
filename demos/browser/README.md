# BlazeX browser component demo

Part of the [host-specific demos](../README.md), located at `demos/browser/`.

This dependency-free browser project is the persistent gallery for BlazeX
controls. It currently demonstrates the experimental Phase 6 text field and
action button through the real standalone DOM driver. Future controls should
be added as modules under `src/demos/` and registered in `src/catalog.js`.

## Run the gallery

From the repository root:

```bash
cd demos/browser
npm start
```

Open <http://127.0.0.1:4100/> and stop the server with `Ctrl+C`.

To use another port:

```bash
npm start -- --port 4200
```

## Verify the project

```bash
npm run check
npm test
```

The demo uses representative versioned DOM batches in the browser because the
Elixir-to-browser runtime path is not connected yet. It is an experimental
development gallery, not product, visual-conformance, accessibility-support,
or browser-support evidence.

## Adding a control

1. Add one focused module under `src/demos/` that exports an async mount
   function.
2. Render the control into the supplied target using `BlazeXDOMDriver`.
3. Return a controller with `dispose()` so filtering can clean up listeners.
4. Add immutable title, category, phase, status, and description metadata to
   `src/catalog.js`.
5. Add projection validation and registry coverage under `test/`.
