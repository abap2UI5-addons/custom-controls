// Tests for the pure parts of z2ui5_cci.cc.NetworkStatus (evaluate: browser
// facts in, displayed state out) and z2ui5_cci.cc.Clock (format).
//
// Both files are UI5 AMD modules, loaded through the same kind of shim as in
// map-shapes.test.mjs: the factory runs with stubs, and Control.extend /
// Button.extend hand the definition object back, which carries the statics.
//
// What this cannot cover: the ping loop, the browser events and the overflow
// menu - those need a real browser and a UI5 runtime.
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

const NetworkStatus = amd("NetworkStatus.js");
const { evaluate } = NetworkStatus;
const { format } = amd("Clock.js");

test("NetworkStatus: no network is offline, whatever the last ping said", () => {
  const state = evaluate({
    online: false,
    ping: { ok: true, ms: 20, status: 200 },
    connection: { effectiveType: "4g", downlink: 10 },
  });
  assert.equal(state.status, "offline");
  assert.equal(state.quality, 0);
  assert.equal(state.latency, -1);
  assert.deepEqual(state.details, []);
});

test("NetworkStatus: a ping without answer is unreachable", () => {
  const state = evaluate({
    online: true,
    ping: { ok: false, ms: null, status: 0 },
    connection: null,
  });
  assert.equal(state.status, "unreachable");
  assert.equal(state.quality, 0);
});

test("NetworkStatus: the latency decides the bars", () => {
  const bars = (ms) =>
    evaluate({ online: true, ping: { ok: true, ms, status: 200 }, connection: null })
      .quality;
  assert.equal(bars(0), 4);
  assert.equal(bars(249), 4);
  assert.equal(bars(250), 3);
  assert.equal(bars(600), 2);
  assert.equal(bars(750), 1);
  assert.equal(bars(5000), 1);
});

test("NetworkStatus: an HTTP error still means reachable, and says so", () => {
  const state = evaluate({
    online: true,
    ping: { ok: true, ms: 42, status: 403 },
    connection: null,
  });
  assert.equal(state.status, "online");
  assert.equal(state.latency, 42);
  assert.deepEqual(state.details, ["42 ms", "HTTP 403"]);
});

test("NetworkStatus: before the first ping the network type gives the bars", () => {
  const state = evaluate({
    online: true,
    ping: null,
    connection: { effectiveType: "3g", downlink: 1.5 },
  });
  assert.equal(state.status, "online");
  assert.equal(state.quality, 3);
  assert.equal(state.latency, -1);
  assert.deepEqual(state.details, ["3G", "1.5 Mbit/s"]);
});

test("NetworkStatus: no ping and no network information is plain online", () => {
  const state = evaluate({ online: true, ping: null, connection: null });
  assert.deepEqual(state, { status: "online", latency: -1, quality: 0, details: [] });
});

const DATE = new Date(2026, 10, 23, 7, 5, 9);

test("NetworkStatus: an OverflowToolbar ignores the state it writes on every ping", () => {
  // every property change of a toolbar item makes the OverflowToolbar lay
  // itself out again - and close its open overflow menu - unless the item
  // names the property as unrelated to its size
  assert.ok(NetworkStatus.metadata.interfaces.includes("sap.m.IOverflowToolbarContent"));
  const config = NetworkStatus.getOverflowToolbarConfig();
  assert.equal(config.canOverflow, false);
  for (const name of ["status", "latency", "quality"]) {
    assert.ok(config.propsUnrelatedToSize.includes(name), name);
  }
});

test("Clock: the four formats", () => {
  assert.equal(format(DATE, "datetime", "de-DE"), "23.11.2026, 07:05:09");
  assert.equal(format(DATE, "date", "de-DE"), "23.11.2026");
  assert.equal(format(DATE, "time", "de-DE"), "07:05:09");
  assert.equal(format(DATE, "shorttime", "de-DE"), "07:05");
});

test("Clock: an unknown format falls back to datetime", () => {
  assert.equal(format(DATE, "nonsense", "de-DE"), format(DATE, "datetime", "de-DE"));
});

test("Clock: a malformed locale falls back to the default one", () => {
  assert.equal(format(DATE, "time", "not a locale!"), format(DATE, "time", ""));
});
