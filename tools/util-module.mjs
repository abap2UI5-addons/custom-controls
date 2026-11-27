// The real app/webapp/cc/Util.js for the Node tests of the controls that
// call its pure helpers (camelCase, coerce, toFlag, ...), loaded through the
// same kind of AMD shim the tests use for the controls. Its two UI5
// dependencies are stubs: none of the pure helpers reaches them.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

export function loadUtil(overrides = {}) {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "Util.js"), "utf8");
  const deps = {
    "sap/ui/core/Element": {},
    "z2ui5_cci/cc/LibUrls": { integrity: {} },
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
  return { ...result, ...overrides };
}
