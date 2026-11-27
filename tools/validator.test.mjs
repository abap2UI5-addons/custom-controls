// Tests the rule check of Validator.js: one rule against one value.
//
// The same AMD shim as chartjs-normalize.test.mjs: the control's definition
// object is handed straight back, and _check( ) is called on it.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function loadDefinition() {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "Validator.js"), "utf8");
  let definition;
  const sap = {
    ui: {
      define(names, factory) {
        const deps = {
          "sap/ui/core/Control": { extend: (name, def) => def },
          "sap/ui/core/library": { ValueState: { None: "None", Error: "Error" } },
          "z2ui5_cci/cc/Util": { logError: () => {} },
        };
        definition = factory(...names.map((name) => deps[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return definition;
}

const { _check: check } = loadDefinition();

test("Validator: a minimum of 0 is checked - it arrives as text", () => {
  const rule = { FIELD: "qty", TYPE: "number", MINIMUM: "0" };
  assert.equal(check(rule, "-1"), "Enter a value of at least 0");
  assert.equal(check(rule, "0"), "");
});

test("Validator: an empty or missing limit is no limit", () => {
  assert.equal(check({ TYPE: "number", MINIMUM: "", MAXIMUM: "" }, "-5"), "");
  assert.equal(check({ TYPE: "number" }, "123456"), "");
});

test("Validator: limits arrive as text or, from an older backend, as numbers", () => {
  assert.equal(check({ TYPE: "integer", MINIMUM: "1", MAXIMUM: "999" }, "1000"), "Enter a value of at most 999");
  assert.equal(check({ TYPE: "integer", MINIMUM: 1, MAXIMUM: 999 }, "0"), "Enter a value of at least 1");
  assert.equal(check({ TYPE: "number", MAXIMUM: "2.5" }, "2.6"), "Enter a value of at most 2.5");
});
