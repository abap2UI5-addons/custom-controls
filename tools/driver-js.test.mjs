// Tests that z2ui5_cci.cc.DriverJs never hands driver.js a popover text it
// would write into the page as markup: escaped by default, sanitized with
// allowHtml.
//
// Loaded through the same AMD shim as network-status-clock.test.mjs; the
// methods are called on a stub `this`. DOMPurify is stubbed - what it removes
// is DOMPurify's business, that it is asked is this control's.
//
// What this cannot cover: driver.js drawing the popover - that needs a browser.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

const Util = {
  // Util.purify, minus the options - see purify.test.mjs
  purify: (html) => `[clean]${html}`,
  toList: (val) => String(val || "").split(",").map((s) => s.trim()).filter(Boolean),
  resolveControl: () => null,
};

function load() {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "DriverJs.js"), "utf8");
  const deps = {
    "sap/ui/core/Control": { extend: (name, definition) => definition },
    "z2ui5_cci/cc/Util": Util,
    "z2ui5_cci/cc/LibUrls": {},
  };
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory(...names.map((name) => deps[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const DriverJs = load();

const control = (allowHtml) => {
  const self = Object.create(DriverJs);
  self.getAllowHtml = () => allowHtml;
  return self;
};

const CONFIG = {
  progressText: "{{current}} of {{total}}",
  nextBtnText: "Next &raquo;",
  steps: [
    {
      element: "#field",
      popover: {
        title: "<img src=x onerror=alert(1)>",
        description: `Material "A&B" <b>new</b>`,
        side: "right",
      },
    },
  ],
};

test("DriverJs: popover texts are escaped by default", () => {
  const out = control(false)._resolveSteps(CONFIG);
  const popover = out.steps[0].popover;
  assert.equal(popover.title, "&lt;img src=x onerror=alert(1)&gt;");
  assert.equal(popover.description, "Material &quot;A&amp;B&quot; &lt;b&gt;new&lt;/b&gt;");
  assert.equal(out.nextBtnText, "Next &amp;raquo;");
  // driver.js substitutes these after the escaping
  assert.equal(out.progressText, "{{current}} of {{total}}");
  // not a text - untouched
  assert.equal(popover.side, "right");
  // the app's config itself is not modified
  assert.equal(CONFIG.steps[0].popover.title, "<img src=x onerror=alert(1)>");
});

test("DriverJs: allowHtml hands the texts to DOMPurify", () => {
  const out = control(true)._resolveSteps(CONFIG);
  assert.equal(out.steps[0].popover.title, "[clean]<img src=x onerror=alert(1)>");
  assert.equal(out.nextBtnText, "[clean]Next &raquo;");
});

test("DriverJs: the highlight step is escaped too", () => {
  const step = control(false)._resolveStep({ element: "#panel", popover: { title: "<i>x</i>" } });
  assert.equal(step.popover.title, "&lt;i&gt;x&lt;/i&gt;");
});
