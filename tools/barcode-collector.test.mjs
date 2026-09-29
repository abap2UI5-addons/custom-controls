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

// A read at a place in the frame: a square of `size` pixels around (x, y), in
// the corner shape zxing-wasm reports.
const at = (text, x, y, size = 100, format = "EAN13") => {
  const h = size / 2;
  return {
    text,
    format,
    position: {
      topLeft: { x: x - h, y: y - h },
      topRight: { x: x + h, y: y - h },
      bottomRight: { x: x + h, y: y + h },
      bottomLeft: { x: x - h, y: y + h },
    },
  };
};

// a whole stack of cartons of one article: `n` copies of a code side by side
const stack = (text, n, format = "EAN13") =>
  Array.from({ length: n }, (_, i) => at(text, 100 + i * 150, 100, 100, format));

test("a code is accepted once it was read in enough frames", () => {
  const collector = BarcodeCollector.create({ confirmations: 2 });

  assert.deepEqual(collector.add([code("4006381333931")]), []);
  assert.equal(collector.size(), 0);
  assert.deepEqual(collector.add([code("4006381333931")]), [{ ...code("4006381333931"), count: 1 }]);
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
    { TEXT: "12345670", FORMAT: "EAN8", COUNT: 1 },
    { TEXT: "12345670", FORMAT: "Code128", COUNT: 1 },
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

test("distinct mode takes a code once, however many labels carry it", () => {
  const collector = BarcodeCollector.create({ confirmations: 2 });

  collector.add(stack("4006381333931", 5));
  assert.deepEqual(collector.add(stack("4006381333931", 5)), [{ ...code("4006381333931"), count: 1 }]);
  assert.deepEqual(collector.rows(), [{ TEXT: "4006381333931", FORMAT: "EAN13", COUNT: 1 }]);
  assert.equal(collector.total(), 1);
});

test("count mode takes a code as often as it is in the picture at once", () => {
  const collector = BarcodeCollector.create({ mode: "count", confirmations: 2 });

  assert.deepEqual(
    collector.add([...stack("4006381333931", 5), at("BATCH-0815", 400, 400, 100, "Code128")]),
    [],
  );
  assert.deepEqual(
    collector.add([...stack("4006381333931", 5), at("BATCH-0815", 400, 400, 100, "Code128")]),
    [
      { ...code("4006381333931"), count: 5 },
      { ...code("BATCH-0815", "Code128"), count: 1 },
    ],
  );
  assert.deepEqual(collector.rows(), [
    { TEXT: "4006381333931", FORMAT: "EAN13", COUNT: 5 },
    { TEXT: "BATCH-0815", FORMAT: "Code128", COUNT: 1 },
  ]);
  assert.equal(collector.size(), 2, "two codes");
  assert.equal(collector.total(), 6, "on six labels");
});

test("a count is the most copies confirmed at once, never a sum over frames", () => {
  const collector = BarcodeCollector.create({ mode: "count", confirmations: 2 });

  collector.add(stack("A", 3));
  assert.deepEqual(collector.add(stack("A", 2)), [{ ...code("A"), count: 2 }], "three once, two twice: 2");
  assert.deepEqual(collector.add(stack("A", 4)), [{ ...code("A"), count: 3 }], "three and more twice: 3");
  // a frame that misses a label - the camera moved, a reflection - takes nothing back
  assert.deepEqual(collector.add(stack("A", 1)), []);
  assert.deepEqual(collector.add(stack("A", 4)), [{ ...code("A"), count: 4 }]);
  assert.equal(collector.total(), 4);
});

test("in count mode the same code read twice at one place is one label", () => {
  const collector = BarcodeCollector.create({ mode: "count" });

  // the second read sits 20 px off a 100 px symbol - the same symbol
  collector.add([at("A", 100, 100), at("A", 120, 110), at("A", 300, 100)]);
  assert.equal(collector.total(), 2);

  // two labels that almost touch are still two
  const touching = BarcodeCollector.create({ mode: "count" });
  touching.add([at("A", 100, 100), at("A", 205, 100)]);
  assert.equal(touching.total(), 2);

  // a long 1D symbol, 300 x 60 - half its diagonal is more than its height -
  // twice, one above the other with 140 px between them
  const long = (y) => ({
    text: "B",
    format: "Code128",
    position: {
      topLeft: { x: 0, y },
      topRight: { x: 300, y },
      bottomRight: { x: 300, y: y + 60 },
      bottomLeft: { x: 0, y: y + 60 },
    },
  });
  const tall = BarcodeCollector.create({ mode: "count" });
  tall.add([long(0), long(200)]);
  assert.equal(tall.total(), 2);
});

test("in count mode a read without a position counts on its own", () => {
  const collector = BarcodeCollector.create({ mode: "count" });

  collector.add([code("A"), code("A"), at("A", 100, 100)]);
  assert.equal(collector.total(), 3);
});

test("in count mode the scan completes at the expected number of labels", () => {
  const collector = BarcodeCollector.create({ mode: "count", expected: 6 });

  collector.add(stack("A", 4));
  assert.equal(collector.isComplete(), false);
  collector.add([...stack("A", 4), at("B", 400, 400, 100, "QRCode")]);
  assert.equal(collector.isComplete(), false, "four and one");
  collector.add([...stack("A", 5), at("B", 400, 400, 100, "QRCode")]);
  assert.equal(collector.isComplete(), true, "five and one");
});

test("toMode takes both modes in any case and rejects the rest", () => {
  assert.equal(BarcodeCollector.toMode(""), "distinct");
  assert.equal(BarcodeCollector.toMode(undefined), "distinct");
  assert.equal(BarcodeCollector.toMode(" Count "), "count");
  assert.equal(BarcodeCollector.toMode("DISTINCT"), "distinct");
  assert.equal(BarcodeCollector.toMode("counting"), "");
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
  const values = {
    mode: "distinct",
    formats: "",
    expected: "",
    facingMode: "environment",
    deviceId: "",
    ...properties,
  };
  const control = {
    ...BarcodeScanner,
    _session: 0,
    calls,
    getMode: () => values.mode,
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
    fireError(parameters) {
      calls.push(["fireError", parameters]);
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
        { TEXT: "4006381333931", FORMAT: "EAN13", COUNT: 1 },
        { TEXT: "ABC-1", FORMAT: "Code128", COUNT: 1 },
      ],
    ],
    ["fireScanned", { count: 2 }],
  ]);
  // the scan's session ended with it - a pending frame must not carry on
  assert.equal(control._isLive(0), false);
});

test("in count mode the event counts labels, not rows", () => {
  globalThis.document ??= { getElementById: () => null };
  const control = scanner({ mode: "count" });
  control._collector = BarcodeCollector.create({ mode: "count" });
  control._collector.add([...stack("4006381333931", 3), at("ABC-1", 400, 400, 100, "Code128")]);
  control._dialog = { close: () => {}, isOpen: () => true };

  control.finish();

  assert.deepEqual(control.calls, [
    [
      "setProperty",
      "codes",
      [
        { TEXT: "4006381333931", FORMAT: "EAN13", COUNT: 3 },
        { TEXT: "ABC-1", FORMAT: "Code128", COUNT: 1 },
      ],
    ],
    ["fireScanned", { count: 4 }],
  ]);
});

test("an unknown mode is reported instead of scanning without it", async () => {
  globalThis.document ??= { getElementById: () => null };
  const control = scanner({ mode: "counting" });
  const status = [];
  control._status = { setType: (type) => status.push(type), setText: (text) => status.push(text) };
  control._dialog = { isOpen: () => true };

  await control._start(control._session, Promise.resolve());

  assert.deepEqual(control.calls, [
    ["fireError", { message: 'Unknown mode "counting" - use distinct or count.' }],
  ]);
  assert.deepEqual(status, ["Error", 'Unknown mode "counting" - use distinct or count.']);
});
