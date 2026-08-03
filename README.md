# test-cc

A **custom control for abap2UI5 that lives in its own repository** — nothing of
it is part of the [abap2UI5](https://github.com/abap2UI5/abap2UI5) framework or
of the [abap2UI5-frontend](https://github.com/abap2UI5/frontend) BSP.

It exists to answer one question: *can custom controls be delivered separately,
so the framework stays small and a new control does not need a pull request
against abap2UI5?*

## What is in here

| Path | What it is |
|---|---|
| `app/cc/Counter.js` | the control — plain UI5, the single source of truth |
| `src/zcl_testcc_counter_js.clas.abap` | **generated** from it by `npm run js2abap` |
| `src/zcl_testcc_counter.clas.abap` | the ABAP half: view builder + JS accessor |
| `src/zcl_testcc_bootstrap.clas.abap` | collects the JS of all controls |
| `src/zcl_testcc_exit.clas.abap` | hands it to abap2UI5 via `z2ui5_if_exit` |
| `src/zcl_testcc_demo.clas.abap` | demo app — `?app_start=zcl_testcc_demo` |

Install with abapGit, then start `?app_start=zcl_testcc_demo`.

## How it plugs in

Two public extension points, no framework change:

**1. The JavaScript reaches the browser through `z2ui5_if_exit`.**
`cs_config-custom_js` is appended to the `z2ui5/Component.js` entry of the
frontend preload (see `z2ui5_cl_app_preload=>get`), so it runs before the first
XML view is built. Every control declares itself with an **explicit module
name**:

```js
sap.ui.define("testcc/cc/Counter", ["sap/ui/core/Control"], (Control) => { ... });
```

The named define registers the module in the ui5loader, so the view resolves it
from the registry — no HTTP request, no `resourceRoot`, no second BSP.

**2. The XML element comes from this repo's own view builder.**
`z2ui5_cl_ai_xml` declares arbitrary namespaces, so a foreign control needs no
entry in the framework's namespace map and no method in
`z2ui5_cl_xml_view_cc`:

```abap
view->a( n = `xmlns:testcc` v = `testcc.cc` ).       " once, on the root
zcl_testcc_counter=>render( view  = box
                            text  = client->_bind( label )
                            count = client->_bind( counter )
                            press = client->_event( `COUNTER_PRESSED` ) ).
```

From there the control behaves like any built-in one: properties bind, the
control writes `count` back into the model, and `press` arrives in
`on_event` as a normal abap2UI5 event.

## Verified

Checked headless against the transpiled abap2UI5 backend
(`ai-demokit`'s `npm run node:build` + `node:serve`, `?app_start=zcl_testcc_demo`):

- `<testcc:Counter/>` resolves and renders — the foreign module namespace works
- `text` / `count` arrive from the ABAP model
- clicking raises `count`, writes it back into the model, and ABAP sees the new
  value on the next roundtrip (two-way binding)
- `press` reaches `on_event` and the log/`Reset` roundtrips behave normally

## Known limitation — this only covers the HTTP-service setup

`custom_js` is consumed in `z2ui5_cl_http_handler=>_http_get`, i.e. in the
**standalone HTTP-service mode**, where abap2UI5 generates `index.html` itself.

It does **not** reach a system that runs the abap2UI5-frontend **BSP** (the
common production setup) or the Fiori Launchpad: there the shell comes from the
BSP's static `index.html` — or, in the FLP, from the app descriptor — and the
backend never gets to touch the bootstrap.

Closing that gap needs one additive change in abap2UI5, not in this repo: carry
the loader configuration over the **protocol** instead of the bootstrap —
a `t_resource_roots` (or the JS bundle itself) in `ty_s_next_frontend`, applied
in the frontend's `Server.js` with `sap.ui.loader.config({ paths })` before
`XMLView.create`. That works identically in all three modes and would let this
repo ship its controls as its own BSP instead of as ABAP string constants.

## Adding a control

1. write `app/cc/<Name>.js` — `sap.ui.define("testcc/cc/<Name>", …)` with the
   explicit module name
2. `npm run js2abap` — regenerates the ABAP holder class
3. add a `render( )` builder class next to `zcl_testcc_counter`
4. add one line to `zcl_testcc_bootstrap=>get_js( )`

## Caveat: only one abap2UI5 exit per system

`z2ui5_cl_exit=>get_user_exit_class( )` collects all implementations of
`Z2UI5_IF_EXIT`, sorts them by name and takes the first. If your system already
has an exit, **delete `ZCL_TESTCC_EXIT`** after the pull and call the bootstrap
from your own exit instead:

```abap
METHOD z2ui5_if_exit~set_config_http_get.
  cs_config-custom_js = zcl_testcc_bootstrap=>get_js( ).
ENDMETHOD.
```

## Checks

`abaplint.jsonc` runs against the abap2UI5 framework as a dependency. The
abap2UI5-linter's headless render is deliberately **not** wired up: it renders
views against the UI5 metadata snapshot, which by design knows nothing about
`testcc.cc.Counter`.
