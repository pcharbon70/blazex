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
60-planning/    Numbered implementation roadmaps and phase evidence
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
| Architecture decision | `20-notes/architecture-decisions/` | `templates/architecture-decision.md` |
| Source note | `30-sources/` | `templates/source.md` |
| Inquiry | `40-inquiries/` | `templates/inquiry.md` |
| Journal entry | `50-journal/` | `templates/journal.md` |
| Planning-stream index | `60-planning/<NN>-<name>/README.md` | `templates/directory-readme.md` |
| Implementation phase | `60-planning/<NN>-<name>/` | `templates/note.md` |

Use lowercase kebab-case filenames, relative local links, subject-based names
for notes/maps, question-based names for inquiries, date-prefixed names for
journals, and author/year/short-title names for source notes.

### Architecture decision records

Durable BlazeX architecture decisions live under
`20-notes/architecture-decisions/` so they remain inside the research corpus
without adding a new top-level document role. Use `kind: note`; proposed records
and records under review use `maturity: developing`, while accepted, rejected,
deprecated, superseded, and archived historical records use `maturity: stable`.

The decision lifecycle states are `proposed`, `under-review`, `accepted`,
`rejected`, `deprecated`, `superseded`, and `archived`. Review is a visible
state, not an undocumented interval. Archival removes a non-binding historical
record from the active register but never deletes it or releases its ID for
reuse.

Name records `adr-<four-digit-id>-<descriptive-name>.md`. IDs are permanent and
never reused. The body metadata records decision status, date, owners, scope,
supersession, and review triggers. Every record names accountable architecture
and product owner roles plus any specialist owners. Every accepted decision
includes context, the decision, rationale, consequences, alternatives,
compatibility, security, accessibility, packaging/dependency, and cross-backend
impact, evidence basis, unresolved evidence, and change-control rules. Update
affected roadmaps, catalogs, maps, package/profile boundaries, and acceptance
records atomically.

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

## Producing implementation plans

Implementation roadmaps live in `60-planning/`. Each planning stream uses the
next unused two-digit directory prefix so its introduction order remains
visible. Never renumber an existing stream or reuse an archived stream's
number.

Each planning stream uses:

1. a `README.md` with `kind: map` for scope, shared status rules,
   dependencies, milestone or phase index, and the eventual roadmap completion
   gate;
2. one `kind: note` document per future phase, normally with
   `maturity: developing`; a stream that spans multiple named roadmap
   milestones groups each milestone under its own indexed subdirectory;
3. links to the research notes and inquiries whose claims the plan tests; and
4. completion evidence that remains unchecked until reproducible
   implementation evidence exists.

Name planning-stream directories `<NN>-<descriptive-name>`. A single-roadmap
stream may keep `phase-<NN>-<descriptive-name>.md` files directly in the stream.
A multi-milestone stream uses `<milestone-id>-<descriptive-name>/README.md` plus
phase files inside that milestone directory. Phase numbering restarts within
each milestone plan. Do not create phase documents merely to populate a new
planning scaffold; phase decomposition is a separate planning decision.

When detailed phases are authorized, use a consistent phase, section, task,
and subtask hierarchy. Every phase must end with an integration gate and a
completion-evidence checklist. A research conclusion, stub, compilation
result, or happy-path demonstration is not completed implementation evidence
unless it satisfies the phase's stated gate.

## Verification

Before reporting archive work complete:

1. inspect repository status and preserve unrelated changes;
2. run `python3 validate_archive.py` from this directory;
3. run `python3 -m unittest test_validate_archive.py` if validation behavior changed;
4. run `python3 validate_browser_product_envelope.py` and
   `python3 -m unittest test_validate_browser_product_envelope.py` when the
   browser product envelope or its validator changes;
5. run `python3 validate_component_catalog.py` and
   `python3 -m unittest test_validate_component_catalog.py` plus
   `python3 generate_component_catalog.py --check` when the catalog lock,
   schema, authored inventory, generated views, generator, or validator changes;
6. run `python3 validate_component_classification.py`,
   `python3 -m unittest test_validate_component_classification.py`, and
   `python3 generate_component_classification.py --check` when Phase 4 product,
   package, capability, fallback, remote, portability, or generated
   classification artifacts change;
7. verify new external citations against primary sources;
8. run `git diff --check` from the project root; and
9. inspect the complete change for stale paths and accidental rewrites.

Do not commit, push, publish, or open a pull request unless the user asks.
