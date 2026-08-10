[![abap version](https://img.shields.io/badge/abap%20version-standard%20%28%E2%89%A5%207.50%29-blue)](#install)
[![namespace](https://img.shields.io/badge/namespace-z2ui5__cl__cci-blue)](abaplint.jsonc)
[![bsp](https://img.shields.io/badge/bsp-Z2UI5_CCI-blue)](#install)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
<br>
[![check](https://github.com/abap2UI5-addons/custom-controls/actions/workflows/check.yml/badge.svg)](https://github.com/abap2UI5-addons/custom-controls/actions/workflows/check.yml)

# abap2UI5 custom controls

Eleven ready-to-use custom controls for
[abap2UI5](https://github.com/abap2UI5/abap2UI5) — signature pad, charts,
barcodes, Excel export, form validation, product tours, Font Awesome, animations,
clickable image maps, Markdown and a code editor.

They ship in their **own BSP** (`Z2UI5_CCI`), not inside the framework. Install this
repository and the controls are there; nothing in abap2UI5 or in the frontend BSP
has to change, and no pull request against the framework is needed to add one.

## Install

1. Install this repository with abapGit. It brings the ABAP classes, the BSP
   application `Z2UI5_CCI` and the two ICF nodes it is served from.
2. Start **`?app_start=z2ui5_cl_cci_sample_00`** — the overview app lists every
   control and opens its sample.

Requires abap2UI5 with the reserved resourceRoot `z2ui5_cci` in the frontend
manifest (see [Troubleshooting](#troubleshooting) if a control stays blank).

On a system whose browsers have no internet access, install the `local` branch
instead — see [Branches](#branches).

## Using a control

Every control has a builder class with one `render( )` method. Declare the
namespace once per view, then add controls like any other:

```abap
DATA(view) = z2ui5_cl_ai_xml=>factory( ).

DATA(root) = view->open( n  = `View`
                         ns = `mvc`
    )->a( n = `xmlns`     v = `sap.m`
    )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).

z2ui5_cl_cci=>xmlns( root ).             " declares xmlns:z2ui5_cci - once per view

DATA(page) = root->open( `Page`
    )->a( n = `title` v = `Signature` ).

z2ui5_cl_cci_signature_pad=>render(
    view   = page
    value  = client->_bind( signature )   " the base64 PNG arrives here
    height = `200px`
    change = client->_event( `SIGNED` ) ).

client->view_display( view->stringify( ) ).
```

That is all — properties bind, values are written back into your ABAP variables
and events arrive in `on_event` like for any built-in control.

## What's in it

| Control | What it does | Builder | Sample |
|---|---|---|---|
| SignaturePad | sign with mouse, finger or stylus → base64 PNG | `z2ui5_cl_cci_signature_pad` | `..._sample_01` |
| ExportSpreadsheet | export a table's rows as `.xlsx`, in the browser | `z2ui5_cl_cci_spreadsheet` | `..._sample_02` |
| Validator | check a form against ABAP rules without a roundtrip | `z2ui5_cl_cci_validator` | `..._sample_03` |
| ChartJs | [Chart.js](https://www.chartjs.org) charts from a bound structure | `z2ui5_cl_cci_chartjs` | `..._sample_04` |
| Barcode | barcodes and QR codes with [bwip-js](https://bwip-js.metafloor.com) | `z2ui5_cl_cci_barcode` | `..._sample_05` |
| DriverJs | product tours and spotlights with [driver.js](https://driverjs.com) | `z2ui5_cl_cci_driverjs` | `..._sample_06` |
| FontAwesome | [Font Awesome](https://fontawesome.com) as UI5 icons and CSS classes | `z2ui5_cl_cci_font_awesome` | `..._sample_07` |
| AnimateCss | [animate.css](https://animate.style) class names on any control | `z2ui5_cl_cci_animate_css` | `..._sample_08` |
| ImageMapster | clickable, highlighting regions on an image | `z2ui5_cl_cci_imagemapster` | `..._sample_09` |
| Markdown | Markdown from ABAP as HTML, with [marked](https://marked.js.org) | `z2ui5_cl_cci_markdown` | `..._sample_10` |
| CodeEditor | UI5's own `sap.ui.codeeditor`, reachable from a view | `z2ui5_cl_cci_code_editor` | inside `..._sample_10` |

Sample classes are `z2ui5_cl_cci_sample_NN` — start any of them directly with
`?app_start=…`, or browse them from `z2ui5_cl_cci_sample_00`, which lists one
row per demo along with the third-party library each control needs. CodeEditor
has no row there because it has no demo of its own: it is the editor on the
left of the Markdown demo.

### SignaturePad

`value` (base64 PNG, bind two-way), `width`, `height`, `linewidth`, `linecolor`,
`editable` · event `change`.

The value is published on pointer-up, not per mouse move. To clear the pad, set
the bound variable to empty.

<img width="769" height="597" alt="image" src="https://github.com/user-attachments/assets/8aa59505-c73e-4f56-8df9-71b127fea574" />

### ExportSpreadsheet

`tableid`, `columns` (a `ty_t_column` table), `filename`, `sheetname`, `text`,
`icon`, `type`, `tooltip`, `enabled`, `status` · event `exported`.

Reads the bound table in the browser, so the data makes no second trip to the
backend. Needs SAPUI5 — under OpenUI5 `sap.ui.export` is missing and the button
renders disabled.

<img width="1252" height="459" alt="image" src="https://github.com/user-attachments/assets/d56be5d4-f43c-4812-94f8-083e38d0fcc2" />


### Validator

`rules` (a `ty_t_rule` table), `trigger`, `valid`, `errors` · event `validated`.

Rule fields: `field`, `type` (`number`/`integer`), `format` (`email`/`date`),
`pattern`, `required`, `minlength`, `maxlength`, `minimum`, `maximum`,
`message`. No external library — works without internet access.

<img width="1246" height="636" alt="image" src="https://github.com/user-attachments/assets/c47560cc-503e-439e-a907-f2ff76790b70" />


### ChartJs

`config` (a `ty_chart` structure), `width`, `height`, `plugins`, `liburl` ·
event `elementpress`.

`config` is the Chart.js configuration verbatim, so anything the Chart.js docs
describe works from ABAP. Change the structure and call `view_model_update( )` to
update in place. `plugins` takes the names from
`z2ui5_cl_cci_chartjs=>cs_plugin` (`datalabels`, `autocolors`, `deferred`,
`annotation`, `venn`, `wordcloud`).

<img width="1248" height="630" alt="image" src="https://github.com/user-attachments/assets/7b20eb12-1823-4b25-a3ad-0dfcab95077a" />

### Barcode

`bcid`, `text`, `alttext`, `scale`, `height`, `includetext`, `textalign`,
`rotate`, `backgroundcolor`, `options`, `renderas` (`canvas`/`svg`), `liburl` ·
event `error`.

`z2ui5_cl_cci_barcode=>get_types( )` returns a handful of symbologies with
values that encode cleanly. Leave `height` empty for 2D codes — a fixed height
squashes a QR code.

<img width="1250" height="626" alt="image" src="https://github.com/user-attachments/assets/5dbed958-a00d-4b4d-9bc1-e36007e51e7c" />

### DriverJs

`config` (a `ty_s_config` structure), `highlight`, `mode`, `trigger`,
`customcss`, `liburl`, `cssurl` · events `highlighted`, `done`.

A step's `element` is the **control id from your view**, not a CSS selector; it
is resolved in the frontend, so a step may point into a nested view or a dialog.

<img width="1244" height="565" alt="image" src="https://github.com/user-attachments/assets/a32d6e9d-ac58-4152-8af0-8d191fc51598" />


### FontAwesome

`fonturi`, `collections`, `cssurl`.

One element in the view and Font Awesome is available two ways: as UI5 icons
(`sap-icon://fa-solid/heart` in any icon property) and as its own CSS classes
(`class="fa-brands fa-github"`). `fonturi` points at a directory holding the font
*and* the metadata JSON the UI5 IconPool needs.

<img width="1248" height="507" alt="image" src="https://github.com/user-attachments/assets/1545f3d3-0c26-4797-aba9-d1a1de108d4c" />

### AnimateCss

`duration`, `delay`, `repeat`, `cssurl`.

Put `animate__animated animate__bounce` into a control's `class` attribute and it
animates. The class names are constants on `z2ui5_cl_cci_animate_css`
(`cs_base`, `cs_attention-*`, `cs_entrance-*`, `cs_exit-*`, `cs_modifier-*`).
`duration`/`delay`/`repeat` retune every animation on the page at once.

<img width="1253" height="623" alt="image" src="https://github.com/user-attachments/assets/b6969b85-73e6-4a27-a7e2-91d78d170b5f" />

### ImageMapster

`src`, `areas` (a `ty_t_area` table), `config`, `selectedkeys` (bind two-way),
`width`, `height`, `autoresize`, `liburl` · event `areapress`.

Turns a floor plan or a machine drawing into an input control: regions highlight,
the selection is written back into the model and a click raises a backend event
carrying the region key. Colours are hex **without** a leading `#`.

<img width="1245" height="508" alt="image" src="https://github.com/user-attachments/assets/b42ba83a-ed4a-43eb-9d06-25f46a493804" />

### Markdown

`value` (the Markdown source), `sanitize`, `breaks`, `gfm`, `width`, `height`,
`liburl`, `purifyurl` · event `linkpress`.

UI5 has no Markdown control. `sap.m.FormattedText` takes HTML and whitelists
only a few tags, so anything with a heading, a table and a code block has to be
assembled as HTML in ABAP — bind a Markdown string instead. Useful for long
texts, release notes, help pages and LLM answers, which come out of every model
as Markdown already.

Bind the same attribute to a `TextArea` and to this control and the preview
follows every keystroke without a roundtrip.

The rendered HTML goes through [DOMPurify](https://github.com/cure53/DOMPurify)
unless `sanitize` is set to `false`. Leave it on for anything a user typed or a
model produced: Markdown carries raw HTML through, and unsanitized that HTML
runs with the user's session. A link whose href starts with `#` does not
navigate — it raises `linkpress` with the href, which is how a help text links
into the app it documents. Every other link opens in a new tab.

### CodeEditor

`value` (bind two-way), `type`, `width`, `height`, `editable`, `linenumbers`,
`colortheme` · event `livechange`.

This one wraps no library at all. UI5 already ships an editor — `sap.ui.codeeditor`,
an ACE editor with syntax highlighting for some eighty languages, served from the
UI5 distribution rather than a CDN, so it also highlights in a system without
internet. Types are on `z2ui5_cl_cci_code_editor=>cs_type`.

What the control adds is a way to **reach** it. `sap.ui.codeeditor` is not among
the abap2UI5 manifest dependencies, and on 1.71 the XML is still processed with
the synchronous strategy: a CodeEditor written straight into a view is fetched
by synchronous XHR and executed with `eval`, which a Content-Security-Policy
without `unsafe-eval` blocks. So the view names this control instead, and the
editor is required asynchronously and created here.

Give it a resolvable `height` — ACE cannot lay out against a percentage unless
the parent has a height of its own.

## Two things to know

### Binding a configuration structure

Five controls take a whole configuration as one property (Chart.js config,
driver.js steps, ImageMapster options, workbook columns, validation rules). Bind
those with this library's JSON filter — and with the camelCase mapper where the
target library expects camelCase names:

```abap
config = client->_bind(
    val           = ms_chart
    custom_filter = NEW z2ui5_cl_cci_json_filter( )
    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                        iv_first_json_upper = abap_false ) )
```

ABAP has no "unset" for a structure component: fields you never touched still
serialize as `""`, `0` or `false`, and `borderWidth: 0` draws no border. The
filter drops initial values so the library's own defaults survive. The flip side:
a value that *is* meaningfully zero, empty or false cannot be sent this way.



### Third-party libraries

Seven controls wrap a library that is not part of UI5 — Chart.js 4, bwip-js 4,
driver.js 1, Font Awesome 6, animate.css 4, jquery.imagemapster 1.5, and
marked 12 together with DOMPurify 3. Each control loads its library on first
use, cached per URL, so ten charts on a page fetch Chart.js once.

Where it loads it from is what separates the two branches: on `main` from
jsDelivr, on `local` from this BSP. Nothing in the repository spells a URL out
— `tools/libs.json` names the npm package and `tools/vendor.mjs` generates
`app/webapp/cc/LibUrls.js` from it and from the version in `package.json`, in
one shape or the other. So the version a browser downloads is the version this
repository was tested against, and a version bump is an edit to `package.json`
plus `npm run vendor`, never a hand-written URL.

A single library can still be redirected per control, on either branch, with the
`liburl` / `cssurl` property:

```abap
z2ui5_cl_cci_chartjs=>render( view = page config = … liburl = `/sap/bc/ui5_ui5/sap/z2ui5_cci/lib/chart.umd.js` ).
```

## Branches

`main` is where development happens; `local` is **generated from it on every
push** and force-pushed by CI. Never develop on it — a commit made there is gone
with the next run. Install it with abapGit exactly like `main`.

| Branch | What it is | Install it when |
|---|---|---|
| `main` | the sources, ABAP ≥ 7.50, libraries from jsDelivr | the default |
| `local` | the same, with every library vendored into the BSP | the browsers have no internet access |

`npm run build:local` copies every library out of `node_modules` into
`app/webapp/lib/` and regenerates the BSP, which grows to about 3.5 MB. The
files are the upstream ones byte-for-byte, with two exceptions. The first is
that **lines are wrapped**. A BSP page is stored as 255-character lines, so a minified bundle
would be chopped at character 256 — in the middle of an identifier as often as
not — and the file the system serves back would no longer be the file that went
in. `tools/wrap-lines.mjs` inserts newlines only where the JavaScript and CSS
grammars treat them as whitespace, and `npm test` proves it by re-parsing every
vendored library and comparing its syntax tree against the original's.

The second is that the trailing `//# sourceMappingURL=` comment is removed. The
`.map` files are developer tooling and are not vendored, so the pointer would
only make a browser with devtools open request a page the BSP does not have —
and a 404 next to a custom control is exactly the symptom someone loses an
afternoon to. Nothing else in the branch reaches outside the SAP system: the
libraries carry no absolute URL they load from (the http links in them are
banner comments and marked's autolink prefix), the stylesheets have no
`@import` and no `url()` other than the inlined fonts, and none of them opens
an XHR, a `fetch` or a script tag of its own.

**UI5 itself is a separate question and lives outside this repository.**
abap2UI5 bootstraps from `https://sdk.openui5.org/...` unless told otherwise,
so an offline system also has to point `cs_config-src` at a local
distribution — see `z2ui5_cl_exit` in the framework. That is what serves
`sap.ui.export` and `sap.ui.codeeditor` too.

Two consequences worth knowing before installing it:

- **Font Awesome's CSS classes work, its UI5 IconPool collections do not.** The
  stylesheet carries the webfonts inline as base64, so `class="fa-solid
  fa-heart"` renders offline. `sap-icon://fa-solid/heart` needs the fonts as
  real files in a directory, plus the metadata JSON that maps icon names to code
  points — and a BSP page is a text object, so neither can ship here. Put that
  bundle in a MIME repository or a BSP of your own and pass the directory as
  `fonturi` to switch the IconPool half back on.
- **ExportSpreadsheet and CodeEditor were never affected**, and still are not:
  both use libraries out of the UI5 distribution rather than a CDN.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `ICF Node NOT found!` | the SICF nodes were not activated — activate `z2ui5_cci` in transaction `SICF` |
| control stays blank, 404 on `cc/<Name>.js` | check `/sap/bc/ui5_ui5/sap/z2ui5_cci/cc/SignaturePad.js` returns JavaScript |
| control stays blank, request goes to `resources/…` | your abap2UI5 frontend predates the reserved resourceRoot `z2ui5_cci`; update it |

In the browser console, `sap.ui.require.toUrl("z2ui5_cci/cc/SignaturePad.js")`
must return the BSP path. That separates a BSP problem from a frontend problem,
which look identical from inside the app.

## Adding your own control

1. write `app/webapp/cc/<Name>.js`, extending `sap.ui.core.Control` under
   `z2ui5_cci.cc.<Name>`, with no dependency on `z2ui5/…` modules
2. wraps a third-party library? add it to `package.json` with an exact version
   and to `tools/libs.json`, then `npm run vendor` — the control reads its URL
   from `z2ui5_cci/cc/LibUrls`, never from a literal, so it works on `main` and
   on `local` without a second code path
3. run `npm run app2bsp` — regenerates the BSP artefacts under `src/01`
4. add a builder class `z2ui5_cl_cci_<name>` next to the others
5. add a sample and a row in `z2ui5_cl_cci_sample_00=>model_init( )`

File names under `app/webapp` become BSP page names and SAP validates them: at
most one directory level, and letters, digits, `_` and `.` only. `app2bsp`
refuses anything else — otherwise you find out on import, as
`CREATE_NEW_PAGE sy-subrc=2 (invalid_name)`.

## Layout

| Path | What it is |
|---|---|
| `app/webapp/cc/*.js` | the controls — plain UI5, the single source of truth |
| `app/webapp/cc/LibUrls.js` | **generated**: where each control loads its library from |
| `app/webapp/lib/` | **generated, `local` branch only**: the vendored libraries |
| `tools/libs.json` | the third-party libraries — npm package, file, CDN URL |
| `tools/vendor.mjs` | writes `LibUrls.js`, and `app/webapp/lib/` with `--local` |
| `tools/wrap-lines.mjs` | breaks a library into lines a BSP page can carry |
| `tools/app2bsp.mjs` | generates the abapGit BSP artefacts from `app/webapp` |
| `src/z2ui5_cl_cci*.clas.abap` | the library and one view builder per control |
| `src/00/` | the overview app and the samples |
| `src/01/` | **generated**: the `Z2UI5_CCI` BSP and its ICF nodes |

Every ABAP object of this repository lives in the `z2ui5_xx_cci` namespace
(`z2ui5_cl_cci`, `z2ui5_cl_cci_<control>`, `z2ui5_cl_cci_sample_NN`) — the same
one-token repository prefix the samples repository uses with `z2ui5_xx_smp`.
The frontend carries the same token: `z2ui5_cci` is the resourceRoot the
abap2UI5 frontend reserves in its `manifest.json`, the BSP `Z2UI5_CCI` and the
UI5 module namespace `z2ui5_cci.cc`. It needs an abap2UI5 that reserves that
root; frontends predating the rename reserve `z2ui5ccc` (and older ones
`z2ui5cc`) and cannot resolve the controls.

CI runs abaplint against the abap2UI5 framework in both syntax versions,
syntax-checks every control, runs the line-wrapper tests, builds the `local`
variant, and fails if any generated artefact — the BSP under `src/01` or
`LibUrls.js` — has drifted from its source.

## Building something only your company needs?

This repository is for controls worth sharing. For a customer's **own**
frontend artefacts — an in-house reuse library, a corporate icon font, company
CSS — use
[abap2UI5/customer-frontend-extension](https://github.com/abap2UI5/customer-frontend-extension).
It is the same mechanism under a second reserved resourceRoot (`z2ui5ext`
instead of `z2ui5_cci`), so the two can be installed side by side and neither
needs a change to abap2UI5.

These controls replace the
[abap2UI5-addons/js-libraries-obsolet](https://github.com/abap2UI5-addons/js-libraries-obsolet)
and
[abap2UI5-addons/custom-controls-obsolet](https://github.com/abap2UI5-addons/custom-controls-obsolet)
repositories, which shipped the same JavaScript as ABAP string literals injected
into every view. Each control's JS file names the class it came from and lists
what changed. Favicon and MessageManager were not ported — abap2UI5 carries them
itself (`z2ui5_cl_xml_view_cc=>favicon( )` / `=>message_manager( )`).
