// z2ui5_cci.cc.ImageMapster - an image map that highlights and selects.
//
// A plain <map>/<area> gives a clickable region and nothing else: no hover
// feedback, no selection, no way to tell which region is active. This control
// draws an SVG overlay on top of the image and wires it to abap2UI5: the
// regions come from a bound table, the selection is written back into the
// model, and clicking one raises a normal backend event carrying the key.
//
// Why SVG and not the jquery.imagemapster library it was ported from
// -------------------------------------------------------------------
// The library did the same job on a <canvas>, and it is a jQuery plugin - its
// whole API is $.fn.mapster. That made it the only thing in the entire stack
// pulling jQuery in (the abap2UI5 frontend itself uses none), it had to be
// loaded from a CDN or vendored, and it cost this control a running fight:
//
//   * mapster fired onClick BEFORE applying its own toggle, so reading the
//     state back reported the selection as it was one click ago
//   * the canvas had to be re-measured by hand, from a ResizeObserver calling
//     mapster("resize"), whenever the image changed size
//   * a re-render patched the <img> in place rather than replacing it, so the
//     old binding was still live on it and binding again silently reset
//     mapster's selection while leaving the canvas painted
//
// An SVG overlay has none of that. `viewBox` is the image's natural pixel
// space - the same space the HTML image map `coords` are written in - so the
// browser scales the shapes with the image and there is nothing to observe or
// re-measure. Hover and selection are ordinary DOM events on ordinary
// elements, so the state is ours and cannot lag behind. The shapes are vectors
// rather than a rasterised canvas, so they stay sharp when the page is zoomed,
// and each one is a real focusable element instead of an <area href="#">,
// which is what makes the control keyboard reachable.
//
// The overlay is rebuilt from scratch in onAfterRendering rather than emitted
// by the renderer. RenderManager describes HTML, and its DOM patcher owns the
// children of everything it describes - an SVG subtree grafted into that would
// be at the mercy of the next patch. Rebuilding is cheap (a handful of
// elements), and it means there is exactly one code path that produces the
// overlay instead of one for the first render and one for every update.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5_cci/cc/Util", "z2ui5_cci/cc/MapShapes"],
  (Control, Util, MapShapes) => {
    "use strict";

    const SVG_NS = "http://www.w3.org/2000/svg";
    const { shapeOf, paintAttributes } = MapShapes;

    return Control.extend("z2ui5_cci.cc.ImageMapster", {
      metadata: {
        properties: {
          // the image the map sits on - URL or data: URI
          src: { type: "string", defaultValue: "" },
          // [{ KEY, SHAPE, COORDS, ALT, HREF, FILLCOLOR, ... }]
          areas: { type: "object[]", defaultValue: [] },
          // render options, e.g. { fillColor, stroke, singleSelect }
          config: { type: "object", defaultValue: null },
          // comma separated keys of the selected areas; bind two-way
          selectedKeys: { type: "string", defaultValue: "" },
          width: { type: "string", defaultValue: "100%" },
          height: { type: "string", defaultValue: "" },
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

      _frame() {
        return document.getElementById(`${this.getId()}-frame`);
      },

      _selection() {
        return Util.toList(this.getSelectedKeys());
      },

      // Which of the three paints an area is currently wearing.
      _stateOf(area) {
        const key = area.KEY;
        if (this._selection().includes(key)) return "select";
        if (this._hover === key) return "highlight";
        // `staticState` means "drawn whatever the user does" - at the map
        // level or for one area
        const config = this.getConfig() || {};
        if (area.STATICSTATE || config.staticState) return "select";
        return "hidden";
      },

      _selectable(area) {
        const config = this.getConfig() || {};
        if (area.ISSELECTABLE !== undefined && area.ISSELECTABLE !== "") {
          return Boolean(area.ISSELECTABLE);
        }
        return config.isSelectable !== false;
      },

      // Repaints without rebuilding: the shapes and their handlers stay, only
      // the presentation attributes change. This is the path a hover and a
      // click take, so it must not touch the DOM structure.
      _paint() {
        const config = this.getConfig() || {};
        (this._shapes || []).forEach(({ node, area }) => {
          const state = this._stateOf(area);
          const attributes = paintAttributes(config, area, state);
          Object.entries(attributes).forEach(([name, value]) => node.setAttribute(name, value));
          node.setAttribute("aria-pressed", String(state === "select"));
        });
        this._clip();
      },

      // `altImage` shows a second picture INSIDE the active regions. The clip
      // path is the union of those regions, so the image is painted only where
      // they are; with none active the clip path is empty and nothing shows,
      // which is exactly the wanted result.
      _clip() {
        if (!this._clipPath || !this._altImage) return;

        while (this._clipPath.firstChild) this._clipPath.removeChild(this._clipPath.firstChild);

        let active = 0;
        (this._shapes || []).forEach(({ node, area }) => {
          if (this._stateOf(area) === "hidden") return;
          this._clipPath.appendChild(node.cloneNode(false));
          active += 1;
        });

        this._altImage.style.display = active ? "" : "none";
      },

      _press(area) {
        const key = area.KEY;
        const config = this.getConfig() || {};

        if (!this._selectable(area)) {
          this.fireAreaPress({ key, selected: false, keys: this.getSelectedKeys() });
          return;
        }

        let list = this._selection();
        const at = list.indexOf(key);
        const wasSelected = at >= 0;

        if (wasSelected && config.isDeselectable === false) {
          this.fireAreaPress({ key, selected: true, keys: list.join(",") });
          return;
        }

        if (config.singleSelect) list = wasSelected ? [] : [key];
        else if (wasSelected) list.splice(at, 1);
        else list.push(key);

        const keys = list.join(",");
        // suppressInvalidate: the overlay is repainted here, a re-render would
        // only throw the shapes away and build the same ones again
        this.setProperty("selectedKeys", keys, true);
        this._paint();
        this.fireAreaPress({ key, selected: !wasSelected, keys });
      },

      // Builds the overlay for the image as it is now. Called once the image
      // has decoded, because the viewBox is its natural size.
      _build() {
        const image = this._image();
        const frame = this._frame();
        if (!image || !frame) return;

        const width = image.naturalWidth;
        const height = image.naturalHeight;
        if (!width || !height) return;

        this._destroyOverlay();

        const config = this.getConfig() || {};
        const svg = document.createElementNS(SVG_NS, "svg");
        svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
        // `none` rather than a meet/slice rule: the overlay is stretched onto
        // the image's box whatever that box turned out to be, so the two can
        // never disagree about where a region is
        svg.setAttribute("preserveAspectRatio", "none");
        svg.setAttribute("focusable", "false");
        Object.assign(svg.style, {
          position: "absolute",
          left: "0",
          top: "0",
          width: "100%",
          height: "100%",
          overflow: "visible",
        });

        if (config.altImage) {
          const defs = document.createElementNS(SVG_NS, "defs");
          this._clipPath = document.createElementNS(SVG_NS, "clipPath");
          this._clipPath.setAttribute("id", `${this.getId()}-clip`);
          defs.appendChild(this._clipPath);
          svg.appendChild(defs);

          this._altImage = document.createElementNS(SVG_NS, "image");
          this._altImage.setAttribute("href", config.altImage);
          this._altImage.setAttribute("x", "0");
          this._altImage.setAttribute("y", "0");
          this._altImage.setAttribute("width", String(width));
          this._altImage.setAttribute("height", String(height));
          this._altImage.setAttribute("clip-path", `url(#${this.getId()}-clip)`);
          svg.appendChild(this._altImage);
        }

        const fade = config.fade !== false;
        const duration = config.fadeDuration ?? MapShapes.DEFAULTS.fadeDuration;

        this._shapes = [];
        (this.getAreas() || []).forEach((area) => {
          const spec = shapeOf(area, { width, height });
          if (!spec) {
            Util.logError(`ImageMapster: area '${area?.KEY ?? ""}' has no usable coords`);
            return;
          }

          const node = document.createElementNS(SVG_NS, spec.tag);
          Object.entries(spec.attr).forEach(([name, value]) =>
            node.setAttribute(name, String(value)),
          );
          node.setAttribute("vector-effect", "non-scaling-stroke");
          if (fade) node.style.transition = `fill-opacity ${duration}ms, stroke-opacity ${duration}ms`;

          const selectable = this._selectable(area);
          node.style.cursor = selectable ? "pointer" : "default";
          node.setAttribute("role", "button");
          node.setAttribute("tabindex", "0");
          if (area.ALT) node.setAttribute("aria-label", area.ALT);

          this._wire(node, area);
          svg.appendChild(node);
          this._shapes.push({ node, area });
        });

        frame.appendChild(svg);
        this._svg = svg;
        this._paint();
      },

      _wire(node, area) {
        const config = this.getConfig() || {};
        const highlight = config.highlight !== false;
        const delay = Number(config.mouseoutDelay) || 0;

        if (highlight) {
          node.addEventListener("pointerenter", () => {
            window.clearTimeout(this._hoverTimer);
            this._hover = area.KEY;
            this._paint();
          });
          node.addEventListener("pointerleave", () => {
            window.clearTimeout(this._hoverTimer);
            const clear = () => {
              if (Util.isDestroyed(this) || this._hover !== area.KEY) return;
              this._hover = null;
              this._paint();
            };
            if (delay) this._hoverTimer = window.setTimeout(clear, delay);
            else clear();
          });
        }

        node.addEventListener("click", () => this._press(area));
        // a focusable element that reacts to the mouse has to react to the
        // keyboard as well, or the tab stop is a dead end
        node.addEventListener("keydown", (event) => {
          if (event.key !== "Enter" && event.key !== " ") return;
          event.preventDefault();
          this._press(area);
        });
      },

      _destroyOverlay() {
        window.clearTimeout(this._hoverTimer);
        this._hoverTimer = null;
        if (this._svg && this._svg.parentNode) this._svg.parentNode.removeChild(this._svg);
        this._svg = null;
        this._shapes = [];
        this._clipPath = null;
        this._altImage = null;
      },

      setSelectedKeys(value) {
        this.setProperty("selectedKeys", value, true);
        // the backend can drive the selection without a re-render
        if (this._svg) this._paint();
        return this;
      },

      onAfterRendering() {
        this._hover = null;

        const image = this._image();
        if (!image || !this.getSrc()) return;

        // The viewBox is the image's natural size, so the overlay cannot be
        // built before the image has decoded.
        const start = () => {
          if (Util.isDestroyed(this)) return;
          this._build();
        };
        if (image.complete && image.naturalWidth) start();
        else image.addEventListener("load", start, { once: true });
      },

      exit() {
        this._destroyOverlay();
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          const config = control.getConfig() || {};

          rm.openStart("div", control);
          rm.style("width", Util.toCssSize(control.getWidth()));
          if (control.getHeight()) {
            rm.style("height", Util.toCssSize(control.getHeight()));
          }
          rm.openEnd();

          // The frame's box IS the image's box, which is what lets the overlay
          // sit at inset 0 and stay correct at every width without anything
          // measuring anything. It holds from both sides and only because of
          // the two styles below:
          //
          //   width   the frame is a block, so it takes the full width offered
          //           - and the image is `width: 100%`, so it takes the same
          //   height  the frame's height is auto, and its only in-flow child
          //           is the image, so it is exactly as tall as the image
          //
          // Note it is NOT that the frame shrink-wraps the image: a block box
          // never shrinks to its child's width. Give the image any width other
          // than 100% and the overlay stops lining up.
          rm.openStart("div", `${control.getId()}-frame`);
          if (config.wrapClass) rm.class(config.wrapClass);
          rm.style("position", "relative");
          rm.style("line-height", "0");
          rm.openEnd();

          rm.openStart("img", `${control.getId()}-image`);
          rm.attr("src", control.getSrc());
          rm.attr("alt", "");
          rm.style("width", "100%");
          rm.style("display", "block");
          rm.openEnd();
          rm.close("img");

          rm.close("div");
          rm.close("div");
        },
      },
    });
  },
);
