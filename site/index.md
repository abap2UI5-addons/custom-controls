---
layout: home

hero:
  name: "Custom Controls"
  text: "Thirteen ready-to-use custom controls, one builder class each."
  image:
    src: /logo.svg
    alt: abap2UI5 addons
  actions:
    - theme: brand
      text: Get started
      link: /guide
    - theme: alt
      text: GitHub
      link: https://github.com/abap2UI5-addons/custom-controls
    - theme: alt
      text: All addons
      link: https://abap2ui5-addons.github.io/

features:
  - title: "SignaturePad, Validator, ExportSpreadsheet, CodeEditor without external libraries"
  - title: "ChartJs, Barcode, DriverJs, FontAwesome, AnimateCss, Markdown wrap well-known JS libraries"
  - title: "BarcodeScanner reads every barcode in the picture at once, or counts identical labels"
  - title: "RichTextEditor (SunEditor) works on OpenUI5 too, with DOMPurify sanitizing"
  - title: "Branch main loads libraries from jsDelivr, branch local vendors them for offline systems"
  - title: "One builder class per control, one sample app per control"
---

## What it does

A library of thirteen custom controls for abap2UI5: signature pad, Chart.js charts, barcodes, a camera scanner that reads several barcodes at once, Excel export, form validation, product tours, Font Awesome, animations, clickable image maps, Markdown, a code editor and a rich text editor. The controls ship in their own BSP Z2UI5_CCI, so nothing in abap2UI5 or its frontend has to change. Each control is used from ABAP through a builder class with one render( ) method; properties bind, values come back into ABAP variables and events arrive in the app like for any built-in control. The overview app z2ui5_cl_cci_sample_00 lists every control with its sample.

## Requirements

- Standard ABAP 7.50 or higher
- abap2UI5 with the reserved resourceRoot z2ui5_cci in the frontend manifest
- ExportSpreadsheet needs SAPUI5 (sap.ui.export is missing under OpenUI5)
- Branch main needs browser access to jsDelivr; branch local does not
- BarcodeScanner needs https and 'wasm-unsafe-eval' in the CSP script-src

## Installation

With [abapGit](https://abapgit.org), from [the repository](https://github.com/abap2UI5-addons/custom-controls):

- Install with abapGit in this order: abap2UI5, then this repository
- Branch main: the sources with libraries from jsDelivr (default); branch local: the same with every library vendored into the BSP, for browsers without internet access
- Brings the ABAP classes, the BSP application Z2UI5_CCI and the two ICF nodes it is served from
- Start ?app_start=z2ui5_cl_cci_sample_00; if it says ICF Node NOT found, activate the node z2ui5_cci in SICF
- Bind configuration structures with omit_initial = abap_true and the camelCase mapper where the library expects it

The [Guide](/guide) has every step.

## A first app

```abap
z2ui5_cl_cci_rich_text_editor=>render(
    view   = page
    value  = client->_bind( mv_html )
    height = `20rem`
    change = client->_event( `TEXT_CHANGED` ) ).
```

## Links

- [abap2UI5-addons/custom-controls-customer](https://github.com/abap2UI5-addons/custom-controls-customer)
- [abap2UI5-addons/js-libraries-obsolet (replaced)](https://github.com/abap2UI5-addons/js-libraries-obsolet)
- [abap2UI5-addons/custom-controls-obsolet (replaced)](https://github.com/abap2UI5-addons/custom-controls-obsolet)
- [Chart.js](https://www.chartjs.org)
- [zxing-wasm](https://github.com/Sec-ant/zxing-wasm)
- [SunEditor](https://github.com/JiHong88/SunEditor)
- [The repository](https://github.com/abap2UI5-addons/custom-controls) - issues and pull requests welcome
