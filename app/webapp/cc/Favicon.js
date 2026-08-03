// z2ui5cc.cc.Favicon - sets the browser tab icon of the running app.
//
// Ported from abap2UI5-addons/custom-controls (z2ui5_cl_cc_favicon). Two
// changes of substance:
//
//   1. the old control appended a new <link rel="shortcut icon"> on every
//      change, so a form that lets the user try five icons left five stale
//      link elements behind and which one won was up to the browser. This one
//      owns exactly one link element and rewrites its href.
//   2. it restores the icon the page had before, so navigating away from the
//      app does not leave the whole Launchpad wearing this app's favicon.
sap.ui.define(["sap/ui/core/Control"], (Control) => {
  "use strict";

  const LINK_ID = "z2ui5cc-favicon";

  return Control.extend("z2ui5cc.cc.Favicon", {
    metadata: {
      properties: {
        // URL or data: URI of the icon
        href: { type: "string", defaultValue: "" },
        // MIME type; empty lets the browser sniff it
        type: { type: "string", defaultValue: "" },
      },
    },

    // The <link> this control owns - created on demand, never duplicated.
    _link() {
      let link = document.getElementById(LINK_ID);
      if (!link) {
        link = document.createElement("link");
        link.id = LINK_ID;
        link.rel = "icon";
        document.head.appendChild(link);
      }
      return link;
    },

    _apply() {
      const href = this.getHref();
      if (!href) return;
      const link = this._link();
      link.href = href;
      if (this.getType()) link.type = this.getType();
    },

    init() {
      // Remember what the page looked like before this app took over, so
      // exit() can put it back.
      const existing = document.querySelector(
        `link[rel~="icon"]:not(#${LINK_ID})`,
      );
      this._restoreHref = existing ? existing.href : "";
    },

    setHref(val) {
      this.setProperty("href", val, true);
      this._apply();
      return this;
    },

    onAfterRendering() {
      this._apply();
    },

    exit() {
      const link = document.getElementById(LINK_ID);
      if (!link) return;
      if (this._restoreHref) link.href = this._restoreHref;
      else link.remove();
    },

    // Nothing visible - the control's whole effect is on <head>.
    renderer: {
      apiVersion: 2,
      render(rm, control) {
        rm.openStart("span", control);
        rm.style("display", "none");
        rm.openEnd();
        rm.close("span");
      },
    },
  });
});
