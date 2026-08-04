# abap2UI5 custom controls

**Custom controls for [abap2UI5](https://github.com/abap2UI5/abap2UI5), delivered
in their own BSP.** Nothing in here is part of the framework or of the
[abap2UI5-frontend](https://github.com/abap2UI5/frontend) BSP, so a new control
never needs a pull request against abap2UI5 and the framework carries no
JavaScript that only one customer uses.

Start `?app_start=z2ui5_cl_ccont_overview` for an overview of every control with a link
to its demo.

## The controls

### `SignaturePad` — `z2ui5cc/cc/SignaturePad`

A canvas the user signs on with mouse, finger or stylus. The stroke is handed
to the backend as a base64 PNG data URL — the same shape the framework's
`CameraPicture` uses for photos — so the signature ends up in a plain ABAP
string.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_signature_pad=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_01` |
| Properties | `value` (base64 PNG, bind two-way), `width`, `height`, `lineWidth` (float), `lineColor`, `editable` (boolean) |
| Events | `change` — fired when a stroke ends, carrying the new `value` |

Details worth knowing: the value is published on pointer-up only, never per
move event, because a full PNG per mouse move would flood the roundtrip
payload. Clearing is backend-driven — set the bound variable to empty and the
pad is blank after the next roundtrip. The backing store is sized to the device
pixel ratio so strokes stay sharp on retina and mobile screens, and
`touch-action: none` keeps a finger stroke from scrolling the page instead of
drawing.

Ported from the abap2UI5 framework branch for
[issue #1257](https://github.com/abap2UI5/abap2UI5/issues/1257). The one change
of substance: the dependency on `z2ui5/core/Lib` is gone. That module is
frontend-internal and not part of the public contract, so a control shipped
from its own BSP must not reach into it — a refactor there would break the
control silently.

### `ExportSpreadsheet` — `z2ui5cc/cc/ExportSpreadsheet`

A button that exports the rows a table is bound to as an `.xlsx` file. The
export runs in the browser and reads the table's binding, so the data never
makes a second trip to the backend and nothing has to be built in ABAP.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_spreadsheet=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_02` |
| Properties | `tableId`, `columns` (bind a `ty_t_column` table), `fileName`, `sheetName`, `text`, `icon`, `type`, `tooltip`, `enabled`, `status` (bind two-way) |
| Events | `exported` |

Needs SAPUI5 — `sap.ui.export` does not ship with OpenUI5, where the button
renders disabled and says so in its tooltip.

### `Validator` — `z2ui5cc/cc/Validator`

Checks a form against rules declared in ABAP, without a roundtrip: raise
`trigger` and the control marks every offending field and writes the verdict
back, so the same roundtrip that started the check brings the result home.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_validator=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_03` |
| Properties | `rules` (bind a `ty_t_rule` table), `trigger`, `valid` and `errors` (bind two-way) |
| Events | `validated` |

Rule fields: `field`, `type` (`number`/`integer`), `format` (`email`/`date`),
`pattern`, `required`, `minlength`, `maxlength`, `minimum`, `maximum`,
`message`. No external library — the constraints are evaluated in the control,
so it works on a system with no internet access.

### `ChartJs` — `z2ui5cc/cc/ChartJs`

A [Chart.js](https://www.chartjs.org) canvas driven by a bound ABAP structure.
`config` is the Chart.js configuration verbatim, so anything the Chart.js
documentation describes can be expressed from ABAP.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_chartjs=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_04` |
| Properties | `config` (bind a `ty_chart` structure), `width`, `height`, `plugins`, `libUrl` |
| Events | `elementPress` |

Changing the bound structure and calling `view_model_update( )` updates the
chart in place; only a changed chart type rebuilds it. `plugins` takes the
names from `z2ui5_cl_ccont_chartjs=>cs_plugin` — `datalabels`, `autocolors`,
`deferred`, `annotation`, `venn`, `wordcloud` — loads them in order after
Chart.js and registers them with it.

### `Barcode` — `z2ui5cc/cc/Barcode`

Barcodes and QR codes with [bwip-js](https://bwip-js.metafloor.com), which
speaks every symbology BWIPP knows. Nothing is rendered in ABAP and no image is
transferred.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_barcode=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_05` |
| Properties | `bcid`, `text`, `altText`, `scale`, `height`, `barWidth`, `includeText`, `textAlign`, `rotate`, `backgroundColor`, `options`, `renderAs` (`canvas`/`svg`), `libUrl` |
| Events | `error` |

`options` takes a raw BWIPP option string (`includetext guardwhitespace`,
`eclevel=M`), so a symbology-specific switch does not need a property here
first. `z2ui5_cl_ccont_barcode=>get_types( )` returns a handful of symbologies
with values that encode cleanly.

### `DriverJs` — `z2ui5cc/cc/DriverJs`

Product tours and spotlight highlights with [driver.js](https://driverjs.com).
The tour is described as data — one step per control, each with the text of its
popover — and `element` is the control id from the view, not a CSS selector.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_driverjs=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_06` |
| Properties | `config` (bind a `ty_s_config` structure), `highlight`, `mode`, `trigger`, `customCss`, `libUrl`, `cssUrl` |
| Events | `highlighted`, `done` |

Ids are resolved in the frontend against the view the control sits in, so a
step may point into a nested view or a dialog without ABAP knowing where the
control ended up.

### `FontAwesome` — `z2ui5cc/cc/FontAwesome`

One element in the view, and [Font Awesome](https://fontawesome.com) is
available two ways: as UI5 icons (`sap-icon://fa-solid/heart` in any icon
property) and as its own CSS classes (`class="fa-brands fa-github"`, including
the animations).

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_font_awesome=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_07` |
| Properties | `fontUri`, `collections`, `cssUrl` |

The UI5 IconPool needs more than the font file: it reads a metadata JSON next
to it that maps icon names to code points. `fontUri` therefore points at a
directory holding both, which is why its default is the prepared bundle rather
than Font Awesome's npm package.

### `AnimateCss` — `z2ui5cc/cc/AnimateCss`

Makes the [animate.css](https://animate.style) class names work on any control:
put `animate__animated animate__bounce` into a `class` attribute and it
animates.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_animate_css=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_08` |
| Properties | `duration`, `delay`, `repeat`, `cssUrl` |

The class names are constants on `z2ui5_cl_ccont_animate_css` —
`cs_base`, `cs_attention-*`, `cs_entrance-*`, `cs_exit-*`, `cs_modifier-*`.
`duration`/`delay`/`repeat` set the CSS variables animate.css reads, so they
retune every animation on the page at once.

### `ImageMapster` — `z2ui5cc/cc/ImageMapster`

An HTML image map that highlights the region under the mouse, keeps a
selection, writes it back into the model and raises a backend event with the
key of the region clicked — so a floor plan or a machine drawing becomes an
input control.

| | |
|---|---|
| ABAP builder | `z2ui5_cl_ccont_imagemapster=>render( )` |
| Demo | `?app_start=z2ui5_cl_ccont_sample_09` |
| Properties | `src`, `areas` (bind a `ty_t_area` table), `config`, `selectedKeys` (bind two-way), `width`, `height`, `autoResize`, `libUrl` |
| Events | `areaPress` |

Colours are hex **without** a leading `#`, the way ImageMapster wants them.

## Configuration structures

Five of the controls take a whole configuration structure as one property — a
Chart.js config, ImageMapster options, driver.js steps, the workbook columns,
the validation rules. Bind those with this library's JSON filter, and with the
camelCase mapper wherever the target library expects camelCase names:

```abap
config = client->_bind(
    val           = ms_chart
    custom_filter = NEW z2ui5_cl_ccont_json_filter( )
    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                        iv_first_json_upper = abap_false ) )
```

ABAP has no "unset" for a structure component: every field the app did not
touch still serializes, as `""`, `0` or `false`. Handing that to a JavaScript
library is not the same as leaving the option out — `borderWidth: 0` draws no
border. The filter drops the initial values so the library's own defaults
survive. The consequence to know about: a value that *is* meaningfully zero,
empty or false cannot be sent that way.

## Third-party libraries

Six controls wrap a library that is not part of UI5. None of it is vendored
into this repository — each control loads its library on first use, from a URL
its `libUrl` / `cssUrl` property carries as a default:

| Control | Library |
|---|---|
| `ChartJs` | Chart.js 4 and its plugins |
| `Barcode` | bwip-js 4 |
| `DriverJs` | driver.js 1 |
| `FontAwesome` | Font Awesome 6 webfonts + stylesheet |
| `AnimateCss` | animate.css 4 |
| `ImageMapster` | jquery.imagemapster 1.5 |

The defaults point at jsDelivr, so the demos run without any setup. **A system
whose browsers have no internet access must override them**: put the library
into this BSP (drop it under `app/webapp/lib/`, run `npm run app2bsp`) or into
your own, and pass its path — `z2ui5_cl_ccont_chartjs=>render( liburl = '...' )`.
Everything is loaded once per URL and cached, so several charts on one page
fetch Chart.js a single time.

This is a deliberate change from the addon repositories these controls came
from, where animate.css, driver.js and jquery.imagemapster were pasted into
ABAP classes as string literals — 4000 lines of CSS in one ABAP method — and
injected into every view that used them.

## How it plugs in

The abap2UI5 frontend reserves **one resourceRoot by convention** in its
`manifest.json`:

```jsonc
"sap.ui5": {
  "resourceRoots": { "z2ui5cc": "../z2ui5cc/" }
}
```

That is the whole integration. The path is a sibling of the frontend BSP, so
this repository's BSP — deployed as **`Z2UI5CC`** — is served from
`/sap/bc/ui5_ui5/sap/z2ui5cc/` and every module under `z2ui5cc/…` resolves
there, in the standalone BSP and inside the Fiori Launchpad alike.

Registration is lazy: on a system without the `Z2UI5CC` BSP nothing is ever
requested, so the entry costs nothing for everyone who has no custom controls.

In the **standalone HTTP service** the component base is the ICF node rather
than the frontend BSP, so that relative path would resolve next to
`/sap/bc/`. abap2UI5 registers the absolute BSP path there instead, from
`z2ui5_cl_http_handler=>_http_get`. Nothing to configure either way.

The ABAP side needs no framework support at all — `z2ui5_cl_ai_xml` declares
arbitrary XML namespaces, so a foreign control needs neither an entry in the
framework's namespace map nor a method in `z2ui5_cl_xml_view_cc`:

```abap
DATA(view) = z2ui5_cl_ai_xml=>factory( ).
DATA(root) = view->open( n = `View` ns = `mvc`
    )->a( n = `xmlns`     v = `sap.m`
    )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).

z2ui5_cl_ccont=>xmlns( root ).          " declares xmlns:z2ui5cc once

z2ui5_cl_ccont_signature_pad=>render( view   = box
                                   value  = client->_bind( signature )
                                   height = `200px`
                                   change = client->_event( `SIGNED` ) ).
```

From there a control behaves like any built-in one: properties bind, values are
written back into the model, and events arrive in `on_event`.

## Layout

| Path | What it is |
|---|---|
| `app/webapp/cc/*.js` | the controls — plain UI5, the single source of truth |
| `app/webapp/cc/Util.js` | the loader / id-resolution helpers the controls share |
| `app/webapp/index.html` | placeholder start page; the BSP has no UI of its own |
| `tools/app2bsp.mjs` | generates the abapGit BSP artefacts from `app/webapp` |
| `src/01/z2ui5cc.wapa.*` | **generated**: BSP pages, page directory, path mapping |
| `src/01/z2ui5cc *.sicf.xml` | **generated**: the ICF nodes the BSP is served from |
| `src/z2ui5_cl_ccont.clas.abap` | library identity: XML namespace, `xmlns( )` and `leaf( )` |
| `src/z2ui5_cl_ccont_json_filter.clas.abap` | drops initial values out of a bound config structure |
| `src/z2ui5_cl_ccont_<control>.clas.abap` | one view builder per control |
| `src/00/z2ui5_cl_ccont_overview.clas.abap` | the front door that lists every control |
| `src/00/z2ui5_cl_ccont_sample_NN.clas.abap` | one sample app per control |

BSP pages are written space-padded to 255-character lines, the same format the
frontend repo's `app2bsp` uses, so a pull into SAP and a re-serialize produce no
diff.

**File names under `app/webapp` become BSP page names, and SAP validates
those.** Keep to at most one directory level and to letters, digits, `_` and
`.` — the shape the frontend BSP has always shipped. `app2bsp` refuses anything
else, because the alternative is finding out on import:

```
CL_O2_API_PAGES=>CREATE_NEW_PAGE sy-subrc=2 (invalid_name)
page='lib/imagemap-editor/bridge.js' ...
Import of object Z2UI5CC failed
```

That is a real failure this repository produced — a two-level path with a
hyphen in it. Which of the two SAP objected to was never established, so
neither is used.

## Install

1. Install this repository with abapGit — it deploys the ABAP classes, the BSP
   application `Z2UI5CC` and the two ICF nodes it is served from
   (`/sap/bc/ui5_ui5/sap/z2ui5cc/` and `/sap/bc/bsp/sap/z2ui5cc/`).
2. Check the BSP answers: `/sap/bc/ui5_ui5/sap/z2ui5cc/cc/SignaturePad.js` must
   return the JavaScript. `ICF Node NOT found!` means the SICF objects were not
   deserialized — activate the node in `SICF` and re-check.
3. Check the frontend resolves it: `sap.ui.require.toUrl("z2ui5cc/cc/SignaturePad.js")`
   in the browser console must return the BSP path, not `resources/…`. If it
   returns `resources/…`, the frontend BSP predates the reserved resourceRoot.
4. Start `?app_start=z2ui5_cl_ccont_overview`.

Those two checks separate a BSP problem from a frontend-manifest problem, which
look identical from inside the app.

## Adding a control

1. write `app/webapp/cc/<Name>.js`, extending `sap.ui.core.Control` under
   `z2ui5cc.cc.<Name>`, with no dependency on `z2ui5/…` modules
2. `npm run app2bsp` — regenerates the BSP artefacts under `src/`
3. add a `render( )` builder class `z2ui5_cl_ccont_<name>`
4. add a demo app and a row in `z2ui5_cl_ccont_overview=>model_init( )`
5. document it under "The controls" above

## Where these came from

Eight of the controls replace two addon repositories that shipped custom
controls the old way — the JavaScript built as ABAP string literals and
injected into each view through `_cc_plain_xml`:

| Repository | Ported to |
|---|---|
| [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls) | `ExportSpreadsheet`, `Validator` |
| [abap2UI5-addons/js-libraries](https://github.com/abap2UI5-addons/js-libraries) | `ChartJs`, `Barcode`, `DriverJs`, `FontAwesome`, `AnimateCss`, `ImageMapster` |

Each control's JS file names the class it came from and lists what changed.

### Already in the framework — not ported

Two of the addons' controls have a maintained counterpart in abap2UI5 itself.
This repository is for controls the framework does **not** carry, so they stay
where they are:

- **Favicon** → `z2ui5.cc.Favicon`, built with
  `z2ui5_cl_xml_view_cc=>favicon( )`.
- **Messaging** / **MessageManager** → `z2ui5.cc.MessageManager`, built with
  `z2ui5_cl_xml_view_cc=>message_manager( )`. It reconciles by a stable message
  key, so a roundtrip cannot duplicate the list, and resolves the messaging
  facade through `z2ui5/core/Lib` — which keeps it working below UI5 1.118,
  where `sap/ui/core/Messaging` does not exist yet.

### Not carried over

- **the ImageMapster editor** — a tool for drawing image-map coordinates, held
  in the addon as three ABAP methods with ~3000 lines of XML-escaped HTML, CSS
  and JavaScript. It is an authoring tool rather than a control, and what the
  user drew never reached ABAP anyway: it went into the browser's
  `localStorage`, or into a text box to copy out by hand.

## Checks

`abaplint` runs against the abap2UI5 framework as a dependency, every control is
syntax-checked, and a gate regenerates the BSP artefacts and fails on drift — a
stale page would otherwise deploy old JavaScript unnoticed.

The abap2UI5-linter's headless view render is deliberately **not** wired up: it
validates views against the UI5 metadata snapshot, which by design knows nothing
about `z2ui5cc.cc.*`.
