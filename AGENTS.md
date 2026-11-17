# AGENTS.md

Single source of truth for agents working on **custom-controls**.

Ready-to-use custom controls for abap2UI5 - signature pad, charts and more.

## What this repository is

A **source** repository in the abap2UI5 ecosystem: humans and agents edit here,
and CI gates every change. It is installed with abapGit and depends on the
[abap2UI5](https://github.com/abap2UI5/abap2UI5) core at runtime.

## Layout

| Path | Contents |
| --- | --- |
| `src/` | One ABAP class per control — the view builder that emits its XML element, plus the types its configuration needs |
| `src/00/` | Samples (`z2ui5_cl_cci_sample_*`) |
| `src/01/` | The generated BSP: the JavaScript of every control, plus the ICF nodes |
| `app/` | The JavaScript sources the BSP is built from |
| `tools/` | `app2bsp` (→ `src/01/`), `vendor` (third-party libraries) and their tests |

`src/01/` is **generated**. Change `app/`, then run `npm run build:local`.

## Dependencies

- [abap2UI5](https://github.com/abap2UI5/abap2UI5) — the framework

There is no version pin on any of them — abaplint resolves each from its `main`
branch. That is why `ci` also runs on a weekly schedule: a rename
upstream breaks this repository silently, and with no pull request open nothing
else would notice.

## Build and verify

```sh
npm ci
npm run check
```

`npm run check` runs abaplint (Standard and ABAP Cloud), the abap2UI5-linter,
the Node tests, a syntax check of the controls and the overlay browser check.
CI also checks that `src/01/` matches `npm run app2bsp`, that `LibUrls.js`
matches `npm run vendor`, and that `npm run build:local` succeeds - those
rewrite the tree, so they are not part of `check`. See
[CONTRIBUTING.md](CONTRIBUTING.md) for what each gate proves and how the
abap2UI5-linter baseline works.

## CI

The ABAP checks come from the shared CI template of abap2UI5-addons (reusable
workflows in
[rap-ext](https://github.com/abap2UI5-addons/rap-ext/blob/main/.github/ci/README.md),
pinned by commit in the `uses:` lines and moved by `bump-deps`); the
JavaScript checks are this repository's own jobs in the same workflow:

* `ci` - on every push to `main`, every pull request, weekly and by hand:
  * `check / abaplint (./abaplint.jsonc)` and
    `check / abaplint (.github/abaplint/abap_cloud.jsonc)` - Standard ABAP and
    ABAP Cloud
  * `check / abap2ui5lint` - the app classes and their views, render gate off
    (the UI5 metadata snapshot cannot know `z2ui5_cci.cc.SignaturePad`); on
    `main` the two README badges are published to the branch `badges`
  * `app2bsp`, `vendor` (with `npm run build:local`) and `js` (`node --check`,
    `npm test`, `npm run check:browser`)
* `ci-702` - on every push to `main` `npm run auto_downport` (against
  `.github/abaplint/abap_702.jsonc`), a force-push to the branch `702`, then
  abaplint on that branch. Never commit to `702` by hand.
* `publish-local` - not from the template: rebuilds the branch `local` with
  the libraries vendored in
* `deploy-pages`, `bump-deps` (monthly; the template pin moves only with the
  `DEPS_TOKEN` secret)

No sibling addon, so no `.github/deps.json`; no ABAP Unit tests and no rename
script, so no `unit` and no `rename` job. The job names above are the
required status checks of the branch protection.

## Views

Views are built with **`z2ui5_cl_ui5_view_builder`**, the core's generic builder
in `src/02`: `ele` (add a child and descend), `tag` (add a child and stay), `a`
(set an attribute on the element the chain points at), `end` (ascend),
`stringify` (render from the root).

Three rules that are easy to get wrong:

1. **`a( )` targets the last child** once a node has children, so a control's
   attributes belong immediately after the `ele( )`/`tag( )` that opened it.
2. **An ABAP boolean goes into `b =`.** Through `v =` an `abap_false` renders as
   an empty string, and UI5 reads an empty string as true.
3. **The root declares its own namespaces.** The frozen builder collected them
   and wrote the `xmlns` attributes itself; this one does not, and a prefix that
   is used but not declared makes the whole view fail to parse — a blank screen,
   not a bad layout. An aggregation tag takes the namespace of *its own control*:
   under `<form:SimpleForm>` it is `<form:content>`, never `<content>`.

The frozen `z2ui5_cl_xml_view` is gone from here and must not come back. It sits
in the core's `src/99`, outside the released API, and the view gate can read
nothing built with it.

## Conventions

- ABAP object names follow ``z2ui5_cl_cci_*``, enforced by `abaplint.jsonc`.
- English for code, comments, commit messages, pull requests and issues.
- All text files are LF-only (`.gitattributes`).
- The ecosystem-wide rules — workflow and npm-script naming, toolchain versions,
  which documentation files exist, commit style — live in
  [CONVENTIONS.md](https://github.com/abap2UI5/abap2UI5/blob/main/.github/shared/CONVENTIONS.md)
  and bind this repository too.
