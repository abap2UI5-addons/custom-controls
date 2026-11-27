// Tests that Util.purify hands DOMPurify the options that drop what its
// default allowlist keeps but a rendered text must not carry: forms, buttons,
// select/textarea, <style> and the attributes that submit a form.
//
// Util.js is loaded through the same kind of AMD shim as
// validator-trigger.test.mjs, with `window` passed in. DOMPurify is stubbed -
// what it does with the options is DOMPurify's business, that it gets them is
// this library's.
//
// What this cannot cover: the sanitized markup in a real browser.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

function loadUtil(window) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "Util.js"), "utf8");
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        const deps = { "sap/ui/core/Element": {}, "z2ui5_cci/cc/LibUrls": { integrity: {} } };
        result = factory(...names.map((name) => deps[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", "window", source)(sap, window);
  return result;
}

test("Util.purify: forms, buttons and <style> are forbidden, task-list inputs are not", () => {
  const calls = [];
  const window = {
    DOMPurify: {
      sanitize: (html, options) => {
        calls.push({ html, options });
        return "[clean]";
      },
    },
  };
  const Util = loadUtil(window);
  assert.equal(Util.purify("<p>x</p>"), "[clean]");
  const { html, options } = calls[0];
  assert.equal(html, "<p>x</p>");
  for (const tag of ["style", "form", "button", "select", "textarea"]) {
    assert.ok(options.FORBID_TAGS.includes(tag), `FORBID_TAGS has ${tag}`);
  }
  for (const attr of ["action", "formaction", "form"]) {
    assert.ok(options.FORBID_ATTR.includes(attr), `FORBID_ATTR has ${attr}`);
  }
  // marked renders a GFM task list item as <input type="checkbox" disabled>
  assert.ok(!options.FORBID_TAGS.includes("input"));
});

test("Util.purify: a value that is not a string is sanitized as text", () => {
  const seen = [];
  const Util = loadUtil({ DOMPurify: { sanitize: (html) => seen.push(html) } });
  Util.purify(undefined);
  Util.purify(42);
  assert.deepEqual(seen, ["", "42"]);
});
