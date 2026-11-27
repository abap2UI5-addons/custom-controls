// Tests that ChartJs.js turns the bound ABAP structure into the configuration
// Chart.js reads: camelCase keys, the keys ABAP cannot spell, and the options
// whose default is true, which ABAP sends as text.
//
// The same AMD shim as chartjs-plugins.test.mjs: the control's definition
// object is handed straight back, and _normalize( ) is called on it.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function loadDefinition() {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "ChartJs.js"), "utf8");
  let definition;
  const sap = {
    ui: {
      define(names, factory) {
        const deps = {
          "sap/ui/core/Control": { extend: (name, def) => def },
          "z2ui5_cci/cc/Util": {},
          "z2ui5_cci/cc/LibUrls": {},
        };
        definition = factory(...names.map((name) => deps[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", "window", source)(sap, {});
  return definition;
}

const { _normalize: normalize } = loadDefinition();

test("ChartJs: upper-case ABAP names become camelCase", () => {
  assert.deepEqual(
    normalize({
      TYPE: "bar",
      DATA: { LABELS: ["Red", "BLUE"], DATASETS: [{ BORDER_WIDTH: 1, DATA: ["12"] }] },
      OPTIONS: { SCALES: { Y: { BEGIN_AT_ZERO: true } } },
    }),
    {
      type: "bar",
      data: { labels: ["Red", "BLUE"], datasets: [{ borderWidth: 1, data: ["12"] }] },
      options: { scales: { y: { beginAtZero: true } } },
    },
  );
});

test("ChartJs: names from the camelCase mapper stay as they are", () => {
  assert.deepEqual(
    normalize({ options: { plugins: { legend: { position: "bottom" } } } }),
    { options: { plugins: { legend: { position: "bottom" } } } },
  );
});

test("ChartJs: the keys ABAP cannot spell are renamed either way", () => {
  assert.deepEqual(
    normalize({ DATA_VENN: [{ SETS: ["A"], VALUE: "2" }] }),
    { data: [{ sets: ["A"], value: "2" }] },
  );
  assert.deepEqual(normalize({ X_SCALEID: "x", scaleid: "y" }), { xScaleID: "x", scaleID: "y" });
});

test("ChartJs: a true-default option can be switched off from ABAP", () => {
  assert.deepEqual(
    normalize({
      OPTIONS: {
        RESPONSIVE: "false",
        PLUGINS: { LEGEND: { DISPLAY: "X" }, TOOLTIP: { ENABLED: "true" } },
      },
    }),
    { options: { responsive: false, plugins: { legend: { display: true }, tooltip: { enabled: true } } } },
  );
});

test("ChartJs: an empty flag leaves the Chart.js default, other text passes", () => {
  assert.deepEqual(
    normalize({ DISPLAY: "", DATALABELS: { DISPLAY: "auto" } }),
    { datalabels: { display: "auto" } },
  );
});

test("ChartJs: booleans, numbers and text outside the flags are untouched", () => {
  assert.deepEqual(
    normalize({ TITLE: { DISPLAY: true, TEXT: "false" }, DATALABELS: { OFFSET: 4 } }),
    { title: { display: true, text: "false" }, datalabels: { offset: 4 } },
  );
});
