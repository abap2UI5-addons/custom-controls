// Tests that the controls taking a bound ABAP structure read it without the
// obsolete camelCase mapper, and that the options whose library default is
// true can be switched off: Util's helpers (camelCase, camelKeys, toFlag,
// toNumber, coerce) and how DriverJs, ImageMapster, ExportSpreadsheet,
// Gauge and ChartJs apply them.
//
// The controls are UI5 AMD modules, loaded through the same kind of shim as in
// network-status-clock.test.mjs, with the real Util.js.
//
// What this cannot cover: the libraries reading the result - that needs a
// browser.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";
import { loadUtil } from "./util-module.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const Util = loadUtil();

function amd(file, deps = {}) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", file), "utf8");
  const all = {
    "sap/ui/core/Control": { extend: (name, definition) => definition },
    "z2ui5_cci/cc/Util": Util,
    "z2ui5_cci/cc/LibUrls": {},
    ...deps,
  };
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map((name) => all[name] ?? {}));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", "window", source)(sap, {});
  return result;
}

test("Util: ABAP field names become camelCase, camelCase names stay", () => {
  assert.equal(Util.camelCase("SHOW_PROGRESS"), "showProgress");
  assert.equal(Util.camelCase("UTC"), "utc");
  assert.equal(Util.camelCase("X2_AXIS"), "x2Axis");
  assert.equal(Util.camelCase("showProgress"), "showProgress");
  assert.equal(Util.camelCase("fill"), "fill");
});

test("Util: camelKeys renames deeply and leaves values alone", () => {
  const raw = { STEPS: [{ ELEMENT: "FIELD_A", POPOVER: { NEXT_BTN_TEXT: "NEXT_STEP" } }] };
  assert.deepEqual(Util.camelKeys(raw), {
    steps: [{ element: "FIELD_A", popover: { nextBtnText: "NEXT_STEP" } }],
  });
  // a copy - the model's object is not modified
  assert.ok("STEPS" in raw);
});

test("Util: toFlag and toNumber read the text ABAP sends", () => {
  assert.equal(Util.toFlag("false"), false);
  assert.equal(Util.toFlag("true"), true);
  assert.equal(Util.toFlag("X"), true);
  assert.equal(Util.toFlag(""), undefined);
  assert.equal(Util.toFlag(false), false);
  assert.equal(Util.toFlag("auto"), "auto");
  assert.equal(Util.toNumber("0"), 0);
  assert.equal(Util.toNumber("2.5"), 2.5);
  assert.equal(Util.toNumber(""), undefined);
  assert.equal(Util.toNumber(7), 7);
  assert.equal(Util.toNumber("wide"), "wide");
});

test("Util: coerce drops what comes out empty, keeps the rest", () => {
  assert.deepEqual(Util.coerce({ a: "false", b: "", c: "0", d: "x" }, ["a", "b"], ["c"]), {
    a: false,
    c: 0,
    d: "x",
  });
});

test("DriverJs: an unmapped config is read, true-default options can be switched off", () => {
  const DriverJs = amd("DriverJs.js");
  const out = DriverJs._normalize({
    ANIMATE: "false",
    ALLOW_CLOSE: "false",
    ALLOW_KEYBOARD_CONTROL: "X",
    SMOOTH_SCROLL: true,
    STAGE_PADDING: "0",
    STAGE_RADIUS: "",
    STEPS: [{ ELEMENT: "product", POPOVER: { TITLE: "Product", SHOW_PROGRESS: "false" } }],
  });
  assert.deepEqual(out, {
    animate: false,
    allowClose: false,
    allowKeyboardControl: true,
    smoothScroll: true,
    stagePadding: 0,
    steps: [{ element: "product", popover: { title: "Product", showProgress: false } }],
  });
});

test("DriverJs: a config from the camelCase mapper still works, and so does a highlight step", () => {
  const DriverJs = amd("DriverJs.js");
  assert.deepEqual(DriverJs._normalize({ showProgress: true, steps: [{ element: "a" }] }), {
    showProgress: true,
    steps: [{ element: "a" }],
  });
  assert.deepEqual(DriverJs._normalize({ ELEMENT: "a", POPOVER: { DESCRIPTION: "d" } }), {
    element: "a",
    popover: { description: "d" },
  });
});

test("ImageMapster: an unmapped config is read, fill, fade and deselection can be switched off", () => {
  const MapShapes = amd("MapShapes.js");
  const ImageMapster = amd("ImageMapster.js", { "z2ui5_cci/cc/MapShapes": MapShapes });
  const config = ImageMapster._normalize({
    FILL: "false",
    FADE: "false",
    IS_DESELECTABLE: "false",
    IS_SELECTABLE: "",
    SINGLE_SELECT: true,
    FILL_COLOR: "0a6ed1",
    RENDER_SELECT: { STROKE: "false", FILL_OPACITY: "0.5" },
  });
  assert.deepEqual(config, {
    fill: false,
    fade: false,
    isDeselectable: false,
    singleSelect: true,
    fillColor: "0a6ed1",
    renderSelect: { stroke: false, fillOpacity: "0.5" },
  });
  // no fill is drawn for a selected area any more
  const paint = MapShapes.paintAttributes(config, {}, "select");
  assert.equal(paint.fill, "none");
  assert.equal(paint.stroke, "none");
});

test("ImageMapster: one area can be made unselectable", () => {
  const MapShapes = amd("MapShapes.js");
  const ImageMapster = amd("ImageMapster.js", { "z2ui5_cci/cc/MapShapes": MapShapes });
  const control = Object.create(ImageMapster);
  control.getConfig = () => ({ IS_SELECTABLE: "true" });
  assert.equal(control._selectable({ KEY: "a", ISSELECTABLE: "false" }), false);
  assert.equal(control._selectable({ KEY: "b", ISSELECTABLE: "X" }), true);
  assert.equal(control._selectable({ KEY: "c" }), true);
  control.getConfig = () => ({ IS_SELECTABLE: "false" });
  assert.equal(control._selectable({ KEY: "c" }), false);
});

test("ExportSpreadsheet: unmapped columns are read, displayUnit and utc can be switched off, scale 0 is kept", () => {
  const ExportSpreadsheet = amd("ExportSpreadsheet.js");
  assert.deepEqual(
    ExportSpreadsheet._normalize({
      LABEL: "Price",
      PROPERTY: "PRICE",
      TYPE: "Currency",
      UNIT_PROPERTY: "CURRENCY",
      DISPLAY_UNIT: "false",
      UTC: "false",
      SCALE: "0",
      WIDTH: 12,
      DELIMITER: true,
    }),
    {
      label: "Price",
      property: "PRICE",
      type: "Currency",
      unitProperty: "CURRENCY",
      displayUnit: false,
      utc: false,
      scale: 0,
      width: 12,
      delimiter: true,
    },
  );
});

test("Gauge: unmapped options are read and win, a text false switches an option off", () => {
  const Gauge = amd("Gauge.js");
  const options = Gauge.toOptions({ options: { COLOR_PLATE: "#222", STROKE_TICKS: "false", VALUE_BOX: "false" } });
  assert.equal(options.colorPlate, "#222");
  assert.equal(options.strokeTicks, false);
  assert.equal(options.valueBox, false);
});

test("ChartJs: numbers sent as text arrive as numbers, 0 and fractions included", () => {
  const ChartJs = amd("ChartJs.js");
  assert.deepEqual(
    ChartJs._normalize({
      OPTIONS: {
        SCALES: { Y: { SUGGESTED_MIN: "0", SUGGESTED_MAX: "", TICKS: { STEP_SIZE: "0.5" } } },
        ANIMATIONS: { TENSION: { FROM: "0.4", TO: "0", EASING: "linear" } },
      },
    }),
    {
      options: {
        scales: { y: { suggestedMin: 0, ticks: { stepSize: 0.5 } } },
        animations: { tension: { from: 0.4, to: 0, easing: "linear" } },
      },
    },
  );
});
