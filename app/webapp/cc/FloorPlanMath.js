// z2ui5_cci.cc.FloorPlanMath - the arithmetic behind the FloorPlan control.
//
// Everything in here is a pure function of plain numbers and rows: where the
// viewport is after a zoom, how far a bar is filled, whether a label fits a
// box of so many pixels. That is the part of the control that can be wrong in
// ways nobody sees at once - a zoom that drifts away from the mouse pointer, a
// bar that fills from the wrong end, a label that overlaps its neighbour - and
// out here tools/floor-plan.test.mjs can check it without a browser.
//
// (The test lives under tools/ rather than next to this file because
// everything under app/webapp/ is turned into a BSP page by app2bsp.)
sap.ui.define([], () => {
  "use strict";

  // ABAP sends numbers, but a packed number may arrive as a string and an
  // initial value does not arrive at all (omit_initial drops it).
  const num = (value, fallback = 0) => {
    const parsed = typeof value === "number" ? value : Number.parseFloat(value);
    return Number.isFinite(parsed) ? parsed : fallback;
  };

  const clamp = (value, low, high) => Math.min(Math.max(value, low), high);

  const box = (row) => ({
    x: num(row?.X),
    y: num(row?.Y),
    w: Math.max(num(row?.WIDTH), 0),
    h: Math.max(num(row?.HEIGHT), 0),
  });

  // The value states an ABAP developer knows from UI5, plus the theme colour
  // each one stands for. The literal is the fallback for a theme that defines
  // no CSS variables (everything before UI5 1.84, and sap_belize).
  const STATES = {
    none: "var(--sapNeutralColor,#6a6d70)",
    success: "var(--sapPositiveColor,#107e3e)",
    warning: "var(--sapCriticalColor,#e9730c)",
    error: "var(--sapNegativeColor,#bb0000)",
    information: "var(--sapInformativeColor,#0a6ed1)",
  };

  /**
   * The colour an item's bar is painted with: its own COLOR when it has one,
   * else the colour of its STATE.
   */
  function colourOf(item) {
    const own = String(item?.COLOR ?? "").trim();
    if (own) return own;
    return STATES[String(item?.STATE ?? "").trim().toLowerCase()] || STATES.none;
  }

  /**
   * The rectangle that holds every item and area, grown by `padding` (a
   * fraction of the larger side) so nothing touches the edge of the control.
   *
   * @returns {{x,y,w,h}|null}  null when there is nothing with a size
   */
  function extent(items, areas, padding = 0.04) {
    let x1 = Infinity;
    let y1 = Infinity;
    let x2 = -Infinity;
    let y2 = -Infinity;

    [...(areas || []), ...(items || [])].forEach((row) => {
      const b = box(row);
      if (!b.w || !b.h) return;
      x1 = Math.min(x1, b.x);
      y1 = Math.min(y1, b.y);
      x2 = Math.max(x2, b.x + b.w);
      y2 = Math.max(y2, b.y + b.h);
    });

    if (!Number.isFinite(x1)) return null;

    const pad = Math.max(x2 - x1, y2 - y1) * padding;
    return { x: x1 - pad, y: y1 - pad, w: x2 - x1 + 2 * pad, h: y2 - y1 + 2 * pad };
  }

  /**
   * The smallest viewport of the given aspect ratio (width / height) that
   * shows all of `target`, centred on it.
   *
   * The control keeps its viewport at the aspect ratio of its own box. That
   * makes one user unit the same number of pixels in both directions, so
   * `pixels / view.w` is THE scale and nothing has to ask the browser for a
   * transformation matrix.
   */
  function fit(target, aspect) {
    const ratio = aspect > 0 ? aspect : 1;
    let { w, h } = target;
    if (w / h < ratio) w = h * ratio;
    else h = w / ratio;
    return {
      x: target.x + target.w / 2 - w / 2,
      y: target.y + target.h / 2 - h / 2,
      w,
      h,
    };
  }

  /**
   * Zooms by `factor` (> 1 is closer) while the plan point (cx, cy) stays
   * under the same pixel - which is what makes a wheel zoom feel like it
   * follows the pointer.
   */
  function zoom(view, cx, cy, factor) {
    const f = factor > 0 ? factor : 1;
    const w = view.w / f;
    const h = view.h / f;
    return {
      x: cx - ((cx - view.x) / view.w) * w,
      y: cy - ((cy - view.y) / view.h) * h,
      w,
      h,
    };
  }

  /**
   * Keeps a viewport usable: not further out than `home` (the whole plan),
   * not closer than `maxZoom` times that, and never so far off to one side
   * that the plan has left the screen.
   */
  function limit(view, home, maxZoom = 40) {
    const w = clamp(view.w, home.w / maxZoom, home.w);
    const h = w * (view.h / view.w);
    // zooming is anchored on a point, so a clamped size must keep the centre
    let x = view.x + (view.w - w) / 2;
    let y = view.y + (view.h - h) / 2;
    // the centre of the viewport stays inside the plan
    x = clamp(x, home.x - w / 2, home.x + home.w - w / 2);
    y = clamp(y, home.y - h / 2, home.y + home.h - h / 2);
    return { x, y, w, h };
  }

  /**
   * The viewport after the control's box changed shape: same centre, same
   * scale along the width, new height.
   */
  function reshape(view, aspect) {
    const ratio = aspect > 0 ? aspect : 1;
    const h = view.w / ratio;
    return { x: view.x, y: view.y + (view.h - h) / 2, w: view.w, h };
  }

  /** Linear blend of two viewports, for the fly-to animation. */
  function blend(from, to, t) {
    const mix = (a, b) => a + (b - a) * t;
    return { x: mix(from.x, to.x), y: mix(from.y, to.y), w: mix(from.w, to.w), h: mix(from.h, to.h) };
  }

  /**
   * The filled part of an item, as a rectangle in plan units.
   *
   * FILL is a share from 0 to 1. DIR says which way the item fills up -
   * `up`, `down`, `left` or `right`; without one it fills along its longer
   * side, from the bottom or from the left. A storage lane is the picture
   * behind that default: it is long and narrow and fills from the back.
   */
  function fillBar(item) {
    const b = box(item);
    const share = clamp(num(item?.FILL), 0, 1);
    let dir = String(item?.DIR ?? "").trim().toLowerCase();
    if (!["up", "down", "left", "right"].includes(dir)) dir = b.h >= b.w ? "up" : "right";

    switch (dir) {
      case "up":
        return { x: b.x, y: b.y + b.h * (1 - share), w: b.w, h: b.h * share };
      case "down":
        return { x: b.x, y: b.y, w: b.w, h: b.h * share };
      case "left":
        return { x: b.x + b.w * (1 - share), y: b.y, w: b.w * share, h: b.h };
      default:
        return { x: b.x, y: b.y, w: b.w * share, h: b.h };
    }
  }

  // An average glyph is about 0.6 em wide in the UI5 fonts; measuring every
  // label in the DOM would cost a layout per item and frame.
  const GLYPH = 0.6;
  const LINE = 1.3;

  const linesThatFit = (width, height, lines, fontPx) => {
    const rows = Math.floor((height - 4) / (fontPx * LINE));
    let count = 0;
    while (count < lines.length && count < rows) {
      if (String(lines[count]).length * fontPx * GLYPH > width - 6) break;
      count += 1;
    }
    return count;
  };

  /**
   * How much of an item's text can be shown in a box of `width` x `height`
   * PIXELS. This is the level of detail: zoomed out a box shows nothing,
   * closer its title, closer still the lines below it.
   *
   * The lines are tried in order and the first one that does not fit ends the
   * list - a detail line without the title above it would mean nothing. A box
   * that is taller than wide is tried sideways as well, and the text is
   * turned when that shows more of it.
   *
   * @returns {{count:number, vertical:boolean}}
   */
  function labelLayout(width, height, lines, fontPx = 12) {
    const list = (lines || []).filter((line) => line !== undefined && line !== null && String(line) !== "");
    if (!list.length) return { count: 0, vertical: false };

    const flat = linesThatFit(width, height, list, fontPx);
    const turned = height > width ? linesThatFit(height, width, list, fontPx) : 0;
    return turned > flat ? { count: turned, vertical: true } : { count: flat, vertical: false };
  }

  /** The rows whose KEY is in `keys`. */
  const pick = (rows, keys) => (rows || []).filter((row) => row && keys.includes(String(row.KEY ?? "")));

  return {
    STATES,
    blend,
    box,
    clamp,
    colourOf,
    extent,
    fillBar,
    fit,
    labelLayout,
    limit,
    num,
    pick,
    reshape,
    zoom,
  };
});
