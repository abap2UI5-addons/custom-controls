// Tests for tools/embed-wasm.mjs.
//
// The embedded module is decoded in the browser and handed to the library as
// it is, so a single wrong byte is a module that fails to compile on a system
// without internet - and nowhere else. The central test therefore takes every
// WebAssembly module this repository vendors, embeds it, runs the script and
// compares what it registered with the original file, byte for byte.
//
// Run: npm test
import { readFileSync } from "node:fs";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";
import { parse } from "acorn";
import { embedWasm, GLOBAL } from "./embed-wasm.mjs";
import { overlongLines, DEFAULT_MAX } from "./wrap-lines.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const config = JSON.parse(readFileSync(join(ROOT, "tools", "libs.json"), "utf8"));

// Runs the script against a stand-in window and returns what it registered.
function run(script) {
  const window = {};
  // eslint-disable-next-line no-new-func
  new Function("window", script)(window);
  return window[GLOBAL];
}

test("every vendored WebAssembly module comes back byte for byte", (t) => {
  const entries = config.entries.filter((entry) => entry.kind === "wasm");
  assert.ok(entries.length > 0, "libs.json declares no WebAssembly module");

  for (const entry of entries) {
    const bytes = readFileSync(join(ROOT, "node_modules", entry.package, entry.file));
    const name = basename(entry.file);
    const script = embedWasm(bytes, name, `${entry.package} ${entry.file}`);

    // no wrapping step follows for these - the script has to fit as written
    assert.deepEqual(overlongLines(script, DEFAULT_MAX), [], `${entry.package}: line(s) too long`);
    parse(script, { ecmaVersion: 2015 });

    const registered = run(script)[name];
    assert.ok(Buffer.from(registered, "base64").equals(bytes), `${entry.package}: bytes differ`);
    // the magic number, so a module that decodes to something else is caught
    // even if the comparison above were ever loosened
    assert.deepEqual([...Buffer.from(registered, "base64").subarray(0, 4)], [0, 0x61, 0x73, 0x6d]);
    t.diagnostic(`${entry.package} ${entry.file}: ${script.split("\n").length} lines`);
  }
});

test("a second module is registered beside the first, not over it", () => {
  const window = {};
  // eslint-disable-next-line no-new-func
  new Function("window", embedWasm(Uint8Array.of(1, 2, 3), "a.wasm", "a"))(window);
  // eslint-disable-next-line no-new-func
  new Function("window", embedWasm(Uint8Array.of(4, 5), "b.wasm", "b"))(window);

  assert.deepEqual(Object.keys(window[GLOBAL]).sort(), ["a.wasm", "b.wasm"]);
  assert.deepEqual([...Buffer.from(window[GLOBAL]["a.wasm"], "base64")], [1, 2, 3]);
});
