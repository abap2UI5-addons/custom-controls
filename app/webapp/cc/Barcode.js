// z2ui5ccc.cc.Barcode - renders a barcode with bwip-js, which speaks every
// symbology BWIPP knows: EAN, UPC, ISBN, Code 128, QR, DataMatrix, GS1 and
// about a hundred more.
//
// The app says which symbology and what to encode; everything else is
// optional. `options` takes a raw BWIPP option string ("includetext
// guardwhitespace", "eclevel=M"), so a symbology-specific switch does not need
// a property here first.
//
// Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_bwipjs). Changes of
// substance:
//
//   1. the canvas had the fixed DOM id "mycanvas", so a second barcode on the
//      same page overwrote the first. It is now the control's own child.
//   2. `includetext` and `textxalign` were hardcoded to true/center although
//      both were declared as properties; they are honoured now.
//   3. a failing draw left an empty canvas and a stack trace in the console.
//      The reason is rendered in place instead - a barcode that will not
//      encode is usually bad input, and the user is the one who can fix it.
//   4. no sap.m.BusyDialog blocking the whole screen while the library loads.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5ccc/cc/Util"],
  (Control, Util) => {
    "use strict";

    const LIB_URL =
      "https://cdn.jsdelivr.net/npm/bwip-js@4.1.1/dist/bwip-js-min.js";

    // BWIPP option string -> the object bwip-js takes.
    // "includetext guardwhitespace eclevel=M" -> {includetext:true,
    // guardwhitespace:true, eclevel:"M"}
    function parseOptions(text) {
      const out = {};
      Util.toList(String(text || "").replace(/\s+/g, ","))
        .forEach((token) => {
          const eq = token.indexOf("=");
          if (eq < 0) out[token] = true;
          else out[token.slice(0, eq)] = token.slice(eq + 1);
        });
      return out;
    }

    return Control.extend("z2ui5ccc.cc.Barcode", {
      metadata: {
        properties: {
          // symbology, e.g. `qrcode`, `ean13`, `code128`
          bcid: { type: "string", defaultValue: "" },
          // what to encode
          text: { type: "string", defaultValue: "" },
          // text printed under the bars instead of the encoded value
          altText: { type: "string", defaultValue: "" },
          // numbers, but declared as strings: an abap2UI5 model carries an
          // ABAP character field as a JSON string, and UI5 rejects "3" for an
          // int-typed property instead of converting it
          scale: { type: "string", defaultValue: "3" },
          // Bar height in millimetres - LINEAR symbologies only, and empty by
          // default on purpose. bwip-js applies it to matrix codes too, where
          // it stretches the symbol instead of sizing bars: a QR code with
          // height=10 comes out 150x75 rather than 150x150. Leave it empty and
          // each symbology uses its own correct proportions.
          height: { type: "string", defaultValue: "" },
          barWidth: { type: "string", defaultValue: "" },
          includeText: { type: "boolean", defaultValue: true },
          textAlign: { type: "string", defaultValue: "center" },
          // 0, 90, 180 or 270 degrees - BWIPP calls them N, R, I, L
          rotate: { type: "string", defaultValue: "N" },
          backgroundColor: { type: "string", defaultValue: "" },
          // raw BWIPP option string, e.g. `includetext guardwhitespace` or
          // `eclevel=M` - the escape hatch for symbology specific switches
          options: { type: "string", defaultValue: "" },
          // `canvas` or `svg`; SVG stays sharp at any zoom and prints better
          renderAs: { type: "string", defaultValue: "canvas" },
          libUrl: { type: "string", defaultValue: LIB_URL },
        },
        events: {
          // fired when the symbology rejected the input, with the reason
          error: { parameters: { message: { type: "string" } } },
        },
      },

      _host() {
        return document.getElementById(`${this.getId()}-host`);
      },

      _options() {
        // fall back to the declared default when the app bound an empty field
        const num = (value, fallback) =>
          Number.isFinite(Number(value)) && String(value).trim() !== ""
            ? Number(value)
            : fallback;

        const opts = {
          bcid: this.getBcid(),
          text: this.getText(),
          scale: num(this.getScale(), 3),
          includetext: this.getIncludeText(),
          textxalign: this.getTextAlign(),
          rotate: this.getRotate(),
          // last, so an explicit option string can override a property
          ...parseOptions(this.getOptions()),
        };
        // only when the app asked for one - see the property comment
        if (String(this.getHeight()).trim()) {
          opts.height = num(this.getHeight(), undefined);
        }
        if (this.getBarWidth()) opts.width = num(this.getBarWidth(), undefined);
        if (this.getAltText()) opts.alttext = this.getAltText();
        if (this.getBackgroundColor()) {
          opts.backgroundcolor = this.getBackgroundColor();
        }
        return opts;
      },

      _fail(host, message) {
        Util.logError(`Barcode: ${message}`);
        host.textContent = message;
        host.style.color = "var(--sapNegativeTextColor, #b00)";
        this.fireError({ message });
      },

      _draw() {
        const host = this._host();
        if (!host) return;
        host.textContent = "";
        host.style.color = "";

        if (!this.getBcid() || !this.getText()) return;

        const opts = this._options();
        try {
          if (this.getRenderAs().toLowerCase() === "svg") {
            // toSVG returns markup, so it goes in as HTML - the string comes
            // from bwip-js, not from user input
            host.innerHTML = window.bwipjs.toSVG(opts);
            return;
          }
          const canvas = document.createElement("canvas");
          host.appendChild(canvas);
          window.bwipjs.toCanvas(canvas, opts);
        } catch (e) {
          this._fail(host, `${e && e.message ? e.message : e}`);
        }
      },

      onAfterRendering() {
        Util.loadScript(
          this.getLibUrl(),
          () => typeof window.bwipjs !== "undefined",
        )
          .then(() => {
            if (Util.isDestroyed(this)) return;
            this._draw();
          })
          .catch((e) => {
            const host = this._host();
            if (host) this._fail(host, `bwip-js could not be loaded: ${e.message}`);
          });
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          rm.openStart("div", control);
          rm.openEnd();
          rm.openStart("div", `${control.getId()}-host`);
          rm.openEnd();
          rm.close("div");
          rm.close("div");
        },
      },
    });
  },
);
