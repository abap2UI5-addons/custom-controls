// Tests that every Chart.js plugin ChartJs.js knows by name is really
// registered once its script has run.
//
// A plugin that does not register itself is handed to Chart.register under the
// global its UMD build parks itself as - and that name is the build's choice,
// not the package's: chartjs-plugin-deferred calls itself ChartDeferred. A
// wrong name fails silently in the browser (one console line, a chart drawn
// without the plugin), so this runs the vendored builds in a sandbox and checks
// what they really expose.
//
// The same AMD shim as map-shapes.test.mjs: the control's definition object is
// handed straight back, and _load( ) is called against a stub.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const LIBS = JSON.parse(readFileSync(join(ROOT, "tools", "libs.json"), "utf8"));

// key -> the file the build vendors, so a "URL" is a path into node_modules
const LIB_URLS = Object.fromEntries(
  LIBS.entries
    .filter((entry) => entry.package && entry.file)
    .map((entry) => [entry.key, join(ROOT, "node_modules", entry.package, entry.file)]),
);

test("every named Chart.js plugin is registered after loading", async () => {
  const sandbox = vm.createContext({});
  const run = (file) => vm.runInContext(readFileSync(file, "utf8"), sandbox, { filename: file });
  const errors = [];

  const Util = {
    toList: (val) => String(val || "").split(",").map((s) => s.trim()).filter(Boolean),
    logError: (message) => errors.push(message),
    loadScript: async (url, isReady) => {
      if (!(typeof isReady === "function" && isReady())) run(url);
    },
    loadScripts: async (urls) => urls.forEach(run),
    isDestroyed: () => false,
  };

  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "ChartJs.js"), "utf8");
  let definition;
  const sap = {
    ui: {
      define(names, factory) {
        const deps = {
          "sap/ui/core/Control": { extend: (name, def) => def },
          "z2ui5_cci/cc/Util": Util,
          "z2ui5_cci/cc/LibUrls": LIB_URLS,
        };
        definition = factory(...names.map((name) => deps[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", "window", source)(sap, sandbox);

  const plugins = "datalabels,autocolors,deferred,annotation,venn,wordcloud";
  run(LIB_URLS.chartJs);
  const registered = [];
  const register = sandbox.Chart.register.bind(sandbox.Chart);
  sandbox.Chart.register = (...items) => {
    registered.push(...items);
    return register(...items);
  };

  await definition._load.call({ getPlugins: () => plugins, getLibUrl: () => LIB_URLS.chartJs });

  assert.deepEqual(errors, []);
  // the four that are handed over by their global
  for (const name of ["ChartDataLabels", "chartjs-plugin-autocolors", "ChartDeferred", "chartjs-plugin-annotation"]) {
    assert.ok(registered.includes(sandbox[name]), `${name} was not registered`);
  }
  // the two chart types register their controllers on load
  assert.ok(sandbox.Chart.registry.getController("venn"));
  assert.ok(sandbox.Chart.registry.getController("wordCloud"));
});
