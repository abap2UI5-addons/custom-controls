# test-cc

**abap2UI5 custom controls delivered in their own BSP** — nothing in here is
part of the [abap2UI5](https://github.com/abap2UI5/abap2UI5) framework or of
the [abap2UI5-frontend](https://github.com/abap2UI5/frontend) BSP.

It exists to answer one question: *can custom controls be shipped separately,
so the framework stays small and a new control does not need a pull request
against abap2UI5?*

## How it works

The abap2UI5 frontend reserves **one resourceRoot by convention** in its
`manifest.json`:

```jsonc
"sap.ui5": {
  "resourceRoots": { "z2ui5cc": "../z2ui5cc/" }
}
```

That is the whole integration. The path is a sibling of the frontend BSP, so a
control BSP deployed as **`Z2UI5CC`** is served from
`/sap/bc/ui5_ui5/sap/z2ui5cc/` and every module under `z2ui5cc/…` resolves
there — in the standalone BSP and inside the Fiori Launchpad alike.

Registration is lazy: on a system without the `Z2UI5CC` BSP nothing is ever
requested, so the entry costs nothing for everyone who has no custom controls.

The ABAP side needs no framework support either. `z2ui5_cl_ai_xml` declares
arbitrary namespaces, so a foreign control needs neither an entry in the
framework's namespace map nor a method in `z2ui5_cl_xml_view_cc`:

```abap
view->a( n = `xmlns:z2ui5cc` v = `z2ui5cc.cc` ).      " once, on the root
zcl_z2ui5cc_counter=>render( view  = box
                             text  = client->_bind( label )
                             count = client->_bind( counter )
                             press = client->_event( `COUNTER_PRESSED` ) ).
```

From there the control behaves like any built-in one: properties bind, the
control writes `count` back into the model, and `press` arrives in `on_event`
as a normal abap2UI5 event.

## What is in here

| Path | What it is |
|---|---|
| `app/webapp/cc/Counter.js` | the control — plain UI5, the single source of truth |
| `app/webapp/index.html` | placeholder start page; the BSP has no UI of its own |
| `src/z2ui5cc.wapa.*` | **generated** BSP artefacts (`npm run app2bsp`) |
| `src/zcl_z2ui5cc_counter.clas.abap` | the ABAP half: the view builder |
| `src/zcl_z2ui5cc_demo.clas.abap` | demo app — `?app_start=zcl_z2ui5cc_demo` |

## Install

1. Install this repository with abapGit — it deploys the ABAP classes **and**
   the BSP application `Z2UI5CC`.
2. Make sure the abap2UI5 frontend BSP declares the `z2ui5cc` resourceRoot
   (see above).
3. Start `?app_start=zcl_z2ui5cc_demo`.

## Verified

Checked headless against the transpiled abap2UI5 backend (`ai-demokit`'s
`npm run node:build` + `node:serve`), with the `Z2UI5CC` BSP stood in for by
serving `app/webapp/` at the resolved resourceRoot URL:

- the manifest entry drives module resolution — UI5 requests
  `cc/Counter.js` from the registered root, not from the framework
- `<z2ui5cc:Counter/>` resolves and renders (foreign XML namespace)
- `text` / `count` arrive from the ABAP model
- clicking raises `count`, writes it back into the model, and ABAP sees the new
  value on the next roundtrip (two-way binding)
- `press` reaches `on_event`; log and `Reset` roundtrips behave normally

## Scope of the convention

One reserved name, one control BSP. That covers the common case — a customer
collects their controls in `Z2UI5CC` — and costs no protocol and no backend
code.

It does **not** cover several independently deployed control BSPs, or control
BSPs under a name the customer chooses. That needs the loader configuration to
travel over the abap2UI5 protocol (a `t_resource_roots` in
`ty_s_next_frontend`, applied in the frontend's `Server.js` via
`sap.ui.loader.config({ paths })` before `XMLView.create`) — an additive change
that can be layered on top of this convention later without breaking it.

Note also that the convention is a **frontend-BSP** mechanism. In the
standalone HTTP-service setup abap2UI5 generates `index.html` itself and there
is no sibling BSP path; there the `cs_config-custom_js` exit field is the way
to get control JavaScript into the shell.

## Adding a control

1. write `app/webapp/cc/<Name>.js`
2. `npm run app2bsp` — regenerates the BSP artefacts under `src/`
3. add a `render( )` builder class next to `zcl_z2ui5cc_counter`

## Checks

`abaplint.jsonc` runs against the abap2UI5 framework as a dependency. The
abap2UI5-linter's headless render is deliberately **not** wired up: it renders
views against the UI5 metadata snapshot, which by design knows nothing about
`z2ui5cc.cc.Counter`.
