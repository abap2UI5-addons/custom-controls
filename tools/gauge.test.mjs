// Tests for the pure part of z2ui5_cci.cc.Gauge: the properties of the
// control in, the options of the canvas-gauges RadialGauge out.
//
// The control is a UI5 AMD module, loaded through the same shim as in
// network-status-clock.test.mjs: Control.extend hands the definition object
// back, which carries the functions.
//
// What this cannot cover: the drawing itself and the needle following a
// changed value - that needs a browser, the library and a UI5 runtime.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";
import { loadUtil } from "./util-module.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function amd(file) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", file), "utf8");
  const stub = { extend: (name, definition) => ({ ...definition }) };
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map((name) => (name === "z2ui5_cci/cc/Util" ? loadUtil() : stub)));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const { toOptions, toMajorTicks, toHighlights } = amd("Gauge.js");

test("Gauge: the interval decides the labelled ticks", () => {
  assert.deepEqual(toMajorTicks(0, 100, 25), ["0", "25", "50", "75", "100"]);
  assert.deepEqual(toMajorTicks(-20, 20, 10), ["-20", "-10", "0", "10", "20"]);
});

test("Gauge: without an interval the scale has ten steps", () => {
  const ticks = toMajorTicks(0, 100, 0);
  assert.equal(ticks.length, 11);
  assert.equal(ticks[0], "0");
  assert.equal(ticks[10], "100");
});

test("Gauge: an interval that does not divide the range is rounded to whole steps", () => {
  // 100 / 30 = 3.33 -> three steps; the last label is still the maximum
  assert.deepEqual(toMajorTicks(0, 100, 30), ["0", "33.333333", "66.666667", "100"]);
});

test("Gauge: an interval that would draw too many labels is ignored", () => {
  assert.equal(toMajorTicks(0, 1000, 1).length, 11);
});

test("Gauge: fractions do not show their floating point noise", () => {
  assert.deepEqual(toMajorTicks(0, 0.3, 0.1), ["0", "0.1", "0.2", "0.3"]);
});

test("Gauge: zones are read from upper-case and lower-case rows alike", () => {
  const upper = toHighlights([{ LOW: 0, HIGH: 60, COLOR: "green" }], 0, 100);
  const lower = toHighlights([{ low: "0", high: "60", color: "green" }], 0, 100);
  assert.deepEqual(upper, [{ from: 0, to: 60, color: "green" }]);
  assert.deepEqual(lower, upper);
});

test("Gauge: a zone is cut to the scale, an empty or colourless one is dropped", () => {
  const zones = toHighlights(
    [
      { low: -50, high: 20, color: "green" },
      { low: 80, high: 500, color: "red" },
      { low: 40, high: 40, color: "blue" },
      { low: 60, high: 50, color: "blue" },
      { low: 20, high: 40, color: "" },
      { low: 200, high: 300, color: "grey" },
    ],
    0,
    100,
  );
  assert.deepEqual(zones, [
    { from: 0, to: 20, color: "green" },
    { from: 80, to: 100, color: "red" },
  ]);
});

test("Gauge: no table is no zone", () => {
  assert.deepEqual(toHighlights(null, 0, 100), []);
  assert.deepEqual(toHighlights("x", 0, 100), []);
});

test("Gauge: the value is kept inside the scale", () => {
  assert.equal(toOptions({ value: 150 }).value, 100);
  assert.equal(toOptions({ value: -5 }).value, 0);
  assert.equal(toOptions({ value: "42" }).value, 42);
  assert.equal(toOptions({ value: "abc", minValue: 10, maxValue: 20 }).value, 10);
});

test("Gauge: a scale without a range gets one", () => {
  const options = toOptions({ minValue: 50, maxValue: 50 });
  assert.equal(options.minValue, 50);
  assert.equal(options.maxValue, 150);
});

test("Gauge: empty texts are switched off, not drawn as empty strings", () => {
  const options = toOptions({});
  assert.equal(options.title, false);
  assert.equal(options.units, false);
  assert.equal(toOptions({ title: "Load", units: "%" }).title, "Load");
});

test("Gauge: the value box shows the number without padding", () => {
  const options = toOptions({ decimals: 1 });
  assert.equal(options.valueInt, 1);
  assert.equal(options.valueDec, 1);
  assert.equal(toOptions({}).valueDec, 0);
  assert.equal(toOptions({ valueBox: false }).valueBox, false);
});

test("Gauge: animation off means no travel time", () => {
  assert.equal(toOptions({ animation: false }).animationDuration, 0);
  assert.equal(toOptions({}).animation, true);
});

test("Gauge: options of the library win over the properties", () => {
  const options = toOptions({ title: "Load", options: { title: "Other", colorPlate: "#222" } });
  assert.equal(options.title, "Other");
  assert.equal(options.colorPlate, "#222");
});
