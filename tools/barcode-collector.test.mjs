// Tests for the BarcodeScanner: the collecting logic in
// app/webapp/cc/BarcodeCollector.js, and the parts of
// app/webapp/cc/BarcodeScanner.js that decide what the camera and the reader
// are asked for and what reaches ABAP.
//
// Both files are UI5 AMD modules, loaded through the same kind of shim as in
// tools/map-shapes.test.mjs. What this cannot cover is the camera and the
// reader themselves - they need a browser, a camera and WebAssembly.
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
        result = factory(...names.map((name) => dependencies[name] ?? {}));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const BarcodeCollector = amd("BarcodeCollector.js");

const BarcodeScanner = amd("BarcodeScanner.js", {
  "sap/ui/core/Control": { extend: (name, definition) => definition },
  "z2ui5_cci/cc/Util": {
    toList: (value) =>
      String(value || "")
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean),
    logError: () => {},
    isDestroyed: () => false,
  },
  "z2ui5_cci/cc/LibUrls": { zxingWasm: "reader.js", zxingWasmBinary: "reader.wasm" },
  "z2ui5_cci/cc/BarcodeCollector": BarcodeCollector,
});

const code = (text, format = "EAN13") => ({ text, format });

test("a code is accepted once it was read in enough frames", () => {
  const collector = BarcodeCollector.create({ confirmations: 2 });

  assert.deepEqual(collector.add([code("4006381333931")]), []);
  assert.equal(collector.size(), 0);
  assert.deepEqual(collector.add([code("4006381333931")]), [code("4006381333931")]);
  assert.equal(collector.size(), 1);
  // a third read adds nothing new
  assert.deepEqual(collector.add([code("4006381333931")]), []);
  assert.equal(collector.size(), 1);
});

test("the same code twice in one frame is one read of that frame", () => {
  const collector = BarcodeCollector.create({ confirmations: 2 });

  collector.add([code("A1", "Code128"), code("A1", "Code128")]);
  assert.equal(collector.size(), 0, "two copies in one frame must not confirm each other");
  collector.add([code("A1", "Code128")]);
  assert.equal(collector.size(), 1);
});

test("a code is its format and its text", () => {
  const collector = BarcodeCollector.create();

  collector.add([code("12345670", "EAN8"), code("12345670", "Code128"), code("12345670", "EAN8")]);
  assert.deepEqual(collector.rows(), [
    { TEXT: "12345670", FORMAT: "EAN8" },
    { TEXT: "12345670", FORMAT: "Code128" },
  ]);
});

test("reads without text or format are ignored", () => {
  const collector = BarcodeCollector.create();

  collector.add([{ text: "", format: "QRCode" }, { text: "x" }, null, undefined]);
  collector.add(undefined);
  assert.equal(collector.size(), 0);
});

test("the scan completes at the expected count, and never without one", () => {
  const three = BarcodeCollector.create({ expected: "3" });
  three.add([code("1", "QRCode"), code("2", "QRCode")]);
  assert.equal(three.isComplete(), false);
  three.add([code("3", "QRCode")]);
  assert.equal(three.isComplete(), true);

  const open = BarcodeCollector.create({ expected: "" });
  open.add([code("1", "QRCode"), code("2", "QRCode"), code("3", "QRCode")]);
  assert.equal(open.isComplete(), false);
});

test("rows keep the order codes were accepted in, and clear starts over", () => {
  const collector = BarcodeCollector.create({ confirmations: 2 });

  collector.add([code("first"), code("second")]);
  collector.add([code("second")]);
  collector.add([code("first")]);
  assert.deepEqual(
    collector.rows().map((row) => row.TEXT),
    ["second", "first"],
  );
  assert.equal(collector.isAccepted("EAN13", "first"), true);

  collector.clear();
  assert.deepEqual(collector.rows(), []);
  assert.equal(collector.isAccepted("EAN13", "first"), false);
});

test("toCount reads what an ABAP field sends and rejects the rest", () => {
  assert.equal(BarcodeCollector.toCount("3"), 3);
  assert.equal(BarcodeCollector.toCount(" 4 "), 4);
  assert.equal(BarcodeCollector.toCount(5), 5);
  for (const bad of ["", "0", "-2", "1.5", "abc", null, undefined, 0]) {
    assert.equal(BarcodeCollector.toCount(bad), 0, `toCount(${JSON.stringify(bad)})`);
  }
});

// A stand-in control: the definition's methods only reach for the getters,
// the collector, the dialog and the fired event.
function scanner(properties = {}) {
  const calls = [];
  const values = { formats: "", expected: "", facingMode: "environment", deviceId: "", ...properties };
  const control = {
    ...BarcodeScanner,
    _session: 0,
    calls,
    getFormats: () => values.formats,
    getExpected: () => values.expected,
    getFacingMode: () => values.facingMode,
    getDeviceId: () => values.deviceId,
    getId: () => "scanner",
    setProperty(name, value) {
      calls.push(["setProperty", name, value]);
    },
    fireScanned(parameters) {
      calls.push(["fireScanned", parameters]);
    },
  };
  return control;
}

test("the camera is asked for the back camera, or for the one device named", () => {
  assert.deepEqual(scanner()._constraints(), {
    audio: false,
    video: { width: { ideal: 1920 }, height: { ideal: 1080 }, facingMode: { ideal: "environment" } },
  });

  const one = scanner({ deviceId: "cam-2", facingMode: "user" })._constraints();
  assert.deepEqual(one.video.deviceId, { exact: "cam-2" });
  assert.equal(one.video.facingMode, undefined, "a deviceId wins over facingMode");
});

test("the reader is limited to the formats named, and reads all without", () => {
  assert.deepEqual(scanner()._readerOptions(), {});
  assert.deepEqual(scanner({ formats: "EAN13, Code128 ,QRCode" })._readerOptions(), {
    formats: ["EAN13", "Code128", "QRCode"],
  });
});

test("finish writes the table before it fires the event", () => {
  // _stop( ) looks for the preview element, which Node has no document for
  globalThis.document ??= { getElementById: () => null };
  const control = scanner();
  control._collector = BarcodeCollector.create();
  control._collector.add([code("4006381333931"), code("ABC-1", "Code128")]);
  let closed = false;
  control._dialog = { close: () => (closed = true), isOpen: () => true };

  control.finish();

  assert.equal(closed, true);
  assert.deepEqual(control.calls, [
    [
      "setProperty",
      "codes",
      [
        { TEXT: "4006381333931", FORMAT: "EAN13" },
        { TEXT: "ABC-1", FORMAT: "Code128" },
      ],
    ],
    ["fireScanned", { count: 2 }],
  ]);
  // the scan's session ended with it - a pending frame must not carry on
  assert.equal(control._isLive(0), false);
});
