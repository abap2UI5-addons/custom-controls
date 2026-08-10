// Tests for tools/wrap-lines.mjs.
//
// The wrapper is what makes vendoring a minified library into a BSP page safe,
// and a mistake in it produces a bundle that is syntactically valid, ships
// cleanly, and misbehaves at runtime. So the central test is not a hand-written
// snippet but every library this repository actually vendors: each one is
// wrapped, re-parsed, and its syntax tree compared against the tree of the
// untouched original. An inserted newline that changes anything - a template
// literal that gained a line break, a directive that stopped being one -
// shows up as a tree difference.
//
// Run: npm test
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";
import { parse } from "acorn";
import { wrapCss, wrapJs, wrapText, overlongLines, DEFAULT_MAX } from "./wrap-lines.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const config = JSON.parse(readFileSync(join(ROOT, "tools", "libs.json"), "utf8"));

// The hard limit a BSP page imposes; the wrapper aims lower (DEFAULT_MAX).
const BSP_LINE_WIDTH = 255;

// The syntax tree without positions - two programs that differ only in where
// the newlines are produce the same value.
const tree = (source) =>
  JSON.stringify(parse(source, { ecmaVersion: "latest" }), (key, value) =>
    key === "start" || key === "end" || key === "raw" ? undefined : value,
  );

test("every vendored JavaScript library survives wrapping unchanged", (t) => {
  const entries = config.entries.filter((entry) => entry.kind === "js");
  assert.ok(entries.length > 0, "libs.json declares no JavaScript libraries");

  for (const entry of entries) {
    const source = readFileSync(join(ROOT, "node_modules", entry.package, entry.file), "utf8");
    const wrapped = wrapJs(source);

    assert.equal(tree(wrapped), tree(source), `${entry.package}: syntax tree changed`);
    assert.deepEqual(
      overlongLines(wrapped, BSP_LINE_WIDTH),
      [],
      `${entry.package}: line(s) too long for a BSP page`,
    );
    t.diagnostic(`${entry.package} ${entry.file}: ${wrapped.split("\n").length} lines`);
  }
});

test("every vendored stylesheet wraps within the BSP line limit", () => {
  for (const entry of config.entries.filter((e) => e.kind === "css")) {
    // Font Awesome is rewritten by the vendor script before wrapping; the raw
    // package file is still the harder input, so it is what is checked here.
    const source = readFileSync(join(ROOT, "node_modules", entry.package, entry.file), "utf8");
    const wrapped = wrapCss(source);

    assert.deepEqual(
      overlongLines(wrapped, BSP_LINE_WIDTH),
      [],
      `${entry.package}: line(s) too long for a BSP page`,
    );
    // undoing the line continuations and the inserted newlines must give the
    // declarations back verbatim
    assert.equal(
      wrapped.replace(/\\\n/g, "").replace(/\n/g, ""),
      source.replace(/\n/g, ""),
      `${entry.package}: stylesheet content changed`,
    );
  }
});

test("a template literal does not gain a line break", () => {
  const filler = "x".repeat(DEFAULT_MAX);
  const source = `const a = {k: "${filler}"}; const b = \`before\${a.k}after\`;`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.match(wrapped, /`before\$\{a\.k\}after`/);
});

test("a directive prologue is never split", () => {
  const filler = "y".repeat(DEFAULT_MAX * 2);
  const source = `function f() {"use strict"; return "${filler}";}`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.match(wrapped, /"use strict"/);
});

test("no newline is inserted where the grammar forbids one", () => {
  // an arrow whose parameter list ends exactly around the limit, and a postfix
  // ++ in the same position - both would change meaning if broken before
  const pad = "a".repeat(DEFAULT_MAX - 20);
  const source = `const ${pad} = 1; const f = (one, two) => one + two; let n = 0; n++;`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.doesNotMatch(wrapped, /\n\s*=>/);
  assert.doesNotMatch(wrapped, /\n\s*\+\+/);
});

test("a string longer than a line is continued, not cut", () => {
  const value = "z".repeat(DEFAULT_MAX * 3);
  const source = `const s = "${value}";`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.ok(wrapped.includes("\\\n"), "expected a line continuation");
  assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), []);
});

test("an escape sequence is never split in half", () => {
  // é repeated: every split point that lands inside one of these would
  // change the string
  const value = "\\u00e9".repeat(DEFAULT_MAX);
  const source = `const s = "${value}";`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.doesNotMatch(wrapped, /\\\n u00e9/);
});

test("a CSS data URI survives wrapping", () => {
  const base64 = "QUJD".repeat(DEFAULT_MAX);
  const source = `@font-face{font-family:"X";src:url("data:font/woff2;base64,${base64}") format("woff2")}`;
  const wrapped = wrapCss(source);

  assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), []);
  const flat = wrapped.replace(/\\\n/g, "").replace(/\n/g, "");
  assert.ok(flat.includes(`base64,${base64}`), "data URI did not survive");
});

test("wrapText breaks on words and keeps short lines alone", () => {
  const source = `short line\n${"word ".repeat(200).trim()}`;
  const wrapped = wrapText(source, 80);

  assert.equal(wrapped.split("\n")[0], "short line");
  assert.deepEqual(overlongLines(wrapped, 80), []);
  assert.equal(wrapped.replace(/\n/g, " ").split(/\s+/).join(" "), source.replace(/\n/g, " "));
});
