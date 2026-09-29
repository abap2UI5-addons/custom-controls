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

// url("x") and url(x) are the same value in CSS; the wrapper may turn the
// second into the first, so content comparisons read both the same way.
const unquoteUrls = (css) => css.replace(/url\("([^"()\s]*)"\)/g, "url($1)");

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
    // declarations back verbatim - up to the quotes an over-long url() gains,
    // which is why both sides are compared with url("x") read as url(x)
    assert.equal(
      unquoteUrls(wrapped.replace(/\\\n/g, "").replace(/\n/g, "")),
      unquoteUrls(source.replace(/\n/g, "")),
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

// eslint-disable-next-line no-new-func
const evaluate = (source, name) => new Function(`${source}; return ${name};`)();

test("an untagged template literal longer than a line is continued, its value unchanged", () => {
  // escapes and a substitution in the mix: the split must step over both
  const text = `${"t".repeat(DEFAULT_MAX)}\\u00e9\\\`${"u".repeat(DEFAULT_MAX)}`;
  const source = `const s = \`${text}\${1 + 1}${"v".repeat(DEFAULT_MAX)}\`;`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.ok(wrapped.includes("\\\n"), "expected a line continuation");
  assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), []);
  assert.equal(evaluate(wrapped, "s"), evaluate(source, "s"));
});

test("an untagged template made of short runs is continued where it overflows", () => {
  // An HTML template: no run is longer than a line, but no break may follow
  // any of them either - together they used to make one line of 400+.
  const run = (c) => `<li class=\\"${c.repeat(90)}\\">\\n\\t`;
  const source = `const t = "x"; const s = \`${run("a")}\${t}${run("b")}\${t}${run("c")}\${t}${run("d")}\`;`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), []);
  assert.equal(evaluate(wrapped, "s"), evaluate(source, "s"));
});

test("a short template at the end of a line keeps its closing backquote there", () => {
  // Tiny untagged literals, as minifiers write them: when one lands at the
  // very end of a line it is continued, and the backquote (or the `${`) after
  // it must stay on that line - a newline in front of it is template text, and
  // `L` becomes `L\n`. zxing-wasm is where this was found. Which column is the
  // bad one depends on everything before it, so every one around the wrap
  // target is tried.
  for (let pad = 0; pad < 260; pad += 1) {
    const source = `const a = [${"0,".repeat(pad)}\`L\`,\`M\${1}N\`];`;
    const wrapped = wrapJs(source);

    assert.equal(tree(wrapped), tree(source), `pad ${pad}`);
    assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), [], `pad ${pad}`);
    assert.deepEqual(evaluate(wrapped, "a"), evaluate(source, "a"), `pad ${pad}`);
  }
});

test("a string that opens on a full line still fits a BSP page", () => {
  // the key ends exactly at the wrap target, so the string opens with no room
  // left on its line - its first chunk must be the quote and nothing more
  const key = "k".repeat(DEFAULT_MAX - "const o = {".length - 1);
  const source = `const o = {${key}:"${"s".repeat(DEFAULT_MAX * 2)}"};`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), []);
});

test("a template literal that may be tagged is never continued", () => {
  // String.raw would hand the inserted backslash and newline to the tag
  const source = `const s = String.raw\`${"w".repeat(DEFAULT_MAX * 2)}\`;`;
  const wrapped = wrapJs(source);

  assert.equal(tree(wrapped), tree(source));
  assert.ok(!wrapped.includes("\\\n"), "a tagged literal gained a line continuation");
  assert.equal(evaluate(wrapped, "s"), evaluate(source, "s"));
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

test("an unquoted CSS url() too long for a line is quoted and continued", () => {
  // how SunEditor inlines its cursors and icons - no quotes, so nothing in it
  // could be continued as it stands
  const base64 = "PHN2".repeat(DEFAULT_MAX);
  const source = `.a{cursor:url(data:image/svg+xml;base64,${base64}) 4 4,auto}.b{color:red}`;
  const wrapped = wrapCss(source);

  assert.deepEqual(overlongLines(wrapped, BSP_LINE_WIDTH), []);
  const flat = wrapped.replace(/\\\n/g, "").replace(/\n/g, "");
  assert.equal(flat, `.a{cursor:url("data:image/svg+xml;base64,${base64}") 4 4,auto}.b{color:red}`);
});

test("a short unquoted CSS url() is left as it is", () => {
  const source = `.a{background:url(img/x.png) no-repeat}`;
  assert.equal(wrapCss(source), source);
});

test("wrapText breaks on words and keeps short lines alone", () => {
  const source = `short line\n${"word ".repeat(200).trim()}`;
  const wrapped = wrapText(source, 80);

  assert.equal(wrapped.split("\n")[0], "short line");
  assert.deepEqual(overlongLines(wrapped, 80), []);
  assert.equal(wrapped.replace(/\n/g, " ").split(/\s+/).join(" "), source.replace(/\n/g, " "));
});
