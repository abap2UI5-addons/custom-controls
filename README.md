# abap2UI5 custom controls

**Custom controls for [abap2UI5](https://github.com/abap2UI5/abap2UI5), delivered
in their own BSP.** Nothing in here is part of the framework or of the
[abap2UI5-frontend](https://github.com/abap2UI5/frontend) BSP, so a new control
never needs a pull request against abap2UI5 and the framework carries no
JavaScript that only one customer uses.

Start `?app_start=zcl_z2ui5cc_demo` for an overview of every control with a link
to its demo.

## The controls

### `Counter` — `z2ui5cc/cc/Counter`

A click target that raises a counter and writes it back into the model. It is
the smallest possible control that still exercises every integration path, and
exists mainly as the reference and the installation check.

| | |
|---|---|
| ABAP builder | `zcl_z2ui5cc_counter=>render( )` |
| Demo | `?app_start=zcl_z2ui5cc_demo_counter` |
| Properties | `text` (string), `count` (int, bind two-way), `enabled` (boolean) |
| Events | `press` — fired after the click, with the raised `count` |

Clicking raises `count` through `setProperty`, so a two-way binding carries the
new value to ABAP with the roundtrip the `press` event triggers. The demo
compares the count the control reported against the number of roundtrips it
handled itself and shows `MISMATCH` if they drift apart.

### `SignaturePad` — `z2ui5cc/cc/SignaturePad`

A canvas the user signs on with mouse, finger or stylus. The stroke is handed
to the backend as a base64 PNG data URL — the same shape the framework's
`CameraPicture` uses for photos — so the signature ends up in a plain ABAP
string.

| | |
|---|---|
| ABAP builder | `zcl_z2ui5cc_signature_pad=>render( )` |
| Demo | `?app_start=zcl_z2ui5cc_demo_signature` |
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

zcl_z2ui5cc=>xmlns( root ).          " declares xmlns:z2ui5cc once

zcl_z2ui5cc_counter=>render( view  = box
                             text  = client->_bind( label )
                             count = client->_bind( counter )
                             press = client->_event( `COUNTER_PRESSED` ) ).
```

From there a control behaves like any built-in one: properties bind, values are
written back into the model, and events arrive in `on_event`.

## Layout

| Path | What it is |
|---|---|
| `app/webapp/cc/*.js` | the controls — plain UI5, the single source of truth |
| `app/webapp/index.html` | placeholder start page; the BSP has no UI of its own |
| `tools/app2bsp.mjs` | generates the abapGit BSP artefacts from `app/webapp` |
| `src/z2ui5cc.wapa.*` | **generated**: BSP pages, page directory, path mapping |
| `src/z2ui5cc *.sicf.xml` | **generated**: the ICF nodes the BSP is served from |
| `src/zcl_z2ui5cc.clas.abap` | library identity: XML namespace + `xmlns( )` helper |
| `src/zcl_z2ui5cc_<control>.clas.abap` | one view builder per control |
| `src/zcl_z2ui5cc_demo*.clas.abap` | the overview app and one demo per control |

BSP pages are written space-padded to 255-character lines, the same format the
frontend repo's `app2bsp` uses, so a pull into SAP and a re-serialize produce no
diff.

## Install

1. Install this repository with abapGit — it deploys the ABAP classes, the BSP
   application `Z2UI5CC` and the two ICF nodes it is served from
   (`/sap/bc/ui5_ui5/sap/z2ui5cc/` and `/sap/bc/bsp/sap/z2ui5cc/`).
2. Check the BSP answers: `/sap/bc/ui5_ui5/sap/z2ui5cc/cc/Counter.js` must
   return the JavaScript. `ICF Node NOT found!` means the SICF objects were not
   deserialized — activate the node in `SICF` and re-check.
3. Check the frontend resolves it: `sap.ui.require.toUrl("z2ui5cc/cc/Counter.js")`
   in the browser console must return the BSP path, not `resources/…`. If it
   returns `resources/…`, the frontend BSP predates the reserved resourceRoot.
4. Start `?app_start=zcl_z2ui5cc_demo`.

Those two checks separate a BSP problem from a frontend-manifest problem, which
look identical from inside the app.

## Adding a control

1. write `app/webapp/cc/<Name>.js`, extending `sap.ui.core.Control` under
   `z2ui5cc.cc.<Name>`, with no dependency on `z2ui5/…` modules
2. `npm run app2bsp` — regenerates the BSP artefacts under `src/`
3. add a `render( )` builder class `zcl_z2ui5cc_<name>`
4. add a demo app and a row in `zcl_z2ui5cc_demo=>model_init( )`
5. document it under "The controls" above

## Checks

`abaplint` runs against the abap2UI5 framework as a dependency, every control is
syntax-checked, and a gate regenerates the BSP artefacts and fails on drift — a
stale page would otherwise deploy old JavaScript unnoticed.

The abap2UI5-linter's headless view render is deliberately **not** wired up: it
validates views against the UI5 metadata snapshot, which by design knows nothing
about `z2ui5cc.cc.*`.
