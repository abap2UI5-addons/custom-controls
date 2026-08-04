# abap2UI5 custom controls

Nine ready-to-use custom controls for
[abap2UI5](https://github.com/abap2UI5/abap2UI5) — signature pad, charts,
barcodes, Excel export, form validation, product tours, Font Awesome, animations
and clickable image maps.

They ship in their **own BSP** (`Z2UI5CC`), not inside the framework. Install this
repository and the controls are there; nothing in abap2UI5 or in the frontend BSP
has to change, and no pull request against the framework is needed to add one.

## Install

1. Install this repository with abapGit. It brings the ABAP classes, the BSP
   application `Z2UI5CC` and the two ICF nodes it is served from.
2. Start **`?app_start=z2ui5_cl_ccont_sample_00`** — the overview app lists every
   control and opens its sample.

Requires abap2UI5 with the reserved resourceRoot `z2ui5cc` in the frontend
manifest (see [Troubleshooting](#troubleshooting) if a control stays blank).

## Using a control

Every control has a builder class with one `render( )` method. Declare the
namespace once per view, then add controls like any other:

```abap
DATA(view) = z2ui5_cl_ai_xml=>factory( ).

DATA(root) = view->open( n  = `View`
                         ns = `mvc`
    )->a( n = `xmlns`     v = `sap.m`
    )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).

z2ui5_cl_ccont=>xmlns( root ).           " declares xmlns:z2ui5cc - once per view

DATA(page) = root->open( `Page`
    )->a( n = `title` v = `Signature` ).

z2ui5_cl_ccont_signature_pad=>render(
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
| SignaturePad | sign with mouse, finger or stylus → base64 PNG | `z2ui5_cl_ccont_signature_pad` | `..._sample_01` |
| ExportSpreadsheet | export a table's rows as `.xlsx`, in the browser | `z2ui5_cl_ccont_spreadsheet` | `..._sample_02` |
| Validator | check a form against ABAP rules without a roundtrip | `z2ui5_cl_ccont_validator` | `..._sample_03` |
| ChartJs | [Chart.js](https://www.chartjs.org) charts from a bound structure | `z2ui5_cl_ccont_chartjs` | `..._sample_04` |
| Barcode | barcodes and QR codes with [bwip-js](https://bwip-js.metafloor.com) | `z2ui5_cl_ccont_barcode` | `..._sample_05` |
| DriverJs | product tours and spotlights with [driver.js](https://driverjs.com) | `z2ui5_cl_ccont_driverjs` | `..._sample_06` |
| FontAwesome | [Font Awesome](https://fontawesome.com) as UI5 icons and CSS classes | `z2ui5_cl_ccont_font_awesome` | `..._sample_07` |
| AnimateCss | [animate.css](https://animate.style) class names on any control | `z2ui5_cl_ccont_animate_css` | `..._sample_08` |
| ImageMapster | clickable, highlighting regions on an image | `z2ui5_cl_ccont_imagemapster` | `..._sample_09` |

Sample classes are `z2ui5_cl_ccont_sample_NN` — start any of them directly with
`?app_start=…`, or browse them from `z2ui5_cl_ccont_sample_00`.

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

<img width="769" height="666" alt="image" src="https://github.com/user-attachments/assets/16967120-1728-4bb6-b65f-64e9e4ee1555" />

### Validator

`rules` (a `ty_t_rule` table), `trigger`, `valid`, `errors` · event `validated`.

Rule fields: `field`, `type` (`number`/`integer`), `format` (`email`/`date`),
`pattern`, `required`, `minlength`, `maxlength`, `minimum`, `maximum`,
`message`. No external library — works without internet access.

<img width="763" height="629" alt="image" src="https://github.com/user-attachments/assets/cb361379-6255-4c4b-a719-0ddc46914fea" />


### ChartJs

`config` (a `ty_chart` structure), `width`, `height`, `plugins`, `liburl` ·
event `elementpress`.

`config` is the Chart.js configuration verbatim, so anything the Chart.js docs
describe works from ABAP. Change the structure and call `view_model_update( )` to
update in place. `plugins` takes the names from
`z2ui5_cl_ccont_chartjs=>cs_plugin` (`datalabels`, `autocolors`, `deferred`,
`annotation`, `venn`, `wordcloud`).

<img width="1248" height="630" alt="image" src="https://github.com/user-attachments/assets/7b20eb12-1823-4b25-a3ad-0dfcab95077a" />

### Barcode

`bcid`, `text`, `alttext`, `scale`, `height`, `includetext`, `textalign`,
`rotate`, `backgroundcolor`, `options`, `renderas` (`canvas`/`svg`), `liburl` ·
event `error`.

`z2ui5_cl_ccont_barcode=>get_types( )` returns a handful of symbologies with
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
animates. The class names are constants on `z2ui5_cl_ccont_animate_css`
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

## Two things to know

### Binding a configuration structure

Five controls take a whole configuration as one property (Chart.js config,
driver.js steps, ImageMapster options, workbook columns, validation rules). Bind
those with this library's JSON filter — and with the camelCase mapper where the
target library expects camelCase names:

```abap
config = client->_bind(
    val           = ms_chart
    custom_filter = NEW z2ui5_cl_ccont_json_filter( )
    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                        iv_first_json_upper = abap_false ) )
```

ABAP has no "unset" for a structure component: fields you never touched still
serialize as `""`, `0` or `false`, and `borderWidth: 0` draws no border. The
filter drops initial values so the library's own defaults survive. The flip side:
a value that *is* meaningfully zero, empty or false cannot be sent this way.



### Third-party libraries and systems without internet

Six controls wrap a library that is not part of UI5 — Chart.js 4, bwip-js 4,
driver.js 1, Font Awesome 6, animate.css 4, jquery.imagemapster 1.5. Nothing is
vendored here; each control loads its library on first use from the URL in its
`liburl` / `cssurl` property, which defaults to jsDelivr. Loading is cached per
URL, so ten charts on a page fetch Chart.js once.

**If the browsers in your system have no internet access, override those URLs.**
Put the library into a BSP of your own (or into this one: drop it under
`app/webapp/`, run `npm run app2bsp`) and pass the path:

```abap
z2ui5_cl_ccont_chartjs=>render( view = page config = … liburl = `/sap/bc/ui5_ui5/sap/z2ui5cc/chart.umd.js` ).
```

## Troubleshooting

| Symptom | Cause |
|---|---|
| `ICF Node NOT found!` | the SICF nodes were not activated — activate `z2ui5cc` in transaction `SICF` |
| control stays blank, 404 on `cc/<Name>.js` | check `/sap/bc/ui5_ui5/sap/z2ui5cc/cc/SignaturePad.js` returns JavaScript |
| control stays blank, request goes to `resources/…` | your abap2UI5 frontend predates the reserved resourceRoot `z2ui5cc`; update it |

In the browser console, `sap.ui.require.toUrl("z2ui5cc/cc/SignaturePad.js")` must
return the BSP path. That separates a BSP problem from a frontend problem, which
look identical from inside the app.

## Adding your own control

1. write `app/webapp/cc/<Name>.js`, extending `sap.ui.core.Control` under
   `z2ui5cc.cc.<Name>`, with no dependency on `z2ui5/…` modules
2. run `npm run app2bsp` — regenerates the BSP artefacts under `src/01`
3. add a builder class `z2ui5_cl_ccont_<name>` next to the others
4. add a sample and a row in `z2ui5_cl_ccont_sample_00=>model_init( )`

File names under `app/webapp` become BSP page names and SAP validates them: at
most one directory level, and letters, digits, `_` and `.` only. `app2bsp`
refuses anything else — otherwise you find out on import, as
`CREATE_NEW_PAGE sy-subrc=2 (invalid_name)`.

## Layout

| Path | What it is |
|---|---|
| `app/webapp/cc/*.js` | the controls — plain UI5, the single source of truth |
| `tools/app2bsp.mjs` | generates the abapGit BSP artefacts from `app/webapp` |
| `src/z2ui5_cl_ccont*.clas.abap` | the library and one view builder per control |
| `src/00/` | the overview app and the samples |
| `src/01/` | **generated**: the `Z2UI5CC` BSP and its ICF nodes |

CI runs abaplint against the abap2UI5 framework, syntax-checks every control and
fails if the generated BSP has drifted from `app/webapp`.

These controls replace the
[abap2UI5-addons/js-libraries](https://github.com/abap2UI5-addons/js-libraries)
and
[abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
repositories, which shipped the same JavaScript as ABAP string literals injected
into every view. Each control's JS file names the class it came from and lists
what changed. Favicon and MessageManager were not ported — abap2UI5 carries them
itself (`z2ui5_cl_xml_view_cc=>favicon( )` / `=>message_manager( )`).
