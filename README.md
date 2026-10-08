# custom-controls

[![abap2UI5-addons](https://img.shields.io/badge/abap2UI5--addons-library-1873b4)](https://github.com/abap2UI5-addons)
[![ABAP](https://img.shields.io/badge/ABAP-Standard%20%E2%89%A5%207.50-blue)](#installation)
[![abap2UI5](https://img.shields.io/badge/requires-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![License](https://img.shields.io/github/license/abap2UI5-addons/custom-controls)](LICENSE)
<br>
[![check](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/custom-controls/check.yml?branch=main&label=check)](https://github.com/abap2UI5-addons/custom-controls/actions/workflows/check.yml)
[![check-abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Fcustom-controls%2Fbadges%2Fcheck-abap2ui5.json)](https://github.com/abap2UI5-addons/custom-controls/actions/workflows/check.yml)
[![abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Fcustom-controls%2Fbadges%2Fabap2ui5.json)](https://github.com/abap2UI5-addons/custom-controls/actions/workflows/check.yml)

**Thirteen ready-to-use custom controls for
[abap2UI5](https://github.com/abap2UI5/abap2UI5)** — signature pad, charts,
barcodes, a scanner that reads several barcodes at once, Excel export, form
validation, product tours, Font Awesome, animations, clickable image maps,
Markdown, a code editor and a rich text editor. Each one is a builder class
with one `render( )` method, for abap2UI5 developers who need a control UI5
does not bring along.

> Part of [abap2UI5-addons](https://github.com/abap2UI5-addons) - addons and apps for [abap2UI5](https://github.com/abap2UI5/abap2UI5), installed with [abapGit](https://abapgit.org).

## Why

The controls ship in their **own BSP** (`Z2UI5_CCI`), not inside the framework. Install this
repository and the controls are there; nothing in abap2UI5 or in the frontend BSP
has to change, and no pull request against the framework is needed to add one.

These controls replace the
[abap2UI5-addons/js-libraries-obsolet](https://github.com/abap2UI5-addons/js-libraries-obsolet)
and
[abap2UI5-addons/custom-controls-obsolet](https://github.com/abap2UI5-addons/custom-controls-obsolet)
repositories, which shipped the same JavaScript as ABAP string literals injected
into every view. Each control's JS file names the class it came from and lists
what changed. Favicon and MessageManager were not ported — abap2UI5 carries them
itself (`z2ui5_cl_xml_view_cc=>favicon( )` / `=>message_manager( )`).

## Installation

**Requirements**

- Standard ABAP 7.50 or higher
- [abap2UI5](https://github.com/abap2UI5/abap2UI5) with the reserved
  resourceRoot `z2ui5_cci` in the frontend manifest (see
  [Troubleshooting](#troubleshooting) if a control stays blank)

**Steps** - with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5)
2. this repository - it brings the ABAP classes, the BSP application
   `Z2UI5_CCI` and the two ICF nodes it is served from. Pick the branch:

   | Branch | What it is | Install it when |
   |---|---|---|
   | `main` | the sources, ABAP ≥ 7.50, libraries from jsDelivr | the default |
   | `local` | the same, with every library vendored into the BSP | the browsers have no internet access |

   `local` is generated from `main` by CI - see [Branches](#branches).

**Start** - **`?app_start=z2ui5_cl_cci_sample_00`** — the overview app lists every
control and opens its sample. If it says `ICF Node NOT found!`, activate the
node `z2ui5_cci` in transaction `SICF`.

## Usage

Every control has a builder class with one `render( )` method. Declare the
namespace once per view, then add controls like any other:

```abap
DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

DATA(root) = view->ele( n  = `View`
                        ns = `mvc`
    )->a( n = `xmlns`     v = `sap.m`
    )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).

z2ui5_cl_cci=>xmlns( root ).             " declares xmlns:z2ui5_cci - once per view

DATA(page) = root->ele( `Page`
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
| BarcodeScanner | every barcode in the camera picture at once → an ABAP table, or identical labels counted, with [zxing-wasm](https://github.com/Sec-ant/zxing-wasm) | `z2ui5_cl_cci_barcode_scanner` | `..._sample_11` |
| RichTextEditor | a WYSIWYG editor for HTML with [SunEditor](https://github.com/JiHong88/SunEditor) — on OpenUI5 too | `z2ui5_cl_cci_rich_text_editor` | `..._sample_12` |

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
describe works from ABAP. Change the structure and the chart updates in
place — the framework pushes the changed model on its own. `plugins` takes the names from
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

### BarcodeScanner

`codes` (a `ty_t_code` table, bind two-way), `mode`, `formats`, `expected`,
`text`, `icon`, `type`, `enabled`, `title`, `facingmode`, `deviceid`, `liburl`,
`wasmurl` · events `scanned` (with `count`), `error` (with `message`).

A button that opens the camera. Every frame is read with
[zxing-wasm](https://github.com/Sec-ant/zxing-wasm) — ZXing-C++ compiled to
WebAssembly, the engine SAPUI5's own `sap.ndc` scanner runs too — so **all**
codes in the picture are found at once, outlined live and collected. A label
carrying material, batch and quantity as three codes is taken in one scan
instead of three. `sap.ndc.BarcodeScannerButton` returns one code per scan
(and needs SAPUI5); even its `multiScan` mode returns just the code the user
taps.

```abap
z2ui5_cl_cci_barcode_scanner=>render(
    view     = page
    codes    = client->_bind( t_code )    " TYPE z2ui5_cl_cci_barcode_scanner=>ty_t_code
    formats  = `EAN13,Code128,DataMatrix` " optional - empty reads every format
    expected = `3`                        " optional - complete at 3 codes, without OK
    text     = `Scan`
    scanned  = client->_event( `SCANNED` ) ).
```

When `scanned` arrives, `t_code` holds one row per distinct code — `text`,
`format` (`EAN13`, `Code128`, `QRCode`, `DataMatrix`, …) and `count`, which is
1 unless you count labels (below). A code only counts once it was read in two
frames, which keeps a one-off misread of a worn 1D code out of the result.
Without `expected` the user collects until pressing OK; Cancel leaves the table
untouched. `formats` takes zxing-wasm's names or groups (`AllLinear`,
`AllMatrix`, `AllRetail`, …); naming only what is on the label is faster and
rules out misreads, and a misspelt name is reported through `error`.

**Counting identical labels.** Twelve cartons of one article carry twelve
labels with the same EAN, and a scan of distinct codes returns that EAN once.
With `mode = z2ui5_cl_cci_barcode_scanner=>cs_mode-count` a code is taken as
often as it is in the picture at once — the scan tells two cartons apart by
where their labels sit — and comes back as one row per code, with the number
of labels in `count`:

```abap
z2ui5_cl_cci_barcode_scanner=>render(
    view     = page
    codes    = client->_bind( t_code )
    mode     = z2ui5_cl_cci_barcode_scanner=>cs_mode-count
    formats  = `EAN13`
    expected = `12`                       " optional - complete at 12 labels, all codes together
    text     = `Count`
    scanned  = client->_event( `SCANNED` ) ).
```

A pallet with two articles comes back as two rows, and the event parameter
`count` is all labels together. What makes it reliable, and what it cannot do:

- **All labels have to be in one picture.** The count of a code is the most
  copies one frame showed — confirmed, like a code, by a second frame — and
  never a sum over frames: the camera moves, and a label seen in two frames is
  still one label. A frame that misses a label takes nothing back. For the
  sides of a pallet, scan each side and add the counts up in ABAP.
- **Equal 1D codes one above the other need some room.** The reader takes two
  equal linear codes that are closer than about half their width, vertically,
  for one symbol. Cartons on a pallet are much further apart than that; labels
  printed densely on one sheet are not. QR codes and DataMatrix have no such
  limit, and neither do codes side by side.

Two things the page has to allow:

- **The camera needs a secure connection.** Browsers offer it on `https://`
  (and `localhost`) only.
- **WebAssembly needs `'wasm-unsafe-eval'`** in the `script-src` of the
  Content-Security-Policy. It allows compiling WebAssembly and nothing else —
  JavaScript `eval` stays blocked. abap2UI5's default policy carries it from
  [abap2UI5/abap2UI5#2810](https://github.com/abap2UI5/abap2UI5/pull/2810) on;
  an older installation, or an exit that writes its own policy, adds it.
  Without it the dialog says so. On `main` the reader also comes from
  jsDelivr, so that host goes into `script-src` and `connect-src` as well; the
  `local` branch needs neither:

```abap
METHOD z2ui5_if_ui5_exit~set_config_http_get.

    " main branch: the reader and its module come from jsDelivr
    REPLACE `script-src 'self'` IN cs_config-content_security_policy
       WITH `script-src 'self' cdn.jsdelivr.net`.
    REPLACE `connect-src 'self'` IN cs_config-content_security_policy
       WITH `connect-src 'self' cdn.jsdelivr.net`.

    " an abap2UI5 whose default does not carry it yet
    IF cs_config-content_security_policy NS `'wasm-unsafe-eval'`.
      REPLACE `script-src ` IN cs_config-content_security_policy
         WITH `script-src 'wasm-unsafe-eval' `.
    ENDIF.

ENDMETHOD.
```

`z2ui5_cl_cci_sample_11` shows a test label with four codes and a test pallet
of six cartons of two articles, drawn by the Barcode control: open it on a
second screen and point a phone at it, in either mode.

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
`width`, `height` · event `areapress`.

Turns a floor plan or a machine drawing into an input control: regions highlight,
the selection is written back into the model and a click raises a backend event
carrying the region key. Colours are hex **without** a leading `#`.

The regions are an **SVG overlay** whose `viewBox` is the image's natural pixel
space — the same space the HTML image map `coords` are written in — so the
browser scales them with the image. No library, nothing to resize, and every
region is a real focusable element, so the map is keyboard reachable.

It used to be the jquery.imagemapster plugin drawing on a canvas, which was the
only reason anything in this repository needed jQuery. Three parameters survive
that change as **no-ops**, kept so callers that pass them still compile:
`liburl` and `autoresize` on `render( )`, and `scale_map` in `ty_s_config`.

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

<img width="900" height="508" alt="Screenshot 2026-08-10 at 23 31 13" src="https://github.com/user-attachments/assets/3dd6fed0-2014-4eed-af9f-45d91bfc8e37" />

### RichTextEditor

`value` (the HTML, bind two-way), `editable`, `width`, `height`, `placeholder`,
`toolbar`, `language`, `sanitize`, `liburl`, `cssurl`, `purifyurl`, `langurl` ·
event `change`.

UI5's own `sap.ui.richtexteditor.RichTextEditor` ships with SAPUI5 only, and
abap2UI5 bootstraps OpenUI5 unless told otherwise — where that control does not
exist and the view fails to load. This one runs on both, with
[SunEditor](https://github.com/JiHong88/SunEditor) 3 (MIT):

```abap
z2ui5_cl_cci_rich_text_editor=>render(
    view   = page
    value  = client->_bind( mv_html )
    height = `20rem`
    change = client->_event( `TEXT_CHANGED` ) ).
```

The model follows the typing without a roundtrip, and is brought fully up to
date when the editor loses focus — which happens before a button elsewhere can
start one. `change` fires on that blur, and only when the text changed. A value
ABAP sets is shown and not rewritten: SunEditor normalizes what it is given
(plain text gains a `<p>`), and the app gets back what it sent until somebody
actually edits it.

- **Sanitizing.** The HTML goes through
  [DOMPurify](https://github.com/cure53/DOMPurify) on its way into the editor
  and on its way back, unless `sanitize` is `false`. Leave it on: the text ends
  up in some other page one day, and what comes in may have been typed by
  somebody else.
- **Toolbar.** Button groups separated by `|`, buttons by `,`, named as
  SunEditor names them: `undo,redo|bold,italic|link`. Empty is the full toolbar
  — formats, fonts, colours, alignment, lists, table, link, image, full screen
  and the HTML source view; `z2ui5_cl_cci_rich_text_editor=>cs_toolbar` has two
  smaller ones. Nothing that talks to a server is offered: no video, embeds,
  math, galleries or uploads.
- **Images** go into the HTML as data URIs, so they travel with the text on
  every roundtrip. Give texts that should stay small a toolbar without `image`.
- **Language** follows the UI5 language; SunEditor ships 24 besides English.
- **Theme.** The editor, its toolbar and its pop-ups take their colours and
  font from the UI5 theme — Horizon, its dark variant and the high-contrast
  themes.
- **CSP.** On `main`, SunEditor and its stylesheet come from jsDelivr, so the
  policy has to allow `cdn.jsdelivr.net` in `script-src` and `style-src`. The
  `local` branch needs neither, and nothing needs `'unsafe-eval'`.


## Two things to know

### Binding a configuration structure

Five controls take a whole configuration as one property (Chart.js config,
driver.js steps, ImageMapster options, workbook columns, validation rules). Bind
those with `omit_initial = abap_true` — and with the camelCase mapper where the
target library expects camelCase names:

```abap
config = client->_bind(
    val           = ms_chart
    omit_initial  = abap_true
    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                        iv_first_json_upper = abap_false ) )
```

ABAP has no "unset" for a structure component: fields you never touched still
serialize as `""`, `0` or `false`, and `borderWidth: 0` draws no border.
`omit_initial` drops initial fields so the library's own defaults survive, while
the entries of an array - a `0` in a dataset, a row of a table - are kept. The
flip side: a field that *is* meaningfully zero, empty or false cannot be sent
this way; `omit_initial_paths` limits the omission to the fields it lists.

`z2ui5_cl_cci_json_filter`, which the samples used before, still works, but
`custom_filter` is obsolete on `_bind( )` and the abap2UI5-linter reports it
(`obsolete-bind-argument`).



### Third-party libraries

Eight controls wrap a library that is not part of UI5 — Chart.js 4, bwip-js 4,
driver.js 1, Font Awesome 6, animate.css 4, marked 12 and SunEditor 3 (each
together with DOMPurify 3), and zxing-wasm 3. Each control loads its library on
first use, cached per URL, so ten charts on a page fetch Chart.js once.

The other five need nothing: SignaturePad and Validator are self-contained,
ExportSpreadsheet and CodeEditor use libraries the UI5 distribution already
carries, and ImageMapster draws its own SVG overlay.

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
with the next run. Install it with abapGit exactly like `main` (the table is
under [Installation](#installation)).

`npm run build:local` copies every library out of `node_modules` into
`app/webapp/lib/` and regenerates the BSP, which grows to about 6 MB — 1.3 MB of
it the barcode reader's WebAssembly module, 1.1 MB SunEditor with its 24
languages. The
files are the upstream ones byte-for-byte, with two exceptions. The first is
that **lines are wrapped**. A BSP page is stored as 255-character lines, so a minified bundle
would be chopped at character 256 — in the middle of an identifier as often as
not — and the file the system serves back would no longer be the file that went
in. `tools/wrap-lines.mjs` inserts newlines only where the JavaScript and CSS
grammars treat them as whitespace, and `npm test` proves it by re-parsing every
vendored library and comparing its syntax tree against the original's. A string
or the text of an untagged template literal that does not fit is continued with
a backslash, which leaves its value alone; an unquoted CSS `url(...)` that does
not fit — SunEditor inlines its cursors that way — is put in quotes first, which
CSS reads as the same value.

The second is that the trailing `//# sourceMappingURL=` comment is removed. The
`.map` files are developer tooling and are not vendored, so the pointer would
only make a browser with devtools open request a page the BSP does not have —
and a 404 next to a custom control is exactly the symptom someone loses an
afternoon to. Nothing else in the branch reaches outside the SAP system: the
libraries carry no absolute URL they load from (the http links in them are
banner comments and marked's autolink prefix), the stylesheets have no
`@import` and no `url()` other than inlined fonts and images, and none of them
opens an XHR, a `fetch` or a script tag of its own — with two exceptions that
are never taken. zxing-wasm's reader would fetch its WebAssembly module from
jsDelivr, but BarcodeScanner hands it the module as bytes instead. SunEditor
carries the endpoints of its embed and video plugins and an XHR for uploads,
but RichTextEditor registers neither plugin and sets no upload URL — an image
goes into the text as a data URI.

That module is the one binary among the libraries, and a BSP page is a text
object. So it travels the way Font Awesome's fonts do, as base64 inside a text
file: `lib/zxing_reader_wasm.js`, written by `tools/embed-wasm.mjs`, registers
it for the control, which decodes it — nothing is fetched at run time. `npm
test` decodes it back and compares it with the original byte for byte.

**UI5 itself is a separate question and lives outside this repository.**
abap2UI5 bootstraps from `https://sdk.openui5.org/...` unless told otherwise,
so an offline system also has to point `cs_config-src` at a local
distribution — see `z2ui5_cl_ui5_user_exit` in the framework. That is what serves
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
   on `local` without a second code path. A WebAssembly module the library
   compiles gets an entry of `"kind": "wasm"` of its own (see `zxingWasmBinary`)
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
| `app/webapp/cc/MapShapes.js` | the image-map geometry, split out so it can be unit-tested |
| `app/webapp/cc/BarcodeCollector.js` | what BarcodeScanner keeps between frames, split out likewise |
| `app/webapp/cc/LibUrls.js` | **generated**: where each control loads its library from |
| `app/webapp/lib/` | **generated, `local` branch only**: the vendored libraries |
| `tools/libs.json` | the third-party libraries — npm package, file, CDN URL |
| `tools/vendor.mjs` | writes `LibUrls.js`, and `app/webapp/lib/` with `--local` |
| `tools/wrap-lines.mjs` | breaks a library into lines a BSP page can carry |
| `tools/embed-wasm.mjs` | carries a WebAssembly module as base64 inside a script, for the local build |
| `tools/*.test.mjs` | unit tests — here, not under `app/`, where they would become BSP pages |
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

## Building something only your company needs?

This repository is for controls worth sharing. For a customer's **own**
frontend artefacts — an in-house reuse library, a corporate icon font, company
CSS — use
[abap2UI5-addons/custom-controls-customer](https://github.com/abap2UI5-addons/custom-controls-customer).
It is the same mechanism under a second reserved resourceRoot (`z2ui5_ccc`
instead of `z2ui5_cci`), so the two can be installed side by side and neither
needs a change to abap2UI5.

## Development

Run what CI runs:

```sh
npm ci
npm run check
```

CI runs abaplint against the abap2UI5 framework in both syntax versions,
syntax-checks every control, runs the line-wrapper tests, builds the `local`
variant, and fails if any generated artefact — the BSP under `src/01` or
`LibUrls.js` — has drifted from its source.

## Contributing

Issues and pull requests are welcome - see [CONTRIBUTING.md](CONTRIBUTING.md)
and, for the rules of the code, [AGENTS.md](AGENTS.md). Security issues:
[SECURITY.md](SECURITY.md).

## License

MIT - see [LICENSE](LICENSE).
