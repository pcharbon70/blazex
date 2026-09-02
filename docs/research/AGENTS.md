# Repository instructions

These instructions apply to the `docs/research` archive. This is a Markdown
research corpus inside the BlazeX project. Preserve room for exploratory
thought while keeping provenance, navigation, and structure reliable.

## Project goal

Research and develop an Elixir-authored, host-neutral UI component framework
that can run through WebAssembly and integrate naturally with Phoenix and
Plug. The browser/Popcorn/AtomVM profile is the first executable path, not the
definition of the product. Preserve desktop and other non-web hosts from the
first public contracts, with fully native controls as the long-term renderer
goal and webview packaging as an explicitly intermediate profile.

Keep four axes distinct: runtime substrate (ERTS, native AtomVM,
AtomVM-in-Wasm, or restricted native Wasm), execution host (browser, webview,
native process, standalone Wasm runtime, server, or test), render backend
(DOM/HTML, native widgets, custom scene, or headless), and server adapter
(Phoenix, Plug, another transport, or none). Also keep three compilation
targets distinct: a language runtime compiled to Wasm that executes BEAM
bytecode, application code AOT-compiled to native Wasm, and standards-level
WebAssembly Component Model binaries.

Do not make HEEx, HTML tags, CSS classes, DOM events, JavaScript objects,
Popcorn, or LiveView renderer data part of the renderer-neutral component
kernel. They belong in adapters. A native-renderer proof must exercise the
semantic tree, event, effect, focus, accessibility, and disposal contracts
before the public component API is considered stable.

Distinguish source claims, local evidence, cross-source synthesis, proposed
architecture, and unverified assumptions. Treat browser code and state as
untrusted. Record exact software versions and access dates for fast-moving
frameworks.

## Archive principles

- Folders describe what a document is doing; maps, links, and tags describe
  what it is about.
- Preserve provenance. Source records, synthesis, experiments, and unresolved
  questions have different document roles.
- Directory READMEs are exhaustive local inventories; maps are selective.
- `frontmatter.schema.json` is the authoritative metadata contract.
- Change a document and every affected index, map, and body link together.

## Canonical structure

```text
00-inbox/       Unprocessed, temporary captures
10-maps/        Curated paths through subjects and questions
20-notes/       Ideas and syntheses in the author's own words
30-sources/     Reading notes and bibliographic records
40-inquiries/   Active questions and research workbenches
50-journal/     Dated observations and research-session evidence
90-archive/     Inactive or superseded material worth retaining
assets/         Images, PDFs, diagrams, datasets, and attachments
templates/      Starting points for documents and directory indexes
```

Do not add or rename a top-level archive directory without a demonstrated
need. Organize subjects through tags, links, and maps first.

## Directory README invariant

Every archive directory must contain a `README.md` created from
`templates/directory-readme.md`. It must use `kind: map`, include `Purpose`,
`What belongs here`, `Index`, and `Maintaining this index`, and inventory every
direct child except itself. Link a child directory through its README.

## Frontmatter contract

Every durable knowledge document and directory README begins with valid YAML
frontmatter. Use lowercase kebab-case tags, quoted `YYYY-MM-DD` dates, YAML
lists, `[]` for an intentionally empty list, and `null` for unknown nullable
source metadata. Do not invent bibliographic values.

- `note` requires `maturity: seed | developing | stable`.
- `inquiry` requires `status: open | paused | resolved`.
- `source` may use bibliographic fields defined in the schema.
- `map` and `journal` use the common fields.

The root README, this file, validator files, and templates are exempt as
specified by the validator.

## Document roles

| Artifact | Destination | Template |
| --- | --- | --- |
| Directory index | Any archive directory's `README.md` | `templates/directory-readme.md` |
| Conceptual map | `10-maps/` | `templates/map.md` |
| Note | `20-notes/` | `templates/note.md` |
| Source note | `30-sources/` | `templates/source.md` |
| Inquiry | `40-inquiries/` | `templates/inquiry.md` |
| Journal entry | `50-journal/` | `templates/journal.md` |

Use lowercase kebab-case filenames, relative local links, subject-based names
for notes/maps, question-based names for inquiries, date-prefixed names for
journals, and author/year/short-title names for source notes.

## Producing research

A deep dive normally creates or updates a connected bundle:

1. a synthesis note in `20-notes/`;
2. a source note in `30-sources/` for each substantively used primary work;
3. an inquiry in `40-inquiries/` while the central question remains open;
4. a topic map and the home map in `10-maps/`;
5. journal evidence for material local inspection or measurements; and
6. every affected directory README.

Prefer official specifications, source trees, release notes, and project
documentation. Record versions, revisions, commands, output, and limitations.
Do not treat search snippets as evidence for detailed claims. Include negative
findings, compatibility limits, and unresolved questions.

## Verification

Before reporting archive work complete:

1. inspect repository status and preserve unrelated changes;
2. run `python3 validate_archive.py` from this directory;
3. run `python3 -m unittest test_validate_archive.py` if validation behavior changed;
4. verify new external citations against primary sources;
5. run `git diff --check` from the project root; and
6. inspect the complete change for stale paths and accidental rewrites.

Do not commit, push, publish, or open a pull request unless the user asks.
