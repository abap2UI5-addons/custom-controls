// Tests for FontAwesome.js: which font directory the IconPool collections are
// registered with, and when the stylesheet is skipped.
//
// The UI5 constructor runs init( ) first and applies the settings afterwards,
// and sap.ui.core.IconPool keeps the FIRST registration of a collection. So
// registering too early pins the default font directory for good. The stubs
// below reproduce exactly those two facts.
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const DEFAULT_URI = "https://cdn.example/fonts/";

function load() {
  const pool = new Map();
  const styles = [];
  const IconPool = {
    registerFont(config) {
      // IconPool warns and keeps what is there
      if (!pool.has(config.collectionName)) pool.set(config.collectionName, config.fontURI);
    },
  };

  // a ManagedObject in miniature: defaults, init( ), then the settings
  // through their setters, in the order given
  function Control() {}
  Control.prototype.applySettings = function applySettings(settings = {}) {
    for (const [name, value] of Object.entries(settings)) {
      this[`set${name.charAt(0).toUpperCase()}${name.slice(1)}`](value);
    }
    return this;
  };
  Control.extend = (name, def) => {
    const properties = def.metadata.properties;
    function Sub(settings) {
      this._props = Object.fromEntries(Object.entries(properties).map(([k, v]) => [k, v.defaultValue]));
      this.init?.();
      this.applySettings(settings);
    }
    Sub.prototype = Object.create(Control.prototype);
    Sub.prototype.setProperty = function setProperty(name, value) {
      this._props[name] = value;
    };
    for (const key of Object.keys(properties)) {
      const cap = key.charAt(0).toUpperCase() + key.slice(1);
      Sub.prototype[`get${cap}`] = function get() {
        return this._props[key];
      };
      Sub.prototype[`set${cap}`] = function set(value) {
        this.setProperty(key, value);
        return this;
      };
    }
    Object.assign(Sub.prototype, def);
    return Sub;
  };

  const Util = {
    toList: (val) => String(val || "").split(",").map((s) => s.trim()).filter(Boolean),
    logError: () => {},
    loadStyle: (url) => {
      styles.push(url);
      return Promise.resolve();
    },
  };
  const LibUrls = { fontAwesomeFontUri: DEFAULT_URI, fontAwesomeCss: "https://cdn.example/all.css" };

  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "FontAwesome.js"), "utf8");
  let FontAwesome;
  const sap = {
    ui: {
      define(names, factory) {
        const deps = {
          "sap/ui/core/Control": Control,
          "sap/ui/core/IconPool": IconPool,
          "z2ui5_cci/cc/Util": Util,
          "z2ui5_cci/cc/LibUrls": LibUrls,
        };
        FontAwesome = factory(...names.map((name) => deps[name]));
      },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return { FontAwesome, pool, styles };
}

test("an app's fontUri is the one the collections are registered with", () => {
  const { FontAwesome, pool } = load();
  new FontAwesome({ fontUri: "/sap/bc/bsp/sap/zfonts/", collections: "fa-solid" });
  assert.deepEqual([...pool.entries()], [["fa-solid", "/sap/bc/bsp/sap/zfonts/"]]);
});

test("without settings every collection is registered with the default", () => {
  const { FontAwesome, pool } = load();
  new FontAwesome();
  assert.equal(pool.size, 9);
  assert.ok([...pool.values()].every((uri) => uri === DEFAULT_URI));
});

test("a cssUrl of a single space skips the stylesheet", () => {
  const { FontAwesome, styles } = load();
  new FontAwesome({ cssUrl: " " }).onAfterRendering();
  assert.deepEqual(styles, []);
});
