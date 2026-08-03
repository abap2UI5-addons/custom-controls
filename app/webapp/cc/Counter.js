// z2ui5cc.cc.Counter - a test custom control that lives OUTSIDE abap2UI5.
//
// The point of this control is not what it does, but where it comes from: no
// file of it is part of the abap2UI5 framework or of the abap2UI5-frontend
// BSP. It ships in its own BSP (Z2UI5CC) and the frontend finds it through the
// reserved resourceRoot declared in the frontend's manifest.json:
//
//   "sap.ui5": { "resourceRoots": { "z2ui5cc": "../z2ui5cc/" } }
//
// so this file is served from /sap/bc/ui5_ui5/sap/z2ui5cc/cc/Counter.js and a
// new custom control never needs a pull request against abap2UI5.
//
// It deliberately exercises all three integration paths a real custom control
// needs from the framework:
//   1. property binding      - text/count are bound from the ABAP model
//   2. write-back            - clicking raises count and pushes it INTO the
//                              model, so the new value reaches ABAP with the
//                              next roundtrip (two-way binding)
//   3. event dispatch        - press is wired to an abap2UI5 backend event
//
// Plain anonymous sap.ui.define: the module name follows from its path under
// the registered resourceRoot, exactly like any other UI5 module.
sap.ui.define(["sap/ui/core/Control"], (Control) => {
  "use strict";

  return Control.extend("z2ui5cc.cc.Counter", {
    metadata: {
      properties: {
        text: { type: "string", defaultValue: "" },
        count: { type: "int", defaultValue: 0 },
        enabled: { type: "boolean", defaultValue: true },
      },
      events: {
        press: {
          parameters: {
            count: { type: "int" },
          },
        },
      },
    },

    // UI5 routes browser events to on<event> handlers on the control.
    onclick() {
      if (!this.getEnabled()) return;
      // setCount goes through setProperty, so a two-way bound count is
      // written back into the JSON model before the roundtrip below is
      // assembled - this is the write-back path the demo app verifies.
      this.setCount(this.getCount() + 1);
      this.firePress({ count: this.getCount() });
    },

    renderer: {
      apiVersion: 2,
      render(rm, control) {
        const enabled = control.getEnabled();

        rm.openStart("div", control);
        rm.class("z2ui5ccCounter");
        rm.style("display", "inline-block");
        rm.style("padding", "0.75rem 1.25rem");
        rm.style("border", "2px solid #0a6ed1");
        rm.style("border-radius", "0.5rem");
        rm.style("font-family", "var(--sapFontFamily, Arial, sans-serif)");
        rm.style("cursor", enabled ? "pointer" : "not-allowed");
        rm.style("opacity", enabled ? "1" : "0.4");
        rm.style("user-select", "none");
        rm.attr("tabindex", enabled ? "0" : "-1");
        rm.attr("role", "button");
        rm.openEnd();

        rm.openStart("span");
        rm.style("font-weight", "bold");
        rm.style("color", "#0a6ed1");
        rm.openEnd();
        rm.text(control.getText());
        rm.close("span");

        rm.openStart("span");
        rm.style("margin-left", "0.75rem");
        rm.openEnd();
        rm.text(String(control.getCount()));
        rm.close("span");

        rm.close("div");
      },
    },
  });
});
