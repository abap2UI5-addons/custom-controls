// z2ui5_cci.cc.FloorPlan - a zoomable plan of boxes with a fill level.
//
// A warehouse seen from above, a shop floor, a car park, a seating plan: a few
// hundred rectangles at fixed places, each with a state, a share that is
// "full" and two or three words about it. The rows come from a bound ABAP
// table, the user zooms and pans with the wheel, a drag or two fingers, and a
// click raises a normal backend event with the key of the box.
//
// What it decides on its own is only what a server cannot know:
//
//   * the level of detail. How much text a box shows depends on how many
//     pixels it has right now - nothing zoomed out, the title closer, the
//     lines below it closer still. The app sends all of it once.
//   * the viewport. Zoom and position stay where the user left them when the
//     table changes; only `fitKeys` moves them from the backend.
//
// With `zoomable` off it is a fixed picture of the whole plan: no wheel, no
// drag, no pinch, no keys and no buttons, the page scrolls as usual, and a
// click still selects - for a plan small enough to be read as it is.
//
// No library. Zoom is the viewBox of one SVG element, and the arithmetic sits
// in FloorPlanMath where it is tested without a browser.
//
// Two layers, and why
// -------------------
// The boxes are drawn in plan units inside the viewBox, so the browser scales
// them. The text is NOT: a label has to stay 12 px high at every zoom, and a
// font size of 0.02 user units (a plan in metres, zoomed in) is where browsers
// start rounding glyph positions. So the labels live in a second SVG without
// a viewBox, in pixels, and are placed from the viewport on every change -
// which is also what lets a label be left out entirely when its box is off
// screen or too small.
//
// Like ImageMapster, the SVG is built in onAfterRendering rather than emitted
// by the renderer: RenderManager describes HTML and its DOM patcher owns the
// children of everything it describes.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5_cci/cc/Util", "z2ui5_cci/cc/FloorPlanMath"],
  (Control, Util, FloorPlanMath) => {
    "use strict";

    const SVG_NS = "http://www.w3.org/2000/svg";
    const { box, colourOf, fillBar, labelLayout } = FloorPlanMath;

    const FONT_PX = 12;
    const LINE_PX = FONT_PX * 1.3;
    // a pointer that moved less than this was a click, not a drag
    const DRAG_PX = 4;
    const MAX_ZOOM = 40;
    const FLY_MS = 300;

    const COLOURS = {
      background: "var(--sapBackgroundColor,#f7f7f7)",
      box: "var(--sapList_Background,#ffffff)",
      border: "var(--sapContent_ForegroundBorderColor,#89919a)",
      area: "var(--sapGroup_TitleBorderColor,#d9d9d9)",
      text: "var(--sapTextColor,#32363a)",
      label: "var(--sapContent_LabelColor,#6a6d70)",
      selected: "var(--sapSelectedColor,#0854a0)",
      button: "var(--sapButton_Background,#ffffff)",
      buttonBorder: "var(--sapButton_BorderColor,#0854a0)",
      buttonText: "var(--sapButton_TextColor,#0854a0)",
    };

    const svgNode = (tag, attributes = {}) => {
      const node = document.createElementNS(SVG_NS, tag);
      Object.entries(attributes).forEach(([name, value]) => node.setAttribute(name, String(value)));
      return node;
    };

    const setBox = (node, b) => {
      node.setAttribute("x", String(b.x));
      node.setAttribute("y", String(b.y));
      node.setAttribute("width", String(Math.max(b.w, 0)));
      node.setAttribute("height", String(Math.max(b.h, 0)));
    };

    const linesOf = (item) => [item.TITLE, item.TEXT, item.INFO];

    return Control.extend("z2ui5_cci.cc.FloorPlan", {
      metadata: {
        properties: {
          // [{ KEY, X, Y, WIDTH, HEIGHT, FILL, DIR, STATE, COLOR, BLOCKED,
          //    DISABLED, TITLE, TEXT, INFO }] - the boxes, in plan units
          items: { type: "object[]", defaultValue: [] },
          // [{ KEY, X, Y, WIDTH, HEIGHT, TITLE }] - outlines behind the
          // boxes: a hall, a zone. Not clickable
          areas: { type: "object[]", defaultValue: [] },
          // comma separated keys of the selected items; bind two-way
          selectedKeys: { type: "string", defaultValue: "" },
          // comma separated keys to point out; every other item is dimmed
          highlightKeys: { type: "string", defaultValue: "" },
          // comma separated keys the viewport flies to; empty shows all
          fitKeys: { type: "string", defaultValue: "" },
          // None | Single | Multi
          selectionMode: { type: "string", defaultValue: "Single" },
          // the zoom buttons in the corner
          showControls: { type: "boolean", defaultValue: true },
          // false: a fixed picture of the whole plan - no wheel, no drag, no
          // pinch, no keys, no buttons. A click still selects.
          zoomable: { type: "boolean", defaultValue: true },
          width: { type: "string", defaultValue: "100%" },
          height: { type: "string", defaultValue: "500px" },
        },
        events: {
          // an item was clicked; `keys` is the selection afterwards
          itemPress: {
            parameters: {
              key: { type: "string" },
              selected: { type: "boolean" },
              keys: { type: "string" },
            },
          },
        },
      },

      _root() {
        return document.getElementById(this.getId());
      },

      _stage() {
        return document.getElementById(`${this.getId()}-stage`);
      },

      _stageSize() {
        const stage = this._stage();
        return { w: stage ? stage.clientWidth : 0, h: stage ? stage.clientHeight : 0 };
      },

      _selection() {
        return Util.toList(this.getSelectedKeys());
      },

      // ------------------------------------------------------------------
      // viewport
      // ------------------------------------------------------------------

      // The whole plan at the aspect ratio of the control's box - what the
      // fit button shows and what a zoom cannot leave.
      _homeView() {
        const size = this._stageSize();
        const all = FloorPlanMath.extent(this.getItems(), this.getAreas());
        if (!all || !size.w || !size.h) return null;
        return FloorPlanMath.fit(all, size.w / size.h);
      },

      _applyView(view) {
        if (!this._svg || !view) return;
        this._viewport = view;
        this._svg.setAttribute("viewBox", `${view.x} ${view.y} ${view.w} ${view.h}`);
        this._scheduleLabels();
      },

      // Every change the user makes goes through here: it is cut to the
      // limits, and it means the viewport is no longer "the whole plan".
      _moveTo(view) {
        const home = this._homeView();
        if (!home) return;
        this._atHome = false;
        this._applyView(FloorPlanMath.limit(view, home, MAX_ZOOM));
      },

      _zoomBy(factor, px, py) {
        if (!this._viewport) return;
        const size = this._stageSize();
        const x = px === undefined ? size.w / 2 : px;
        const y = py === undefined ? size.h / 2 : py;
        const point = this._toPlan(x, y);
        this._stopFlight();
        this._moveTo(FloorPlanMath.zoom(this._viewport, point.x, point.y, factor));
      },

      // pixel inside the stage -> plan units
      _toPlan(px, py) {
        const size = this._stageSize();
        const view = this._viewport;
        return {
          x: view.x + (px / size.w) * view.w,
          y: view.y + (py / size.h) * view.h,
        };
      },

      _stopFlight() {
        if (this._flight) window.cancelAnimationFrame(this._flight);
        this._flight = null;
      },

      // Animated change of the viewport. Somebody who asked the system for
      // reduced motion gets the result without the journey.
      _flyTo(target, atHome) {
        this._stopFlight();
        const from = this._viewport;
        const still =
          !from || (window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
        if (still) {
          this._applyView(target);
          this._atHome = atHome;
          return;
        }

        const started = window.performance.now();
        const step = (now) => {
          if (Util.isDestroyed(this) || !this._svg) return;
          const t = Math.min((now - started) / FLY_MS, 1);
          // ease out: fast first, settling at the end
          this._applyView(FloorPlanMath.blend(from, target, 1 - (1 - t) * (1 - t)));
          if (t < 1) {
            this._flight = window.requestAnimationFrame(step);
          } else {
            this._flight = null;
            this._atHome = atHome;
          }
        };
        this._flight = window.requestAnimationFrame(step);
      },

      // `fitKeys` as a viewport: the named items with some room around them,
      // or the whole plan when the list is empty or names nothing.
      _fitTarget() {
        const home = this._homeView();
        if (!home) return null;
        const keys = Util.toList(this.getFitKeys());
        const hits = keys.length ? FloorPlanMath.pick(this.getItems(), keys) : [];
        const around = hits.length ? FloorPlanMath.extent(hits, [], 0.35) : null;
        if (!around) return { view: home, atHome: true };
        const size = this._stageSize();
        const view = FloorPlanMath.limit(FloorPlanMath.fit(around, size.w / size.h), home, MAX_ZOOM);
        return { view, atHome: false };
      },

      _showFit(animated) {
        const target = this._fitTarget();
        if (!target) return;
        if (animated) {
          this._flyTo(target.view, target.atHome);
        } else {
          this._stopFlight();
          this._applyView(target.view);
          this._atHome = target.atHome;
        }
      },

      // ------------------------------------------------------------------
      // drawing
      // ------------------------------------------------------------------

      // Builds both layers from the bound tables. The viewport survives: a
      // refresh of the data must not throw the user back to the overview.
      _build() {
        const stage = this._stage();
        if (!stage) return;

        this._destroyLayers();

        const svg = svgNode("svg", { preserveAspectRatio: "none", focusable: "false" });
        Object.assign(svg.style, {
          position: "absolute",
          left: "0",
          top: "0",
          width: "100%",
          height: "100%",
          // the gestures are ours: without this a touch pans the page. A
          // fixed plan has no gestures and leaves the page its scrolling
          touchAction: this.getZoomable() ? "none" : "auto",
          cursor: this.getZoomable() ? "grab" : "default",
        });

        // diagonal lines for a blocked item, sized from the plan so the
        // pattern is neither a grey fog nor three lines at the default zoom
        const all = FloorPlanMath.extent(this.getItems(), this.getAreas());
        const tile = all ? Math.max(all.w, all.h) / 120 : 1;
        const patternId = `${this.getId()}-hatch`;
        const defs = svgNode("defs");
        const pattern = svgNode("pattern", {
          id: patternId,
          width: tile,
          height: tile,
          patternUnits: "userSpaceOnUse",
          patternTransform: "rotate(45)",
        });
        const stripe = svgNode("rect", { x: 0, y: 0, width: tile / 3, height: tile });
        stripe.style.fill = COLOURS.border;
        pattern.appendChild(stripe);
        defs.appendChild(pattern);
        svg.appendChild(defs);

        this._zones = [];
        (this.getAreas() || []).forEach((area) => {
          const b = box(area);
          if (!b.w || !b.h) return;
          const node = svgNode("rect", { "vector-effect": "non-scaling-stroke" });
          setBox(node, b);
          node.style.fill = "none";
          node.style.stroke = COLOURS.area;
          node.style.strokeWidth = "2";
          svg.appendChild(node);
          this._zones.push({ area, b, text: null });
        });

        this._shapes = [];
        (this.getItems() || []).forEach((item, index) => {
          const b = box(item);
          if (!b.w || !b.h) {
            Util.logError(`FloorPlan: item '${item?.KEY ?? ""}' has no size`);
            return;
          }

          const group = svgNode("g", { "data-index": index });
          // an item that takes no click does not look as if it did
          if (!item.DISABLED) group.style.cursor = "pointer";

          const frame = svgNode("rect", { "vector-effect": "non-scaling-stroke" });
          setBox(frame, b);
          frame.style.fill = COLOURS.box;

          const bar = svgNode("rect");
          setBox(bar, fillBar(item));
          bar.style.fill = colourOf(item);
          bar.style.fillOpacity = "0.85";
          // the frame takes the pointer, so a click on the empty part of a
          // box and one on its bar are the same click
          bar.style.pointerEvents = "none";

          group.appendChild(frame);
          group.appendChild(bar);

          if (item.BLOCKED) {
            const hatch = svgNode("rect");
            setBox(hatch, b);
            hatch.style.fill = `url(#${patternId})`;
            hatch.style.fillOpacity = "0.45";
            hatch.style.pointerEvents = "none";
            group.appendChild(hatch);
          }

          // the browser's own tooltip: everything the item says about
          // itself, whatever the zoom shows of it
          const words = linesOf(item).filter((line) => line !== undefined && line !== null && line !== "");
          if (words.length) {
            const title = svgNode("title");
            title.textContent = words.join("\n");
            group.appendChild(title);
          }

          svg.appendChild(group);
          this._shapes.push({ item, b, group, frame, text: null });
        });

        const labels = svgNode("svg", { focusable: "false", "aria-hidden": "true" });
        Object.assign(labels.style, {
          position: "absolute",
          left: "0",
          top: "0",
          width: "100%",
          height: "100%",
          pointerEvents: "none",
          fontSize: `${FONT_PX}px`,
        });

        stage.appendChild(svg);
        stage.appendChild(labels);
        this._svg = svg;
        this._labels = labels;

        this._wire(svg);
        this._paint();

        // First drawing, or the user never left the overview: show what
        // fitKeys asks for. Otherwise the viewport is the user's.
        const size = this._stageSize();
        if (!this._viewport || this._atHome !== false || !this.getZoomable()) {
          // a fixed plan has no viewport of the user's to keep
          this._showFit(false);
        } else if (size.w && size.h) {
          this._applyView(FloorPlanMath.reshape(this._viewport, size.w / size.h));
        }
      },

      // Selection and highlight are presentation only, so they are painted
      // onto the shapes that are there instead of building new ones.
      _paint() {
        const selection = this._selection();
        const highlight = Util.toList(this.getHighlightKeys());

        (this._shapes || []).forEach((shape) => {
          const key = String(shape.item.KEY ?? "");
          const selected = selection.includes(key);
          shape.frame.style.stroke = selected ? COLOURS.selected : COLOURS.border;
          shape.frame.style.strokeWidth = selected ? "3" : "1";
          shape.dimmed = highlight.length > 0 && !highlight.includes(key);
          shape.group.style.opacity = shape.dimmed ? "0.25" : "1";
          if (shape.text) shape.text.style.opacity = shape.dimmed ? "0.25" : "1";
          // a selected frame must not be half hidden under its neighbours
          if (selected) shape.group.parentNode.appendChild(shape.group);
        });
      },

      _scheduleLabels() {
        if (this._labelFrame) return;
        this._labelFrame = window.requestAnimationFrame(() => {
          this._labelFrame = null;
          if (Util.isDestroyed(this) || !this._svg) return;
          this._placeLabels();
        });
      },

      _textNode(colour, weight) {
        const node = svgNode("text", { "text-anchor": "middle" });
        node.style.fill = colour;
        node.style.fontWeight = weight;
        // a halo in the box colour keeps a label readable on top of a bar
        node.style.paintOrder = "stroke";
        node.style.stroke = COLOURS.box;
        node.style.strokeWidth = "2.5px";
        node.style.strokeOpacity = "0.8";
        node.style.strokeLinejoin = "round";
        this._labels.appendChild(node);
        return node;
      },

      // Places the text of everything that is on screen and big enough, in
      // pixels. This is the level of detail, and it runs on every change of
      // the viewport - so it creates nothing it does not show.
      _placeLabels() {
        const view = this._viewport;
        const size = this._stageSize();
        if (!view || !size.w || !size.h) return;
        const scale = size.w / view.w;

        const onScreen = (b) => ({
          x: (b.x - view.x) * scale,
          y: (b.y - view.y) * scale,
          w: b.w * scale,
          h: b.h * scale,
        });
        const visible = (p) => p.x < size.w && p.y < size.h && p.x + p.w > 0 && p.y + p.h > 0;

        (this._shapes || []).forEach((shape) => {
          const p = onScreen(shape.b);
          const lines = linesOf(shape.item);
          const layout = visible(p) ? labelLayout(p.w, p.h, lines, FONT_PX) : { count: 0 };

          if (!layout.count) {
            if (shape.text) shape.text.style.display = "none";
            return;
          }

          if (!shape.text) shape.text = this._textNode(COLOURS.text, "normal");
          const text = shape.text;
          const shown = lines
            .filter((line) => line !== undefined && line !== null && String(line) !== "")
            .slice(0, layout.count);

          // rebuilt only when the number of lines changes, not on every pan
          const signature = shown.join("\n");
          if (text.__lines !== signature) {
            text.__lines = signature;
            while (text.firstChild) text.removeChild(text.firstChild);
            shown.forEach((line, row) => {
              const span = svgNode("tspan");
              span.textContent = String(line);
              if (row === 0) span.style.fontWeight = "bold";
              text.appendChild(span);
            });
          }

          const cx = p.x + p.w / 2;
          const cy = p.y + p.h / 2;
          const first = cy - ((shown.length - 1) * LINE_PX) / 2 + FONT_PX * 0.35;
          Array.from(text.childNodes).forEach((span, row) => {
            span.setAttribute("x", String(cx));
            span.setAttribute("y", String(first + row * LINE_PX));
          });
          if (layout.vertical) text.setAttribute("transform", `rotate(-90 ${cx} ${cy})`);
          else text.removeAttribute("transform");
          text.style.opacity = shape.dimmed ? "0.25" : "1";
          text.style.display = "";
        });

        // an area's title sits in its top left corner, once it has the room
        (this._zones || []).forEach((zone) => {
          const p = onScreen(zone.b);
          const title = String(zone.area.TITLE ?? "");
          const fits = title && visible(p) && p.h > 30 && title.length * FONT_PX * 0.65 < p.w - 12;
          if (!fits) {
            if (zone.text) zone.text.style.display = "none";
            return;
          }
          if (!zone.text) {
            zone.text = this._textNode(COLOURS.label, "bold");
            zone.text.setAttribute("text-anchor", "start");
            zone.text.textContent = title;
          }
          // kept on screen while its area is, like a sticky table header
          zone.text.setAttribute("x", String(Math.max(p.x, 0) + 6));
          zone.text.setAttribute("y", String(Math.max(p.y, 0) + FONT_PX + 4));
          zone.text.style.display = "";
        });
      },

      // ------------------------------------------------------------------
      // input
      // ------------------------------------------------------------------

      _press(item) {
        // drawn, but not to be clicked: no event and no selection
        if (item.DISABLED) return;
        const key = String(item.KEY ?? "");
        const mode = String(this.getSelectionMode() || "").toLowerCase();

        if (mode === "none") {
          this.fireItemPress({ key, selected: false, keys: this.getSelectedKeys() });
          return;
        }

        let list = this._selection();
        const at = list.indexOf(key);
        const wasSelected = at >= 0;

        if (mode === "multi") {
          if (wasSelected) list.splice(at, 1);
          else list.push(key);
        } else {
          list = wasSelected ? [] : [key];
        }

        const keys = list.join(",");
        // suppressInvalidate: the selection is painted here, a re-render
        // would only build the same shapes again
        this.setProperty("selectedKeys", keys, true);
        this._paint();
        this.fireItemPress({ key, selected: !wasSelected, keys });
      },

      // One set of pointer handlers for mouse, pen and touch: one pointer
      // pans, two pinch, and a pointer that went down and up in place is a
      // click on the item under it.
      _wire(svg) {
        const pointers = new Map();
        let moved = false;
        let target = null;
        let targetGroup = null;
        let pinch = null;
        const zoomable = this.getZoomable();

        const local = (event) => {
          const rect = svg.getBoundingClientRect();
          return { x: event.clientX - rect.left, y: event.clientY - rect.top };
        };

        const pinchState = () => {
          const [a, b] = Array.from(pointers.values());
          return {
            distance: Math.hypot(a.x - b.x, a.y - b.y) || 1,
            x: (a.x + b.x) / 2,
            y: (a.y + b.y) / 2,
          };
        };

        svg.addEventListener("pointerdown", (event) => {
          if (event.pointerType === "mouse" && event.button !== 0) return;
          const point = local(event);
          pointers.set(event.pointerId, point);
          if (pointers.size === 1) {
            moved = false;
            const group = event.target.closest ? event.target.closest("[data-index]") : null;
            target = group ? this.getItems()[Number(group.getAttribute("data-index"))] : null;
            targetGroup = group;
          } else {
            // a second finger: this is a gesture, never a click
            moved = true;
            pinch = pinchState();
          }
          // keeps the drag alive when the pointer leaves the control - a
          // fixed plan has no drag, and without the capture the pointer that
          // comes up says which item it is over
          if (zoomable && svg.setPointerCapture) svg.setPointerCapture(event.pointerId);
          this._stopFlight();
        });

        svg.addEventListener("pointermove", (event) => {
          const last = pointers.get(event.pointerId);
          if (!last || !this._viewport || !zoomable) return;
          const point = local(event);
          const size = this._stageSize();

          if (pointers.size >= 2) {
            pointers.set(event.pointerId, point);
            const now = pinchState();
            const anchor = this._toPlan(pinch.x, pinch.y);
            let view = FloorPlanMath.zoom(this._viewport, anchor.x, anchor.y, now.distance / pinch.distance);
            // two fingers that move together drag the plan along
            view = {
              ...view,
              x: view.x - ((now.x - pinch.x) / size.w) * view.w,
              y: view.y - ((now.y - pinch.y) / size.h) * view.h,
            };
            pinch = now;
            this._moveTo(view);
            return;
          }

          const dx = point.x - last.x;
          const dy = point.y - last.y;
          if (!moved && Math.hypot(dx, dy) < DRAG_PX) return;
          moved = true;
          svg.style.cursor = "grabbing";
          pointers.set(event.pointerId, point);
          this._moveTo({
            ...this._viewport,
            x: this._viewport.x - (dx / size.w) * this._viewport.w,
            y: this._viewport.y - (dy / size.h) * this._viewport.h,
          });
        });

        const release = (event, cancelled) => {
          if (!pointers.has(event.pointerId)) return;
          pointers.delete(event.pointerId);
          if (pointers.size >= 2) pinch = pinchState();
          if (pointers.size) return;
          if (zoomable) svg.style.cursor = "grab";
          // On a fixed plan a finger that slipped a little is still a tap,
          // as long as it comes up on the item it went down on. A scroll of
          // the page arrives as a cancel and is no click.
          const over = event.target && event.target.closest ? event.target.closest("[data-index]") : null;
          const same = zoomable || over === targetGroup;
          if (!cancelled && !moved && target && same) this._press(target);
          target = null;
          targetGroup = null;
        };
        svg.addEventListener("pointerup", (event) => release(event, false));
        svg.addEventListener("pointercancel", (event) => release(event, true));

        // not passive: the wheel zooms the plan instead of scrolling the page
        svg.addEventListener(
          "wheel",
          (event) => {
            // a fixed plan lets the wheel scroll the page
            if (!this._viewport || !zoomable) return;
            event.preventDefault();
            const point = local(event);
            // deltaMode 1 counts lines, not pixels
            const delta = event.deltaMode === 1 ? event.deltaY * 16 : event.deltaY;
            this._zoomBy(Math.exp(-delta * 0.0015), point.x, point.y);
          },
          { passive: false },
        );
      },

      // The plan itself is one tab stop: + and - zoom, 0 shows all, the
      // arrow keys pan.
      onkeydown(event) {
        if (!this._viewport || !this.getZoomable() || event.target !== this._root()) return;
        const stepX = this._viewport.w * 0.15;
        const stepY = this._viewport.h * 0.15;
        const pan = (dx, dy) => this._moveTo({ ...this._viewport, x: this._viewport.x + dx, y: this._viewport.y + dy });

        switch (event.key) {
          case "+":
          case "=":
            this._zoomBy(1.4);
            break;
          case "-":
            this._zoomBy(1 / 1.4);
            break;
          case "0":
            this._showAll();
            break;
          case "ArrowLeft":
            pan(-stepX, 0);
            break;
          case "ArrowRight":
            pan(stepX, 0);
            break;
          case "ArrowUp":
            pan(0, -stepY);
            break;
          case "ArrowDown":
            pan(0, stepY);
            break;
          default:
            return;
        }
        event.preventDefault();
      },

      _showAll() {
        const home = this._homeView();
        if (home) this._flyTo(home, true);
      },

      // the three buttons in the corner
      onclick(event) {
        const button = event.target.closest ? event.target.closest("[data-action]") : null;
        if (!button) return;
        const action = button.getAttribute("data-action");
        if (action === "in") this._zoomBy(1.4);
        else if (action === "out") this._zoomBy(1 / 1.4);
        else this._showAll();
      },

      // ------------------------------------------------------------------
      // properties that change without a re-render
      // ------------------------------------------------------------------

      setItems(value) {
        this.setProperty("items", value, true);
        if (this._svg) this._build();
        return this;
      },

      setAreas(value) {
        this.setProperty("areas", value, true);
        if (this._svg) this._build();
        return this;
      },

      setSelectedKeys(value) {
        this.setProperty("selectedKeys", value, true);
        if (this._svg) this._paint();
        return this;
      },

      setHighlightKeys(value) {
        this.setProperty("highlightKeys", value, true);
        if (this._svg) this._paint();
        return this;
      },

      setFitKeys(value) {
        this.setProperty("fitKeys", value, true);
        if (this._svg) this._showFit(true);
        return this;
      },

      // ------------------------------------------------------------------
      // lifecycle
      // ------------------------------------------------------------------

      _destroyLayers() {
        this._stopFlight();
        if (this._labelFrame) window.cancelAnimationFrame(this._labelFrame);
        this._labelFrame = null;
        [this._svg, this._labels].forEach((node) => {
          if (node && node.parentNode) node.parentNode.removeChild(node);
        });
        this._svg = null;
        this._labels = null;
        this._shapes = [];
        this._zones = [];
      },

      _unobserve() {
        if (this._resizeObserver) this._resizeObserver.disconnect();
        this._resizeObserver = null;
        if (this._onResize) window.removeEventListener("resize", this._onResize);
        this._onResize = null;
      },

      onBeforeRendering() {
        this._unobserve();
        this._destroyLayers();
      },

      onAfterRendering() {
        this._build();

        // The viewport has the aspect ratio of the box, so it has to follow
        // when the box changes shape - a resized window, a side panel.
        const stage = this._stage();
        const onResize = () => {
          if (Util.isDestroyed(this) || !this._svg) return;
          const size = this._stageSize();
          if (!size.w || !size.h) return;
          // a control that was rendered hidden gets its first viewport here
          if (!this._viewport || this._atHome !== false) this._showFit(false);
          else this._applyView(FloorPlanMath.reshape(this._viewport, size.w / size.h));
        };
        if (stage && window.ResizeObserver) {
          this._resizeObserver = new window.ResizeObserver(onResize);
          this._resizeObserver.observe(stage);
        } else {
          this._onResize = onResize;
          window.addEventListener("resize", onResize);
        }
      },

      exit() {
        this._unobserve();
        this._destroyLayers();
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          rm.openStart("div", control);
          // the tab stop is for the keys that move the view - a fixed plan
          // has none to offer
          if (control.getZoomable()) rm.attr("tabindex", "0");
          rm.attr("role", "group");
          rm.attr("aria-label", "Floor plan");
          rm.style("position", "relative");
          rm.style("box-sizing", "border-box");
          rm.style("width", Util.toCssSize(control.getWidth()));
          rm.style("height", Util.toCssSize(control.getHeight()));
          rm.style("background", COLOURS.background);
          rm.style("user-select", "none");
          rm.style("-webkit-user-select", "none");
          rm.openEnd();

          // The stage is what the two SVG layers are measured against. It
          // clips them: a zoomed plan must not paint over its neighbours.
          rm.openStart("div", `${control.getId()}-stage`);
          rm.style("position", "absolute");
          rm.style("left", "0");
          rm.style("top", "0");
          rm.style("right", "0");
          rm.style("bottom", "0");
          rm.style("overflow", "hidden");
          rm.openEnd();
          rm.close("div");

          if (control.getShowControls() && control.getZoomable()) {
            rm.openStart("div", `${control.getId()}-controls`);
            rm.style("position", "absolute");
            rm.style("top", "0.5rem");
            rm.style("right", "0.5rem");
            rm.style("display", "flex");
            rm.style("flex-direction", "column");
            rm.style("gap", "0.25rem");
            rm.openEnd();
            [
              ["in", "+", "Zoom in"],
              ["out", "−", "Zoom out"],
              ["all", "▢", "Show all"],
            ].forEach(([action, sign, label]) => {
              rm.openStart("button");
              rm.attr("type", "button");
              rm.attr("data-action", action);
              rm.attr("title", label);
              rm.attr("aria-label", label);
              rm.style("width", "2rem");
              rm.style("height", "2rem");
              rm.style("padding", "0");
              rm.style("font-size", "1rem");
              rm.style("line-height", "1");
              rm.style("cursor", "pointer");
              rm.style("border-radius", "0.25rem");
              rm.style("border", `1px solid ${COLOURS.buttonBorder}`);
              rm.style("background", COLOURS.button);
              rm.style("color", COLOURS.buttonText);
              rm.openEnd();
              rm.text(sign);
              rm.close("button");
            });
            rm.close("div");
          }

          rm.close("div");
        },
      },
    });
  },
);
