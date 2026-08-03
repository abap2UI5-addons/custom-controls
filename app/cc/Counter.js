// testcc.cc.Counter - a test custom control that lives OUTSIDE abap2UI5.
//
// The point of this control is not what it does, but where it comes from: no
// file of it is part of the abap2UI5 framework or the abap2UI5-frontend BSP.
// It is registered under its own module namespace "testcc" and reaches the
// browser through the public z2ui5_if_exit extension point (see
// ZCL_TESTCC_EXIT), so a new custom control never needs a pull request
// against abap2UI5.
//
// It deliberately exercises all three integration paths a real custom control
// needs from the framework:
//   1. property binding      - text/count are bound from the ABAP model
//   2. write-back            - clicking raises count and pushes it INTO the
//                              model, so the new value reaches ABAP with the
//                              next roundtrip (two-way binding)
//   3. event dispatch        - press is wired to an abap2UI5 backend event
//
// The explicit module name in sap.ui.define() is what makes this work without
// a second BSP: the module registers itself in the ui5loader at bootstrap, so
// the XML view resolves <testcc:Counter/> from the registry instead of firing
// an HTTP request. Registering a resourceRoot for "testcc" and serving this
// file from its own BSP is the other half of the story - see README.md.
sap.ui.define("testcc/cc/Counter", ["sap/ui/core/Control"], (Control) => {
  "use strict";

  return Control.extend("testcc.cc.Counter", {
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
