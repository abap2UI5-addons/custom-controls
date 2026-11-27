// Tests for the pure parts of z2ui5_cci.cc.ScanInput: the inputmode the
// field gets, what counts as typing elsewhere, when the field may take the
// focus and in which order several fields are asked, when a value state
// deserves a beep, and the capital letters.
//
// The module is a UI5 AMD module, loaded through the same kind of shim as in
// network-status-clock.test.mjs: Input.extend hands the definition back, and
// the statics hang on it.
//
// What this cannot cover: the focus really moving, the popups, the sound and
// the soft keyboard - those need a browser with UI5 and a handheld.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function amd(file) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", file), "utf8");
  const stub = { extend: (name, definition) => ({ ...definition }) };
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map(() => stub));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const ScanInput = amd("ScanInput.js");
const { normalizeMode, effectiveMode, isTextEntry, whyNot, errorSignal, successSignal, toUpper, focusOrder } =
  ScanInput;

test("ScanInput: keyboard off is always inputmode none", () => {
  assert.equal(effectiveMode(false, "numeric"), "none");
  assert.equal(effectiveMode(false, ""), "none");
});

test("ScanInput: keyboard on takes the field's mode, empty for the default", () => {
  assert.equal(effectiveMode(true, "numeric"), "numeric");
  assert.equal(effectiveMode(true, " NUMERIC "), "numeric");
  assert.equal(effectiveMode(true, ""), "");
  // an unknown keyword is refused, not written
  assert.equal(effectiveMode(true, "digits"), "");
  assert.equal(normalizeMode("digits"), null);
  assert.equal(normalizeMode(undefined), "");
});

test("ScanInput: text fields, selects and iframes count as typing elsewhere", () => {
  assert.equal(isTextEntry({ tagName: "INPUT", type: "text" }), true);
  assert.equal(isTextEntry({ tagName: "input" }), true);
  assert.equal(isTextEntry({ tagName: "INPUT", type: "number" }), true);
  assert.equal(isTextEntry({ tagName: "TEXTAREA" }), true);
  assert.equal(isTextEntry({ tagName: "SELECT" }), true);
  assert.equal(isTextEntry({ tagName: "IFRAME" }), true);
  assert.equal(isTextEntry({ tagName: "DIV", isContentEditable: true }), true);
});

test("ScanInput: buttons, checkboxes and the body do not", () => {
  assert.equal(isTextEntry({ tagName: "BUTTON" }), false);
  assert.equal(isTextEntry({ tagName: "INPUT", type: "checkbox" }), false);
  assert.equal(isTextEntry({ tagName: "BODY" }), false);
  assert.equal(isTextEntry({ tagName: "DIV" }), false);
  assert.equal(isTextEntry(null), false);
});

const FREE = {
  keepFocus: true,
  rendered: true,
  visible: true,
  enabled: true,
  editable: true,
  documentHidden: false,
  hasFocus: false,
  popupOpen: false,
  activeInPopup: false,
  activeIsTextEntry: false,
  textSelected: false,
};

test("ScanInput: a visible, enabled field with nothing in the way takes the focus", () => {
  assert.equal(whyNot(FREE), null);
});

test("ScanInput: the focus is never taken from what the user is doing", () => {
  assert.equal(whyNot({ ...FREE, keepFocus: false }), "off");
  assert.equal(whyNot({ ...FREE, rendered: false }), "not rendered");
  assert.equal(whyNot({ ...FREE, visible: false }), "hidden");
  assert.equal(whyNot({ ...FREE, enabled: false }), "disabled");
  assert.equal(whyNot({ ...FREE, editable: false }), "disabled");
  assert.equal(whyNot({ ...FREE, documentHidden: true }), "document hidden");
  assert.equal(whyNot({ ...FREE, hasFocus: true }), "has focus");
  assert.equal(whyNot({ ...FREE, popupOpen: true }), "popup");
  assert.equal(whyNot({ ...FREE, activeInPopup: true }), "popup");
  assert.equal(whyNot({ ...FREE, activeIsTextEntry: true }), "typing elsewhere");
  assert.equal(whyNot({ ...FREE, textSelected: true }), "text selected");
});

test("ScanInput: an open popup outranks typing - the field waits for it to close", () => {
  assert.equal(whyNot({ ...FREE, popupOpen: true, activeIsTextEntry: true }), "popup");
});

test("ScanInput: a change to Error beeps, staying Error only after a submit", () => {
  assert.equal(errorSignal({ previous: "None", next: "Error", rendered: true }), true);
  assert.equal(errorSignal({ previous: "Success", next: "Error", rendered: true }), true);
  assert.equal(errorSignal({ previous: "Error", next: "Error", rendered: true }), false);
  assert.equal(
    errorSignal({ previous: "Error", next: "Error", rendered: true, awaiting: true }),
    true,
  );
});

test("ScanInput: no beep for other states or for a field not yet on screen", () => {
  assert.equal(errorSignal({ previous: "Error", next: "Success", rendered: true }), false);
  assert.equal(errorSignal({ previous: "None", next: "Warning", rendered: true }), false);
  assert.equal(errorSignal({ previous: "None", next: "Error", rendered: false }), false);
  assert.equal(
    errorSignal({ previous: "None", next: "Error", rendered: false, awaiting: true }),
    false,
  );
});

test("ScanInput: the setters the renderer draws nothing from do not re-render", () => {
  // rule 10 of abap2UI5's frontend: a property without rendering is written
  // with setProperty( ..., true ) and returns this
  const calls = [];
  const self = {
    setProperty: (name, value, suppress) => calls.push([name, value, suppress]),
    getKeepFocus: () => false,
    getDomRef: () => null,
    _applyMode() {},
    _applyToggleState() {},
  };
  for (const [setter, name] of [
    ["setKeepFocus", "keepFocus"],
    ["setSelectOnFocus", "selectOnFocus"],
    ["setBeepOnError", "beepOnError"],
    ["setBeepOnSuccess", "beepOnSuccess"],
    ["setVibrateOnError", "vibrateOnError"],
    ["setKeyboard", "keyboard"],
    ["setInputMode", "inputMode"],
    ["setKeyboardToggleTooltip", "keyboardToggleTooltip"],
    ["setUpperCase", "upperCase"],
  ]) {
    calls.length = 0;
    assert.equal(ScanInput[setter].call(self, true), self, setter);
    assert.deepEqual(calls, [[name, true, true]], setter);
  }
});

test("ScanInput: names a renderer, so UI5 does not look for ScanInputRenderer.js", () => {
  assert.ok(ScanInput.renderer);
});

const free = {
  keepFocus: true,
  rendered: true,
  visible: true,
  enabled: true,
  editable: true,
  documentHidden: false,
  hasFocus: false,
  popupOpen: false,
  activeInPopup: false,
  activeIsTextEntry: false,
  textSelected: false,
};

test("ScanInput: a claim takes the focus from another text field and from a selection", () => {
  assert.equal(whyNot({ ...free, activeIsTextEntry: true }), "typing elsewhere");
  assert.equal(whyNot({ ...free, activeIsTextEntry: true, claim: true }), null);
  assert.equal(whyNot({ ...free, textSelected: true, claim: true }), null);
});

test("ScanInput: a claim still waits for a popup and never enters a field that cannot take it", () => {
  assert.equal(whyNot({ ...free, claim: true, popupOpen: true }), "popup");
  assert.equal(whyNot({ ...free, claim: true, activeInPopup: true }), "popup");
  assert.equal(whyNot({ ...free, claim: true, visible: false }), "hidden");
  assert.equal(whyNot({ ...free, claim: true, enabled: false }), "disabled");
  assert.equal(whyNot({ ...free, claim: true, rendered: false }), "not rendered");
  assert.equal(whyNot({ ...free, claim: true, keepFocus: false }), "off");
});

test("ScanInput: without a claim the field rendered last is asked first", () => {
  const order = focusOrder([{ name: "a" }, { name: "b" }, { name: "c" }]);
  assert.deepEqual(order.map((f) => f.name), ["c", "b", "a"]);
});

test("ScanInput: a claim goes first, the latest claim before an older one", () => {
  const order = focusOrder([
    { name: "a", claim: 2 },
    { name: "b", claim: 0 },
    { name: "c", claim: 5 },
    { name: "d", claim: 0 },
  ]);
  assert.deepEqual(order.map((f) => f.name), ["c", "a", "d", "b"]);
});

test("ScanInput: capital letters, one character for one", () => {
  assert.equal(toUpper("ab-12 cd"), "AB-12 CD");
  assert.equal(toUpper("äöü"), "ÄÖÜ");
  assert.equal(toUpper(""), "");
  assert.equal(toUpper(null), "");
});

test("ScanInput: a letter whose capital form is two characters is kept", () => {
  // the sharp s would become SS and move the caret and the length
  assert.equal(toUpper("straße"), "STRAßE");
  assert.equal(toUpper("straße").length, "straße".length);
});

test("ScanInput: a change to Success sounds, staying Success only after a submit", () => {
  assert.equal(successSignal({ previous: "None", next: "Success", rendered: true }), true);
  assert.equal(successSignal({ previous: "Error", next: "Success", rendered: true }), true);
  assert.equal(successSignal({ previous: "Success", next: "Success", rendered: true }), false);
  assert.equal(successSignal({ previous: "Success", next: "Success", rendered: true, awaiting: true }), true);
});

test("ScanInput: no success tone for other states or for a field not yet on screen", () => {
  assert.equal(successSignal({ previous: "Success", next: "None", rendered: true }), false);
  assert.equal(successSignal({ previous: "None", next: "Error", rendered: true, awaiting: true }), false);
  assert.equal(successSignal({ previous: "None", next: "Success", rendered: false }), false);
});

test("ScanInput: one change is never both an error and a success", () => {
  for (const next of ["None", "Success", "Warning", "Error", "Information"]) {
    const change = { previous: "None", next, rendered: true, awaiting: true };
    assert.equal(errorSignal(change) && successSignal(change), false, next);
  }
});
