// Tests that the Subresource Integrity hashes in app/webapp/cc/LibUrls.js are
// the hashes of the files this repository pins.
//
// tools/vendor.mjs writes them from node_modules; the `vendor` CI job proves
// the committed file is what the script writes. This test says the same on
// every `npm test` - so a version bump that skipped `npm run vendor` fails
// locally too - and holds the two rules the hashes rest on: every CDN URL
// carries one, and the one URL that cannot (the Font Awesome IconPool
// directory, see tools/libs.json) is pinned to a commit instead.
//
// What this cannot cover: that jsDelivr really serves those bytes. Its /npm/
// endpoint serves the published package unchanged, which is checked by hand
// when the scheme is touched, not on every run (it needs the network).
import { createHash } from "node:crypto";
import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";
import test from "node:test";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const LIBS = JSON.parse(readFileSync(join(ROOT, "tools", "libs.json"), "utf8"));

function libUrls() {
  const source = readFileSync(join(ROOT, "app", "webapp", "cc", "LibUrls.js"), "utf8");
  let result;
  const sap = {
    ui: {
      define(names, factory) {
        result = factory();
      },
      require: { toUrl: (path) => `/${path}` },
    },
  };
  // eslint-disable-next-line no-new-func
  new Function("sap", source)(sap);
  return result;
}

const sri = (file) =>
  `sha384-${createHash("sha384").update(readFileSync(file)).digest("base64")}`;

const version = (pkg) =>
  JSON.parse(readFileSync(join(ROOT, "node_modules", pkg, "package.json"), "utf8")).version;

test("every pinned CDN file carries the sha384 of the installed package's file", () => {
  const urls = libUrls();
  if (urls.build === "local") {
    // the local build loads from this BSP - nothing to pin, nothing to hash
    assert.deepEqual(urls.integrity, {});
    return;
  }

  const expected = {};
  for (const entry of LIBS.entries) {
    const url = entry.cdn.replace("{version}", version(entry.package));
    assert.equal(urls[entry.key], url, `${entry.key}: LibUrls.js is stale - run npm run vendor`);
    expected[url] = sri(join(ROOT, "node_modules", entry.package, entry.file));
  }
  assert.deepEqual(urls.integrity, expected, "LibUrls.js integrity is stale - run npm run vendor");
});

test("the Font Awesome IconPool directory is pinned to a commit", () => {
  // CSS @font-face and the IconPool's XHR take no integrity attribute, so the
  // URL itself has to be immutable: a GitHub repository at a full commit sha
  assert.match(
    LIBS.fontAwesome.cdnFontUri,
    /^https:\/\/cdn\.jsdelivr\.net\/gh\/[^/]+\/[^/@]+@[0-9a-f]{40}\//,
  );
  const urls = libUrls();
  if (urls.build !== "local") {
    assert.equal(urls.fontAwesomeFontUri, LIBS.fontAwesome.cdnFontUri);
  }
});
