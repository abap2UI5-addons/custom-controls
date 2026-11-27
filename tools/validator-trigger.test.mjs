// Tests for two decisions the Validator and DriverJs controls make without a
// browser: which value a form field has (Validator.readValue / check), and
// when a `trigger` value starts the action (Util.triggerFired).
//
// The modules are UI5 AMD modules, loaded through the same kind of shim as in
// network-status-clock.test.mjs. The UI5 controls a field can be are stubs
// that answer isA( ) for their class and its parents.
//
// What this cannot cover: the value states painted on real fields and a real
// view_display - those need a UI5 runtime.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function amd(file, deps = {}) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", file), "utf8");
  const stub = { extend: (name, definition) => ({ ...definition }) };
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map((name) => deps[name] ?? stub));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const Util = amd("Util.js", { "z2ui5_cci/cc/LibUrls": { integrity: {} } });
const Validator = amd("Validator.js", {
  "sap/ui/core/library": { ValueState: { None: "None", Error: "Error" } },
  "z2ui5_cci/cc/Util": Util,
});

// a field of class `classes[0]` (and its parents), with `props` as properties
function field(classes, props, extra = {}) {
  const control = {
    isA: (name) => classes.includes(name),
    getMetadata: () => ({ getProperty: (name) => name in props }),
    ...extra,
  };
  for (const [name, value] of Object.entries(props)) {
    control[`get${name.charAt(0).toUpperCase()}${name.slice(1)}`] = () => value;
  }
  return control;
}

const REQUIRED = { FIELD: "f", REQUIRED: true };

test("Validator: an unticked CheckBox fails required, a ticked one passes", () => {
  const off = field(["sap.m.CheckBox"], { selected: false, text: "I agree" });
  const on = field(["sap.m.CheckBox"], { selected: true, text: "I agree" });
  assert.equal(Validator.readValue(off), false);
  assert.notEqual(Validator.check(REQUIRED, Validator.readValue(off)), "");
  assert.equal(Validator.check(REQUIRED, Validator.readValue(on)), "");
  // not required: unticked is fine
  assert.equal(Validator.check({ FIELD: "f" }, false), "");
});

test("Validator: a Switch is read through its state", () => {
  const off = field(["sap.m.Switch"], { state: false });
  const on = field(["sap.m.Switch"], { state: true });
  assert.notEqual(Validator.check(REQUIRED, Validator.readValue(off)), "");
  assert.equal(Validator.check(REQUIRED, Validator.readValue(on)), "");
});

test("Validator: a MultiComboBox is its selected keys, not the typed text", () => {
  const typed = field(["sap.m.MultiComboBox", "sap.m.ComboBoxBase", "sap.m.InputBase"], {
    value: "tom",
    selectedKeys: [],
  });
  const chosen = field(["sap.m.MultiComboBox", "sap.m.ComboBoxBase", "sap.m.InputBase"], {
    value: "",
    selectedKeys: ["TOMATO", "ONION"],
  });
  assert.deepEqual(Validator.readValue(typed), []);
  assert.notEqual(Validator.check(REQUIRED, Validator.readValue(typed)), "");
  assert.deepEqual(Validator.readValue(chosen), ["TOMATO", "ONION"]);
  assert.equal(Validator.check(REQUIRED, Validator.readValue(chosen)), "");
});

test("Validator: a MultiInput is its tokens, not the typed text", () => {
  const token = (key, text) => ({ getKey: () => key, getText: () => text });
  const classes = ["sap.m.MultiInput", "sap.m.Input", "sap.m.InputBase"];
  const typed = field(classes, { value: "abc", tokens: [] });
  const chosen = field(classes, { value: "", tokens: [token("A1", "Alpha"), token("", "Beta")] });
  assert.notEqual(Validator.check(REQUIRED, Validator.readValue(typed)), "");
  assert.deepEqual(Validator.readValue(chosen), ["A1", "Beta"]);
  assert.equal(Validator.check(REQUIRED, Validator.readValue(chosen)), "");
});

test("Validator: Input and Select keep their value and key", () => {
  const input = field(["sap.m.Input", "sap.m.InputBase"], { value: "12", selectedKey: "" });
  const select = field(["sap.m.Select"], { selectedKey: "B" });
  assert.equal(Validator.readValue(input), "12");
  assert.equal(Validator.readValue(select), "B");
  assert.equal(Validator.check({ FIELD: "f", TYPE: "number", MINIMUM: 20 }, "12") !== "", true);
});

// a control whose trigger is bound to `path` (or not bound, path null)
let counter = 0;
function triggerControl(path, name = "z2ui5_cci.cc.DriverJs") {
  counter += 1;
  return {
    id: counter,
    getBindingPath: () => path,
    getBindingInfo: () => (path ? { parts: [{ path, model: undefined }] } : undefined),
    getMetadata: () => ({ getName: () => name }),
  };
}

test("trigger: a rebuilt view does not repeat what the last instance did", () => {
  const path = "/XX/TRIGGER_A";
  const first = triggerControl(path);
  assert.equal(Util.triggerFired(first, 0, 0), false, "0 never starts");
  assert.equal(Util.triggerFired(first, 1, 0), true, "the user raised it");
  assert.equal(Util.triggerFired(first, 1, 1), false, "an unrelated model update");

  // view_display after a navigation back: a new instance, the old value
  const rebuilt = triggerControl(path);
  assert.equal(Util.triggerFired(rebuilt, 1, 0), false);
  // ...and the next raise starts it again
  assert.equal(Util.triggerFired(rebuilt, 2, 1), true);
});

test("trigger: raised in the roundtrip that first shows the view, it starts", () => {
  const control = triggerControl("/XX/TRIGGER_B");
  assert.equal(Util.triggerFired(control, 1, 0), true);
});

test("trigger: a new value on a rebuilt view starts", () => {
  const path = "/XX/TRIGGER_C";
  Util.triggerFired(triggerControl(path), 3, 0);
  assert.equal(Util.triggerFired(triggerControl(path), 4, 0), true);
});

test("trigger: the memory is per control class and per binding", () => {
  Util.triggerFired(triggerControl("/XX/TRIGGER_D"), 1, 0);
  assert.equal(Util.triggerFired(triggerControl("/XX/TRIGGER_D", "z2ui5_cci.cc.Validator"), 1, 0), true);
  assert.equal(Util.triggerFired(triggerControl("/XX/TRIGGER_E"), 1, 0), true);
});

test("trigger: a literal (unbound) trigger acts on every display", () => {
  assert.equal(Util.triggerFired(triggerControl(null), 1, 0), true);
  assert.equal(Util.triggerFired(triggerControl(null), 1, 0), true);
});
