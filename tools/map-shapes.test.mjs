// Tests for the ImageMapster overlay: the geometry and paint arithmetic in
// app/webapp/cc/MapShapes.js, and the selection logic in
// app/webapp/cc/ImageMapster.js.
//
// Both files are UI5 AMD modules, so they are loaded through a small shim that
// captures the sap.ui.define factory and calls it with stubs. For the control
// that means Control.extend hands the definition object straight back, which
// is enough to call its methods against a mock - the methods that matter here
// touch properties and the selection, not the DOM.
//
// What this cannot cover: rendering, the UI5 lifecycle, and anything that
// needs a real browser. The overlay's DOM has to be looked at on a system.
//
// The tests live here rather than beside the modules because everything under
// app/webapp/ is turned into a BSP page by app2bsp - a test file there would
// be deployed to the SAP system.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

// Loads a UI5 module and returns whatever its factory returns.
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

const MapShapes = amd("MapShapes.js");

// The control, with just enough of UI5 stubbed to get its definition object.
const ImageMapster = amd("ImageMapster.js", {
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
  "z2ui5_cci/cc/MapShapes": MapShapes,
});

// A stand-in control: the definition's methods only reach for the properties,
// the selection and the fired event.
function mockControl({ areas = [], config = null, selectedKeys = "" } = {}) {
  const control = Object.create(ImageMapster);
  control._selectedKeys = selectedKeys;
  control.fired = [];
  control.painted = 0;
  control.getAreas = () => areas;
  control.getConfig = () => config;
  control.getSelectedKeys = () => control._selectedKeys;
  control.setProperty = (name, value) => {
    if (name === "selectedKeys") control._selectedKeys = value;
  };
  control.fireAreaPress = (payload) => control.fired.push(payload);
  control._paint = () => {
    control.painted += 1;
  };
  return control;
}

// ---------------------------------------------------------------------------
// geometry
// ---------------------------------------------------------------------------

test("a rectangle is read from either pair of corners", () => {
  const expected = { tag: "rect", attr: { x: 20, y: 30, width: 80, height: 60 } };
  assert.deepEqual(MapShapes.shapeOf({ SHAPE: "rect", COORDS: "20,30,100,90" }), expected);
  // bottom-right first - a perfectly ordinary way to write it, and negative
  // width/height would make the shape invisible rather than wrong-looking
  assert.deepEqual(MapShapes.shapeOf({ SHAPE: "rect", COORDS: "100,90,20,30" }), expected);
});

test("a circle keeps centre and radius", () => {
  assert.deepEqual(MapShapes.shapeOf({ SHAPE: "circle", COORDS: "50, 60 ,25" }), {
    tag: "circle",
    attr: { cx: 50, cy: 60, r: 25 },
  });
});

test("a polygon pairs its coordinates and is the default shape", () => {
  const poly = { tag: "polygon", attr: { points: "0,0 10,0 10,10" } };
  assert.deepEqual(MapShapes.shapeOf({ SHAPE: "poly", COORDS: "0,0,10,0,10,10" }), poly);
  assert.deepEqual(MapShapes.shapeOf({ COORDS: "0,0,10,0,10,10" }), poly);
  // a stray odd number has no partner and must not become "10,NaN"
  assert.deepEqual(MapShapes.shapeOf({ COORDS: "0,0,10,0,10,10,99" }), poly);
});

test("shape `default` covers the whole image", () => {
  assert.deepEqual(MapShapes.shapeOf({ SHAPE: "default" }, { width: 600, height: 400 }), {
    tag: "rect",
    attr: { x: 0, y: 0, width: 600, height: 400 },
  });
});

test("geometry that cannot be drawn is rejected, not guessed", () => {
  assert.equal(MapShapes.shapeOf({ SHAPE: "rect", COORDS: "1,2,3" }), null);
  assert.equal(MapShapes.shapeOf({ SHAPE: "circle", COORDS: "1,2" }), null);
  assert.equal(MapShapes.shapeOf({ SHAPE: "poly", COORDS: "1,2,3,4" }), null);
  assert.equal(MapShapes.shapeOf({ SHAPE: "poly", COORDS: "" }), null);
  assert.equal(MapShapes.shapeOf({}), null);
});

// ---------------------------------------------------------------------------
// paint
// ---------------------------------------------------------------------------

test("colours get their # back, and only when they are bare hex", () => {
  assert.equal(MapShapes.colour("0a6ed1"), "#0a6ed1");
  assert.equal(MapShapes.colour("fff"), "#fff");
  assert.equal(MapShapes.colour("#0a6ed1"), "#0a6ed1");
  assert.equal(MapShapes.colour("red"), "red");
  assert.equal(MapShapes.colour("rgb(1,2,3)"), "rgb(1,2,3)");
});

test("render options layer config, then state, then the area", () => {
  const config = {
    fillColor: "111111",
    fillOpacity: 0.4,
    renderSelect: { fillColor: "222222" },
  };

  // config only
  assert.equal(MapShapes.paintOf(config, {}, "highlight").fillColor, "111111");
  // the state layer wins over the map-wide option
  assert.equal(MapShapes.paintOf(config, {}, "select").fillColor, "222222");
  // and the area wins over both
  assert.equal(MapShapes.paintOf(config, { FILLCOLOR: "333333" }, "select").fillColor, "333333");
  // an option nobody overrode survives all three layers
  assert.equal(MapShapes.paintOf(config, {}, "select").fillOpacity, 0.4);
});

test("a hidden area is transparent but still there", () => {
  const attributes = MapShapes.paintAttributes({ fillColor: "0a6ed1" }, {}, "hidden");
  assert.equal(attributes["fill-opacity"], 0);
  assert.equal(attributes["stroke-opacity"], 0);
  // it keeps a fill so it stays a hit target for the pointer and the tab key
  assert.notEqual(attributes.fill, "none");
});

test("fill and stroke can be switched off", () => {
  const attributes = MapShapes.paintAttributes(
    { fill: false, stroke: true, strokeColor: "107e3e", strokeWidth: 3 },
    {},
    "highlight",
  );
  assert.equal(attributes.fill, "none");
  assert.equal(attributes.stroke, "#107e3e");
  assert.equal(attributes["stroke-width"], 3);
});

// ---------------------------------------------------------------------------
// selection
// ---------------------------------------------------------------------------

const AREA_A = { KEY: "a" };
const AREA_B = { KEY: "b" };

test("a click selects, a second click deselects", () => {
  const control = mockControl({ areas: [AREA_A] });

  control._press(AREA_A);
  assert.equal(control.getSelectedKeys(), "a");
  assert.deepEqual(control.fired.at(-1), { key: "a", selected: true, keys: "a" });

  control._press(AREA_A);
  assert.equal(control.getSelectedKeys(), "");
  assert.deepEqual(control.fired.at(-1), { key: "a", selected: false, keys: "" });
});

test("the event reports the state AFTER the click, not before", () => {
  // this is the bug the jQuery library had: its onClick ran ahead of its own
  // toggle, so reading the selection back reported it one click behind
  const control = mockControl({ areas: [AREA_A, AREA_B], selectedKeys: "a" });
  control._press(AREA_B);
  assert.deepEqual(control.fired.at(-1), { key: "b", selected: true, keys: "a,b" });
});

test("singleSelect keeps at most one key", () => {
  const control = mockControl({ areas: [AREA_A, AREA_B], config: { singleSelect: true } });

  control._press(AREA_A);
  control._press(AREA_B);
  assert.equal(control.getSelectedKeys(), "b");

  control._press(AREA_B);
  assert.equal(control.getSelectedKeys(), "");
});

test("isDeselectable false makes a selection final", () => {
  const control = mockControl({
    areas: [AREA_A],
    config: { isDeselectable: false },
    selectedKeys: "a",
  });

  control._press(AREA_A);
  assert.equal(control.getSelectedKeys(), "a");
  assert.deepEqual(control.fired.at(-1), { key: "a", selected: true, keys: "a" });
});

test("an unselectable area still raises the event", () => {
  const control = mockControl({ areas: [AREA_A], config: { isSelectable: false } });

  control._press(AREA_A);
  assert.equal(control.getSelectedKeys(), "");
  assert.deepEqual(control.fired.at(-1), { key: "a", selected: false, keys: "" });
});

test("an area may opt into selection where the map opted out", () => {
  const area = { KEY: "a", ISSELECTABLE: true };
  const control = mockControl({ areas: [area], config: { isSelectable: false } });

  control._press(area);
  assert.equal(control.getSelectedKeys(), "a");
});

test("staticState draws an area as if it were selected", () => {
  const control = mockControl({ areas: [{ KEY: "a", STATICSTATE: true }] });
  assert.equal(control._stateOf({ KEY: "a", STATICSTATE: true }), "select");
  assert.equal(control._stateOf({ KEY: "b" }), "hidden");
});

test("hover only shows where nothing is selected", () => {
  const control = mockControl({ areas: [AREA_A, AREA_B], selectedKeys: "a" });
  control._hover = "a";
  // selection outranks hover
  assert.equal(control._stateOf(AREA_A), "select");
  control._hover = "b";
  assert.equal(control._stateOf(AREA_B), "highlight");
});

// ---------------------------------------------------------------------------
// the module boundary
// ---------------------------------------------------------------------------

test("the control references nothing that moved to MapShapes", () => {
  // Splitting the module left the risk of a name that still reads as if it
  // were local. Node's syntax check cannot see it - it is a runtime error on a
  // code path that only a browser reaches.
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "ImageMapster.js"), "utf8");
  const moved = ["DEFAULTS", "RENDER_KEYS", "paintOf", "colour", "numbers"];

  for (const name of moved) {
    const bare = new RegExp(`(?<![.\\w])${name}\\b`, "g");
    const hits = [...source.matchAll(bare)].filter(
      (hit) => !/MapShapes\.\w*$/.test(source.slice(0, hit.index)),
    );
    assert.deepEqual(hits.map((hit) => hit[0]), [], `${name} is used without a MapShapes prefix`);
  }
});
