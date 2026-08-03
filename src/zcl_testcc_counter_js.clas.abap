* =====================================================================
* GENERATED FILE - DO NOT EDIT
* Source: app/cc/counter.js
* Regenerate with 'npm run js2abap' after changing the JavaScript.
* =====================================================================
CLASS zcl_testcc_counter_js DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS get
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_testcc_counter_js IMPLEMENTATION.

  METHOD get.

    result = `// testcc.cc.Counter - a test custom control that lives OUTSIDE abap2UI5.` && |\n| &&
             `//` && |\n| &&
             `// The point of this control is not what it does, but where it comes from: no` && |\n| &&
             `// file of it is part of the abap2UI5 framework or the abap2UI5-frontend BSP.` && |\n| &&
             `// It is registered under its own module namespace "testcc" and reaches the` && |\n| &&
             `// browser through the public z2ui5_if_exit extension point (see` && |\n| &&
             `// ZCL_TESTCC_EXIT), so a new custom control never needs a pull request` && |\n| &&
             `// against abap2UI5.` && |\n| &&
             `//` && |\n| &&
             `// It deliberately exercises all three integration paths a real custom control` && |\n| &&
             `// needs from the framework:` && |\n| &&
             `//   1. property binding      - text/count are bound from the ABAP model` && |\n| &&
             `//   2. write-back            - clicking raises count and pushes it INTO the` && |\n| &&
             `//                              model, so the new value reaches ABAP with the` && |\n| &&
             `//                              next roundtrip (two-way binding)` && |\n| &&
             `//   3. event dispatch        - press is wired to an abap2UI5 backend event` && |\n| &&
             `//` && |\n| &&
             `// The explicit module name in sap.ui.define() is what makes this work without` && |\n| &&
             `// a second BSP: the module registers itself in the ui5loader at bootstrap, so` && |\n| &&
             `// the XML view resolves <testcc:Counter/> from the registry instead of firing` && |\n| &&
             `// an HTTP request. Registering a resourceRoot for "testcc" and serving this` && |\n| &&
             `// file from its own BSP is the other half of the story - see README.md.` && |\n| &&
             `sap.ui.define("testcc/cc/Counter", ["sap/ui/core/Control"], (Control) => {` && |\n| &&
             `  "use strict";` && |\n| &&
             `` && |\n| &&
             `  return Control.extend("testcc.cc.Counter", {` && |\n| &&
             `    metadata: {` && |\n| &&
             `      properties: {` && |\n| &&
             `        text: { type: "string", defaultValue: "" },` && |\n| &&
             `        count: { type: "int", defaultValue: 0 },` && |\n| &&
             `        enabled: { type: "boolean", defaultValue: true },` && |\n| &&
             `      },` && |\n| &&
             `      events: {` && |\n| &&
             `        press: {` && |\n| &&
             `          parameters: {` && |\n| &&
             `            count: { type: "int" },` && |\n| &&
             `          },` && |\n| &&
             `        },` && |\n| &&
             `      },` && |\n| &&
             `    },` && |\n| &&
             `` && |\n| &&
             `    // UI5 routes browser events to on<event> handlers on the control.` && |\n| &&
             `    onclick() {` && |\n| &&
             `      if (!this.getEnabled()) return;` && |\n| &&
             `      // setCount goes through setProperty, so a two-way bound count is` && |\n| &&
             `      // written back into the JSON model before the roundtrip below is` && |\n| &&
             `      // assembled - this is the write-back path the demo app verifies.` && |\n| &&
             `      this.setCount(this.getCount() + 1);` && |\n| &&
             `      this.firePress({ count: this.getCount() });` && |\n| &&
             `    },` && |\n| &&
             `` && |\n| &&
             `    renderer: {` && |\n| &&
             `      apiVersion: 2,` && |\n| &&
             `      render(rm, control) {` && |\n| &&
             `        const enabled = control.getEnabled();` && |\n| &&
             `` && |\n| &&
             `        rm.openStart("div", control);` && |\n| &&
             `        rm.style("display", "inline-block");` && |\n| &&
             `        rm.style("padding", "0.75rem 1.25rem");` && |\n| &&
             `        rm.style("border", "2px solid #0a6ed1");` && |\n| &&
             `        rm.style("border-radius", "0.5rem");` && |\n| &&
             `        rm.style("font-family", "var(--sapFontFamily, Arial, sans-serif)");` && |\n| &&
             `        rm.style("cursor", enabled ? "pointer" : "not-allowed");` && |\n| &&
             `        rm.style("opacity", enabled ? "1" : "0.4");` && |\n| &&
             `        rm.style("user-select", "none");` && |\n| &&
             `        rm.attr("tabindex", enabled ? "0" : "-1");` && |\n| &&
             `        rm.attr("role", "button");` && |\n| &&
             `        rm.openEnd();` && |\n| &&
             `` && |\n| &&
             `        rm.openStart("span");` && |\n| &&
             `        rm.style("font-weight", "bold");` && |\n| &&
             `        rm.style("color", "#0a6ed1");` && |\n| &&
             `        rm.openEnd();` && |\n| &&
             `        rm.text(control.getText());` && |\n| &&
             `        rm.close("span");` && |\n| &&
             `` && |\n| &&
             `        rm.openStart("span");` && |\n| &&
             `        rm.style("margin-left", "0.75rem");` && |\n| &&
             `        rm.openEnd();` && |\n| &&
             `        rm.text(String(control.getCount()));` && |\n| &&
             `        rm.close("span");` && |\n| &&
             `` && |\n| &&
             `        rm.close("div");` && |\n| &&
             `      },` && |\n| &&
             `    },` && |\n| &&
             `  });` && |\n| &&
             `});` && |\n| &&
             ``.

  ENDMETHOD.

ENDCLASS.
