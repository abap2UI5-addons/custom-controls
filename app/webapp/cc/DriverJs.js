// z2ui5_cci.cc.DriverJs - product tours and spotlight highlights, driven from
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
//   4. the popover texts are text. driver.js writes title, description,
//      progress and button texts with innerHTML, so a material description or
//      a user name in a step was markup - and script - on the page. They are
//      escaped here; `allowHtml` lets markup through, sanitized by DOMPurify.
//
// `trigger`: see Util.triggerFired - the value a fresh instance is built with
// starts the tour only when it is not the value the previous instance at the
// same binding already had, so a view_display (a navigation back, say) does
// not start the last tour again.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5_cci/cc/Util", "z2ui5_cci/cc/LibUrls"],
  (Control, Util, LibUrls) => {
    "use strict";

    const LIB_URL = LibUrls.driverJs;
    const CSS_URL = LibUrls.driverJsCss;
    const PURIFY_URL = LibUrls.domPurify;

    // the texts driver.js writes into the popover with innerHTML - on the
    // config, on every step's popover and on the highlight step's popover
    const HTML_TEXTS = [
      "title",
      "description",
      "progressText",
      "nextBtnText",
      "prevBtnText",
      "doneBtnText",
    ];

    const escapeHtml = (value) =>
      String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");

    const STYLE_ID = "z2ui5_cci-driverjs-custom";

    return Control.extend("z2ui5_cci.cc.DriverJs", {
      metadata: {
        properties: {
          // driver.js configuration; `steps[].element` is a control id
          config: { type: "object", defaultValue: null },
          // a single step, for mode `highlight`
          highlight: { type: "object", defaultValue: null },
          // `tour` walks the steps, `highlight` spotlights one element
          mode: { type: "string", defaultValue: "tour" },
          // raise it to start; 0 never starts, so opening the app does not
          // immediately take the user hostage. A rebuilt view does not start
          // the last tour again - see Util.triggerFired.
          trigger: { type: "int", defaultValue: 0 },
          // false (default): the popover texts are shown as plain text.
          // true: they are HTML, sanitized with DOMPurify before driver.js
          // sees them - simple markup works, script does not.
          allowHtml: { type: "boolean", defaultValue: false },
          // extra CSS, e.g. to theme `.driver-popover.driverjs-theme`
          customCss: { type: "string", defaultValue: "" },
          libUrl: { type: "string", defaultValue: LIB_URL },
          cssUrl: { type: "string", defaultValue: CSS_URL },
          // DOMPurify, only loaded with allowHtml
          purifyUrl: { type: "string", defaultValue: PURIFY_URL },
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
        if (!control) return element;
        // a UI5 id may carry characters a selector reads as syntax (`.`, `:`)
        const id = control.getId();
        return `#${typeof CSS !== "undefined" && CSS.escape ? CSS.escape(id) : id}`;
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

      // Escapes - or, with allowHtml, sanitizes - every text driver.js will
      // write with innerHTML. Works on a copy; `target` is that copy.
      _texts(target) {
        const html = this.getAllowHtml();
        HTML_TEXTS.forEach((key) => {
          const value = target[key];
          if (value === undefined || value === null || value === "") return;
          target[key] = html ? Util.purify(value) : escapeHtml(value);
        });
      },

      _resolveStep(step) {
        const next = { ...step, element: this._selector(step.element) };
        if (next.popover) {
          next.popover = { ...next.popover };
          this._buttons(next.popover, step.popover);
          this._texts(next.popover);
        }
        return next;
      },

      _resolveSteps(config) {
        if (!config) return config;

        const out = { ...config };
        this._buttons(out, config);
        this._texts(out);

        if (Array.isArray(config.steps)) {
          out.steps = config.steps.map((step) => this._resolveStep(step));
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
          // driver.js calls this from destroy( ) as well - a tour torn down
          // because the control goes away or a new one starts is not done
          onDestroyed: () => {
            if (this._quiet || Util.isDestroyed(this)) return;
            this.fireDone();
          },
        };

        this._destroyDriver();
        const instance = driver(config);
        this._driver = instance;

        if (this.getMode() === "highlight") {
          const step = this.getHighlight();
          if (!step) {
            Util.logError("DriverJs: mode is `highlight` but no step was given");
            return;
          }
          instance.highlight(this._resolveStep(step));
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
        const libs = [
          Util.loadStyle(this.getCssUrl()),
          Util.loadScript(this.getLibUrl(), () => Boolean(window.driver)),
        ];
        // DOMPurify is only fetched when markup is allowed - without it the
        // texts are escaped, which needs no library
        if (this.getAllowHtml()) {
          libs.push(
            Util.loadScript(this.getPurifyUrl(), () => typeof window.DOMPurify !== "undefined"),
          );
        }
        Promise.all(libs)
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
        // hijack the screen. The first value of a fresh instance is a change
        // only when it is new to this binding (Util.triggerFired): a
        // view_display after a navigation back hands the new instance the
        // trigger of the tour the user already saw.
        if (Util.triggerFired(this, value, previous)) this._start();
        return this;
      },

      _destroyDriver() {
        if (this._driver && this._driver.destroy) {
          this._quiet = true;
          try {
            this._driver.destroy();
          } finally {
            this._quiet = false;
          }
        }
        this._driver = null;
      },

      exit() {
        // a tour outlives its control otherwise: the overlay is appended to
        // <body>, not to this element
        this._destroyDriver();
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
