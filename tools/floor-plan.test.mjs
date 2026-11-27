// Tests for the FloorPlan control: the viewport, fill and label arithmetic in
// app/webapp/cc/FloorPlanMath.js, and the selection logic in
// app/webapp/cc/FloorPlan.js.
//
// Both are UI5 AMD modules and are loaded through the same small shim the
// ImageMapster tests use: Control.extend hands the definition object straight
// back, which is enough to call the methods that touch properties and the
// selection rather than the DOM.
//
// What this cannot cover: the drawing, the gestures and the UI5 lifecycle -
// those need a browser.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function amd(file, dependencies = {}) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", file), "utf8");
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map((name) => dependencies[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const M = amd("FloorPlanMath.js");

const FloorPlan = amd("FloorPlan.js", {
  "sap/ui/core/Control": { extend: (name, definition) => definition },
  "z2ui5_cci/cc/Util": {
    toList: (value) =>
      String(value || "")
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean),
    logError: () => {},
    isDestroyed: () => false,
    toCssSize: (value) => String(value ?? ""),
  },
  "z2ui5_cci/cc/FloorPlanMath": M,
});

function mockControl({ selectionMode = "Single", selectedKeys = "" } = {}) {
  const control = Object.create(FloorPlan);
  control._selectedKeys = selectedKeys;
  control.fired = [];
  control.painted = 0;
  control.getSelectionMode = () => selectionMode;
  control.getSelectedKeys = () => control._selectedKeys;
  control.setProperty = (name, value) => {
    if (name === "selectedKeys") control._selectedKeys = value;
  };
  control.fireItemPress = (payload) => control.fired.push(payload);
  control._paint = () => {
    control.painted += 1;
  };
  return control;
}

const close = (actual, expected, what) =>
  assert.ok(Math.abs(actual - expected) < 1e-9, `${what}: ${actual} is not ${expected}`);

// ---------------------------------------------------------------------------
// numbers from ABAP
// ---------------------------------------------------------------------------

test("FloorPlan: a number may arrive as a string or not at all", () => {
  assert.equal(M.num(2.5), 2.5);
  assert.equal(M.num("2.5"), 2.5);
  assert.equal(M.num(undefined), 0);
  assert.equal(M.num("", 7), 7);
  assert.deepEqual(M.box({ X: "1", WIDTH: 3, HEIGHT: "4" }), { x: 1, y: 0, w: 3, h: 4 });
});

// ---------------------------------------------------------------------------
// extent and viewport
// ---------------------------------------------------------------------------

test("FloorPlan: the extent holds items and areas", () => {
  const all = M.extent([{ X: 10, Y: 10, WIDTH: 10, HEIGHT: 10 }], [{ X: 0, Y: 0, WIDTH: 100, HEIGHT: 50 }], 0);
  assert.deepEqual(all, { x: 0, y: 0, w: 100, h: 50 });
});

test("FloorPlan: the padding is a share of the larger side, on every edge", () => {
  const all = M.extent([{ X: 0, Y: 0, WIDTH: 100, HEIGHT: 50 }], [], 0.1);
  assert.deepEqual(all, { x: -10, y: -10, w: 120, h: 70 });
});

test("FloorPlan: rows without a size do not count, and nothing is no extent", () => {
  assert.equal(M.extent([{ X: 5, Y: 5 }], []), null);
  assert.equal(M.extent([], undefined), null);
});

test("FloorPlan: fit centres the target in a viewport of the box's shape", () => {
  // a square plan in a box twice as wide as high
  const view = M.fit({ x: 0, y: 0, w: 100, h: 100 }, 2);
  assert.deepEqual(view, { x: -50, y: 0, w: 200, h: 100 });
  // and in one twice as high as wide
  assert.deepEqual(M.fit({ x: 0, y: 0, w: 100, h: 100 }, 0.5), { x: 0, y: -50, w: 100, h: 200 });
});

test("FloorPlan: a zoom keeps the point under the pointer where it is", () => {
  const view = { x: 0, y: 0, w: 200, h: 100 };
  const next = M.zoom(view, 150, 25, 2);
  assert.equal(next.w, 100);
  assert.equal(next.h, 50);
  // (150, 25) was at 75 % / 25 % of the viewport and still is
  close((150 - next.x) / next.w, 0.75, "x share");
  close((25 - next.y) / next.h, 0.25, "y share");
});

test("FloorPlan: zooming in and out again ends where it started", () => {
  const view = { x: 3, y: 7, w: 200, h: 100 };
  const back = M.zoom(M.zoom(view, 40, 60, 3), 40, 60, 1 / 3);
  ["x", "y", "w", "h"].forEach((key) => close(back[key], view[key], key));
});

test("FloorPlan: the viewport cannot go further out than the whole plan", () => {
  const home = { x: 0, y: 0, w: 200, h: 100 };
  const out = M.limit(M.zoom(home, 100, 50, 0.1), home);
  assert.deepEqual(out, home);
});

test("FloorPlan: the viewport cannot go closer than the maximum zoom", () => {
  const home = { x: 0, y: 0, w: 200, h: 100 };
  const near = M.limit(M.zoom(home, 100, 50, 1000), home, 40);
  close(near.w, 5, "width");
  close(near.h, 2.5, "height");
  // still centred on the point it zoomed to
  close(near.x + near.w / 2, 100, "centre x");
  close(near.y + near.h / 2, 50, "centre y");
});

test("FloorPlan: a pan cannot push the plan off the screen", () => {
  const home = { x: 0, y: 0, w: 200, h: 100 };
  const far = M.limit({ x: 5000, y: -5000, w: 50, h: 25 }, home);
  // the centre of the viewport stops at the edge of the plan
  close(far.x + far.w / 2, 200, "centre x");
  close(far.y + far.h / 2, 0, "centre y");
});

test("FloorPlan: a resized box keeps the centre and the scale", () => {
  const view = M.reshape({ x: 0, y: 0, w: 200, h: 100 }, 4);
  assert.deepEqual(view, { x: 0, y: 25, w: 200, h: 50 });
});

test("FloorPlan: the fly-to starts at one viewport and ends at the other", () => {
  const from = { x: 0, y: 0, w: 200, h: 100 };
  const to = { x: 50, y: 20, w: 20, h: 10 };
  assert.deepEqual(M.blend(from, to, 0), from);
  assert.deepEqual(M.blend(from, to, 1), to);
  assert.deepEqual(M.blend(from, to, 0.5), { x: 25, y: 10, w: 110, h: 55 });
});

// ---------------------------------------------------------------------------
// fill level
// ---------------------------------------------------------------------------

const LANE = { X: 10, Y: 20, WIDTH: 4, HEIGHT: 40 };
const SHELF = { X: 10, Y: 20, WIDTH: 40, HEIGHT: 4 };

test("FloorPlan: a tall item fills from the bottom", () => {
  assert.deepEqual(M.fillBar({ ...LANE, FILL: 0.25 }), { x: 10, y: 50, w: 4, h: 10 });
});

test("FloorPlan: a wide item fills from the left", () => {
  assert.deepEqual(M.fillBar({ ...SHELF, FILL: 0.25 }), { x: 10, y: 20, w: 10, h: 4 });
});

test("FloorPlan: DIR overrides the default, in all four directions", () => {
  assert.deepEqual(M.fillBar({ ...LANE, FILL: 0.25, DIR: "down" }), { x: 10, y: 20, w: 4, h: 10 });
  assert.deepEqual(M.fillBar({ ...LANE, FILL: 0.25, DIR: "right" }), { x: 10, y: 20, w: 1, h: 40 });
  assert.deepEqual(M.fillBar({ ...LANE, FILL: 0.25, DIR: "LEFT" }), { x: 13, y: 20, w: 1, h: 40 });
  assert.deepEqual(M.fillBar({ ...SHELF, FILL: 0.25, DIR: "up" }), { x: 10, y: 23, w: 40, h: 1 });
});

test("FloorPlan: the fill is a share between nothing and everything", () => {
  assert.equal(M.fillBar({ ...LANE }).h, 0);
  assert.equal(M.fillBar({ ...LANE, FILL: -1 }).h, 0);
  assert.equal(M.fillBar({ ...LANE, FILL: 1.7 }).h, 40);
  assert.equal(M.fillBar({ ...LANE, FILL: "0.5" }).h, 20);
});

// ---------------------------------------------------------------------------
// colours
// ---------------------------------------------------------------------------

test("FloorPlan: a state is a theme colour with a fallback", () => {
  assert.equal(M.colourOf({ STATE: "Error" }), "var(--sapNegativeColor,#bb0000)");
  assert.equal(M.colourOf({ STATE: "success" }), M.STATES.success);
  assert.equal(M.colourOf({}), M.STATES.none);
  assert.equal(M.colourOf({ STATE: "no such state" }), M.STATES.none);
});

test("FloorPlan: an item's own colour wins over its state", () => {
  assert.equal(M.colourOf({ STATE: "Error", COLOR: "#123456" }), "#123456");
  assert.equal(M.colourOf({ STATE: "Error", COLOR: "  " }), M.STATES.error);
});

// ---------------------------------------------------------------------------
// level of detail
// ---------------------------------------------------------------------------

test("FloorPlan: a small box shows no text", () => {
  assert.deepEqual(M.labelLayout(10, 10, ["7001", "OSB 12 mm"]), { count: 0, vertical: false });
});

test("FloorPlan: a box shows as many lines as it is high", () => {
  const lines = ["7001", "OSB 12 mm", "78 %"];
  assert.equal(M.labelLayout(200, 24, lines).count, 1);
  assert.equal(M.labelLayout(200, 40, lines).count, 2);
  assert.equal(M.labelLayout(200, 60, lines).count, 3);
});

test("FloorPlan: a line that is too wide ends the list", () => {
  // the title fits 60 px, the second line does not - and the third is not
  // shown without it
  const lines = ["7001", "OSB 3 N+F 2500x675x22", "78 %"];
  assert.deepEqual(M.labelLayout(60, 200, ["7001"]), { count: 1, vertical: false });
  assert.equal(M.labelLayout(60, 30, lines).count, 1);
});

test("FloorPlan: a tall, narrow box turns its text when that shows more", () => {
  const lines = ["7001", "OSB 3 N+F 2500x675x22"];
  const layout = M.labelLayout(40, 300, lines);
  assert.deepEqual(layout, { count: 2, vertical: true });
  // a wide box is never turned
  assert.equal(M.labelLayout(300, 40, lines).vertical, false);
});

test("FloorPlan: empty lines are not lines", () => {
  assert.deepEqual(M.labelLayout(500, 500, ["", undefined, null]), { count: 0, vertical: false });
  assert.equal(M.labelLayout(500, 500, ["7001", "", "78 %"]).count, 2);
});

// ---------------------------------------------------------------------------
// picking rows
// ---------------------------------------------------------------------------

test("FloorPlan: rows are picked by key", () => {
  const rows = [{ KEY: "a" }, { KEY: "b" }, { KEY: 3 }, null];
  assert.deepEqual(M.pick(rows, ["b", "3"]), [{ KEY: "b" }, { KEY: 3 }]);
  assert.deepEqual(M.pick(undefined, ["a"]), []);
});

// ---------------------------------------------------------------------------
// selection
// ---------------------------------------------------------------------------

test("FloorPlan: Single selects one item and a second click clears it", () => {
  const control = mockControl();
  control._press({ KEY: "a" });
  assert.deepEqual(control.fired.pop(), { key: "a", selected: true, keys: "a" });
  control._press({ KEY: "b" });
  assert.deepEqual(control.fired.pop(), { key: "b", selected: true, keys: "b" });
  control._press({ KEY: "b" });
  assert.deepEqual(control.fired.pop(), { key: "b", selected: false, keys: "" });
  assert.equal(control.painted, 3);
});

test("FloorPlan: Multi toggles each item on its own", () => {
  const control = mockControl({ selectionMode: "Multi", selectedKeys: "a" });
  control._press({ KEY: "b" });
  assert.equal(control._selectedKeys, "a,b");
  control._press({ KEY: "a" });
  assert.deepEqual(control.fired.pop(), { key: "a", selected: false, keys: "b" });
});

test("FloorPlan: None reports the click and selects nothing", () => {
  const control = mockControl({ selectionMode: "None", selectedKeys: "x" });
  control._press({ KEY: "a" });
  assert.deepEqual(control.fired.pop(), { key: "a", selected: false, keys: "x" });
  assert.equal(control._selectedKeys, "x");
  assert.equal(control.painted, 0);
});

test("FloorPlan: a disabled item takes no click", () => {
  const control = mockControl({ selectedKeys: "x" });
  control._press({ KEY: "a", DISABLED: true });
  assert.equal(control.fired.length, 0);
  assert.equal(control._selectedKeys, "x");
  assert.equal(control.painted, 0);
  // and with the mode that only reports clicks, too
  const reporting = mockControl({ selectionMode: "None" });
  reporting._press({ KEY: "a", DISABLED: true });
  assert.equal(reporting.fired.length, 0);
});

test("FloorPlan: a numeric key is a key", () => {
  const control = mockControl();
  control._press({ KEY: 7001 });
  assert.deepEqual(control.fired.pop(), { key: "7001", selected: true, keys: "7001" });
});
