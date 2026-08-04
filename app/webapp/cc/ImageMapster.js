// z2ui5cc.cc.ImageMapster - an HTML image map that highlights and selects.
//
// A plain <map>/<area> gives a clickable region and nothing else: no hover
// feedback, no selection, no way to tell which region is active. ImageMapster
// draws those on a canvas over the image, and this control wires that to
// abap2UI5: the regions come from a bound table, the selection is written back
// into the model, and clicking one raises a normal backend event.
//
// Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_imagemapster). Changes
// of substance:
//
//   1. the minified library - 3300 lines of it - was pasted into ABAP as
//      string literals and injected into the view. It is loaded from a URL
//      the app can override.
//   2. the areas were hand-written into the view as html:map / html:area
//      elements with an `onclick` that called
//      `sap.z2ui5.oController.eB([...])` - a frontend internal, and one that
//      told the backend nothing about WHICH area was clicked. They are a
//      bound table now and the event carries the key.
//   3. the map was bound with a global `onWindowResize(200,200)` call
//      appended as raw <script>. Resizing is a property, handled by a
//      ResizeObserver on the control's own element.
//
// The image-map EDITOR the old repository shipped alongside this (a 2000 line
// inline HTML/JS tool for drawing the coordinates) is not part of this port -
// it is an authoring tool, not a control.
sap.ui.define(
  ["sap/ui/core/Control", "sap/ui/thirdparty/jquery", "z2ui5cc/cc/Util"],
  (Control, jQuery, Util) => {
    "use strict";

    const LIB_URL =
      "https://cdn.jsdelivr.net/npm/imagemapster@1.5.4/dist/jquery.imagemapster.min.js";

    // Per-area render settings, as opposed to the geometry that goes on the
    // <area> element itself.
    const AREA_SETTINGS = {
      FILLCOLOR: "fillColor",
      FILLOPACITY: "fillOpacity",
      STROKECOLOR: "strokeColor",
      SELECTED: "selected",
      STATICSTATE: "staticState",
      ISSELECTABLE: "isSelectable",
    };

    return Control.extend("z2ui5cc.cc.ImageMapster", {
      metadata: {
        properties: {
          // the image the map sits on - URL or data: URI
          src: { type: "string", defaultValue: "" },
          // [{ KEY, SHAPE, COORDS, ALT, HREF, FILLCOLOR, ... }]
          areas: { type: "object[]", defaultValue: [] },
          // ImageMapster options, e.g. { fillColor, stroke, singleSelect }
          config: { type: "object", defaultValue: null },
          // comma separated keys of the selected areas; bind two-way
          selectedKeys: { type: "string", defaultValue: "" },
          width: { type: "string", defaultValue: "100%" },
          height: { type: "string", defaultValue: "" },
          // keep the map in step with the image when the element resizes
          autoResize: { type: "boolean", defaultValue: true },
          libUrl: { type: "string", defaultValue: LIB_URL },
        },
        events: {
          // a region was clicked; `keys` is the selection afterwards
          areaPress: {
            parameters: {
              key: { type: "string" },
              selected: { type: "boolean" },
              keys: { type: "string" },
            },
          },
        },
      },

      _image() {
        return document.getElementById(`${this.getId()}-image`);
      },

      _mapName() {
        return `${this.getId()}-map`;
      },

      _options() {
        const areas = (this.getAreas() || [])
          .map((area) => {
            const entry = { key: area.KEY };
            let touched = false;
            Object.entries(AREA_SETTINGS).forEach(([field, option]) => {
              if (area[field] === undefined || area[field] === "") return;
              entry[option] = area[field];
              touched = true;
            });
            return touched ? entry : null;
          })
          .filter(Boolean);

        return {
          ...(this.getConfig() || {}),
          // the attribute the <area> elements carry their key in
          mapKey: "data-key",
          areas,
          // ImageMapster fires onClick BEFORE it applies the toggle, so
          // mapster("get") still reports the selection as it was *before* this
          // click. Reading it here made every event lag one click behind -
          // select a region and the backend was told about the previous one.
          // Deferring by a tick lets the toggle land first.
          //
          // data.key and data.selected are already the new state, so they are
          // captured now and only the list is read late.
          onClick: (data) => {
            const key = data.key;
            const selected = Boolean(data.selected);
            window.setTimeout(() => {
              if (Util.isDestroyed(this) || !this._bound) return;
              const keys = this._selection();
              this.setProperty("selectedKeys", keys, true);
              this.fireAreaPress({ key, selected, keys });
            }, 0);
          },
        };
      },

      // ImageMapster returns the selected keys as a comma separated string.
      _selection() {
        try {
          return jQuery(this._image()).mapster("get") || "";
        } catch (e) {
          return "";
        }
      },

      _bindMap() {
        const image = this._image();
        if (!image || !this.getSrc()) return;

        // ImageMapster measures the image, so binding before it decoded gives
        // a map scaled to a 0x0 picture.
        const start = () => {
          if (Util.isDestroyed(this) || this._bound) return;
          const $image = jQuery(image);
          $image.mapster(this._options());
          this._bound = true;
          const initial = this.getSelectedKeys();
          if (initial) $image.mapster("set", true, initial);
          this._observe();
        };

        if (image.complete && image.naturalWidth) start();
        else image.addEventListener("load", start, { once: true });
      },

      _unbindMap() {
        if (!this._bound) return;
        try {
          jQuery(this._image()).mapster("unbind");
        } catch (e) {
          Util.logError("ImageMapster: unbind failed", e);
        }
        this._bound = false;
      },

      // Keeps the canvas overlay in step with the rendered image size.
      _observe() {
        if (!this.getAutoResize() || typeof ResizeObserver === "undefined") return;
        // NOT called `_observer`: ManagedObject already owns that name for
        // its own ManagedObjectObserver, which has no disconnect().
        if (!this._mapResizeObserver) {
          this._mapResizeObserver = new ResizeObserver(() => {
            if (Util.isDestroyed(this) || !this._bound) return;
            const image = this._image();
            if (!image || !image.clientWidth) return;
            try {
              jQuery(image).mapster("resize", image.clientWidth, 0, 0);
            } catch (e) {
              Util.logError("ImageMapster: resize failed", e);
            }
          });
        }
        this._mapResizeObserver.disconnect();
        this._mapResizeObserver.observe(this.getDomRef());
      },

      setSelectedKeys(value) {
        this.setProperty("selectedKeys", value, true);
        // the backend can drive the selection: clear everything, then set
        // what it asked for
        if (this._bound) {
          try {
            const $image = jQuery(this._image());
            $image.mapster("set", false);
            if (value) $image.mapster("set", true, value);
          } catch (e) {
            Util.logError("ImageMapster: could not apply the selection", e);
          }
        }
        return this;
      },

      // Unbind while the element is still the one mapster knows.
      //
      // The renderer uses apiVersion 2, so UI5 PATCHES the existing <img> on a
      // re-render instead of replacing it - the old mapster binding is still
      // live on that very element. Binding a second time on top of it leaves
      // the canvas overlay painted while mapster's own selection resets to
      // empty, so the picture and the model drift apart (verified against
      // imagemapster 1.5.4: bind, select `lab`, bind again -> get() == "").
      onBeforeRendering() {
        this._unbindMap();
      },

      onAfterRendering() {
        this._bound = false;

        // ImageMapster is a jQuery plugin whose UMD wrapper attaches to the
        // global jQuery. UI5 2.x no longer publishes one, so hand it the
        // instance UI5 itself uses.
        if (!window.jQuery) window.jQuery = jQuery;

        Util.loadScript(this.getLibUrl(), () => Boolean(jQuery.fn.mapster))
          .then(() => {
            if (Util.isDestroyed(this)) return;
            this._bindMap();
          })
          .catch((e) => Util.logError("ImageMapster: library not available", e));
      },

      exit() {
        if (this._mapResizeObserver) {
          this._mapResizeObserver.disconnect();
          this._mapResizeObserver = null;
        }
        this._unbindMap();
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          const mapName = `${control.getId()}-map`;

          rm.openStart("div", control);
          rm.style("width", Util.toCssSize(control.getWidth()));
          if (control.getHeight()) {
            rm.style("height", Util.toCssSize(control.getHeight()));
          }
          rm.openEnd();

          rm.openStart("img", `${control.getId()}-image`);
          rm.attr("src", control.getSrc());
          rm.attr("usemap", `#${mapName}`);
          rm.style("width", "100%");
          rm.style("display", "block");
          rm.openEnd();
          rm.close("img");

          rm.openStart("map");
          rm.attr("name", mapName);
          rm.openEnd();
          (control.getAreas() || []).forEach((area) => {
            rm.openStart("area");
            rm.attr("data-key", area.KEY || "");
            rm.attr("shape", area.SHAPE || "poly");
            rm.attr("coords", area.COORDS || "");
            if (area.ALT) rm.attr("alt", area.ALT);
            // an href makes the region focusable and keyboard reachable;
            // ImageMapster suppresses the navigation itself
            rm.attr("href", area.HREF || "#");
            rm.openEnd();
            rm.close("area");
          });
          rm.close("map");

          rm.close("div");
        },
      },
    });
  },
);
