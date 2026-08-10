// z2ui5ccc.cc.DriverJs - product tours and spotlight highlights, driven from
// ABAP.
//
// The app describes the tour as data - a list of steps, each naming a control
// id and the text of its popover - and raises `trigger` to start it. Ids are
// resolved against the view this control was rendered in, so a step can point
// at a control in a nested view or a dialog without the app saying where it
// lives.
//
// Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_driver_js). Changes of
// substance:
//
//   1. the whole driver.js library and its stylesheet were pasted into ABAP as
//      string literals and injected as <script>/<style> into the view. They
//      are loaded as a library now, from a URL the app can override.
//   2. the step's `elementview` told the frontend which of the five known
//      views to resolve the id in (MAIN/NEST/NEST2/POPUP/POPOVER), and the
//      switch that did it had no break statements, so every case fell through
//      to the last one and every id was resolved against the popover view.
//      Resolution is automatic here and the field is gone.
//   3. callbacks are no longer JavaScript source strings compiled with
//      `new Function` on the client. The tour finishing and each step being
//      highlighted are UI5 events instead.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5ccc/cc/Util"],
  (Control, Util) => {
    "use strict";

    const LIB_URL =
      "https://cdn.jsdelivr.net/npm/driver.js@1.3.1/dist/driver.js.iife.js";
    const CSS_URL =
      "https://cdn.jsdelivr.net/npm/driver.js@1.3.1/dist/driver.css";

    const STYLE_ID = "z2ui5ccc-driverjs-custom";

    return Control.extend("z2ui5ccc.cc.DriverJs", {
      metadata: {
        properties: {
          // driver.js configuration; `steps[].element` is a control id
          config: { type: "object", defaultValue: null },
          // a single step, for mode `highlight`
          highlight: { type: "object", defaultValue: null },
          // `tour` walks the steps, `highlight` spotlights one element
          mode: { type: "string", defaultValue: "tour" },
          // raise it to start; 0 never starts, so opening the app does not
          // immediately take the user hostage
          trigger: { type: "int", defaultValue: 0 },
          // extra CSS, e.g. to theme `.driver-popover.driverjs-theme`
          customCss: { type: "string", defaultValue: "" },
          libUrl: { type: "string", defaultValue: LIB_URL },
          cssUrl: { type: "string", defaultValue: CSS_URL },
        },
        events: {
          highlighted: { parameters: { index: { type: "int" } } },
          done: {},
        },
      },

      // A step points at a UI5 control id; driver.js wants a CSS selector.
      // A value that already looks like a selector (# . [ ) is passed through,
      // so an app can still target plain DOM.
      _selector(element) {
        if (!element || typeof element !== "string") return element;
        if (/^[#.[]/.test(element)) return element;
        const control = Util.resolveControl(this, element);
        return control ? `#${control.getId()}` : element;
      },

      // driver.js wants arrays for showButtons/disableButtons, but ABAP has no
      // natural way to send one per option, so they travel as comma separated
      // lists and are split here. An empty list is dropped rather than sent as
      // [], which would mean "no buttons at all" and strand the user in a tour
      // with no way forward and no way out.
      _buttons(target, source) {
        ["showButtons", "disableButtons"].forEach((key) => {
          if (typeof source[key] !== "string") return;
          const list = Util.toList(source[key]);
          if (list.length) target[key] = list;
          else delete target[key];
        });
      },

      _resolveSteps(config) {
        if (!config) return config;

        const out = { ...config };
        this._buttons(out, config);

        if (Array.isArray(config.steps)) {
          out.steps = config.steps.map((step) => {
            const next = { ...step, element: this._selector(step.element) };
            if (next.popover) {
              next.popover = { ...next.popover };
              this._buttons(next.popover, step.popover);
            }
            return next;
          });
        }

        return out;
      },

      _applyCustomCss() {
        const css = this.getCustomCss();
        let style = document.getElementById(STYLE_ID);
        if (!css) {
          if (style) style.remove();
          return;
        }
        if (!style) {
          style = document.createElement("style");
          style.id = STYLE_ID;
          document.head.appendChild(style);
        }
        style.textContent = css;
      },

      _run() {
        const driver = window.driver && window.driver.js && window.driver.js.driver;
        if (!driver) {
          Util.logError("DriverJs: the library exposed no driver factory");
          return;
        }

        const base = this._resolveSteps(this.getConfig()) || {};
        const config = {
          // Spelled out rather than left to driver.js' default: a tour with no
          // navigation traps the user on step one, so the buttons must not
          // depend on anything the backend did or did not send.
          showButtons: ["next", "previous", "close"],
          ...base,
          onHighlighted: (element, step, options) => {
            const index = options && options.state ? options.state.activeIndex : 0;
            this.fireHighlighted({ index: index || 0 });
          },
          onDestroyed: () => this.fireDone(),
        };

        const instance = driver(config);
        this._driver = instance;

        if (this.getMode() === "highlight") {
          const step = this.getHighlight();
          if (!step) {
            Util.logError("DriverJs: mode is `highlight` but no step was given");
            return;
          }
          instance.highlight({
            ...step,
            element: this._selector(step.element),
          });
          return;
        }

        if (!config.steps || !config.steps.length) {
          Util.logError("DriverJs: mode is `tour` but the config has no steps");
          return;
        }
        instance.drive();
      },

      _start() {
        this._applyCustomCss();
        Promise.all([
          Util.loadStyle(this.getCssUrl()),
          Util.loadScript(this.getLibUrl(), () => Boolean(window.driver)),
        ])
          .then(() => {
            if (Util.isDestroyed(this)) return;
            this._run();
          })
          .catch((e) => Util.logError("DriverJs: library not available", e));
      },

      setTrigger(value) {
        const previous = this.getTrigger();
        this.setProperty("trigger", value, true);
        // Only a real change starts a tour - the property is written on every
        // model update, and restarting the tour on an unrelated one would
        // hijack the screen.
        if (value !== previous && value > 0) this._start();
        return this;
      },

      exit() {
        // a tour outlives its control otherwise: the overlay is appended to
        // <body>, not to this element
        if (this._driver && this._driver.destroy) this._driver.destroy();
        this._driver = null;
        const style = document.getElementById(STYLE_ID);
        if (style) style.remove();
      },

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
  },
);
