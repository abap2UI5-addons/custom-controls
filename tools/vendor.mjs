// Produces the library URLs the controls load - in one of two shapes.
//
//   npm run vendor          the CDN build (this is what `main` carries).
//                           app/webapp/lib/ is removed and every control loads
//                           its library from jsDelivr on first use.
//
//   npm run vendor:local    the local build (this is what the `local` branch
//                           carries). Every library is copied out of
//                           node_modules into app/webapp/lib/, so the BSP ships
//                           it and the browser never leaves the SAP system.
//
// Both builds write app/webapp/cc/LibUrls.js - a generated module the controls
// take their default URLs from. Nothing else in the repository names a library
// URL, so the two builds cannot drift apart, and bumping a version is a change
// to package.json plus a re-run of this script.
//
// The vendored files are copied byte-for-byte, with two exceptions: line
// breaks, and the source-map comment. A BSP page is stored as 255-character
// lines, so anything longer is wrapped by tools/wrap-lines.mjs, which only
// inserts newlines the JavaScript and CSS grammars treat as whitespace - see
// that file for why that is safe and why reformatting with Prettier is not an
// option. The source-map pointer goes because the .map file is not vendored
// (stripSourceMap below).
//
// Run `npm run app2bsp` afterwards - this script writes app/webapp, the BSP
// artefacts under src/01 are generated from it.
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { wrapCss, wrapJs, wrapText, overlongLines, DEFAULT_MAX } from "./wrap-lines.mjs";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const WEBAPP = join(ROOT, "app", "webapp");
const NODE_MODULES = join(ROOT, "node_modules");

const config = JSON.parse(readFileSync(join(ROOT, "tools", "libs.json"), "utf8"));
const LIB_DIR = join(WEBAPP, config.libDir);
const LIB_URLS = join(WEBAPP, "cc", "LibUrls.js");

const local = process.argv.includes("--local");

const packageVersion = (name) =>
  JSON.parse(readFileSync(join(NODE_MODULES, name, "package.json"), "utf8")).version;

const read = (pkg, file) => readFileSync(join(NODE_MODULES, pkg, file), "utf8");

// Removes the trailing source-map pointer.
//
// Most dist builds end in `//# sourceMappingURL=chart.umd.js.map`. The .map
// file is not vendored - it is developer tooling, it doubles the size of some
// of these libraries, and it is not what an offline installation is for. Left
// in, the comment makes any browser with devtools open request a page the BSP
// does not have, and a 404 next to a custom control is exactly the symptom
// someone would spend an afternoon on. Dropping the pointer costs nothing:
// without a map the debugger simply shows the shipped file.
//
// Only a line that *starts* with the comment is removed, so a library that
// merely mentions the string inside a literal is left alone.
const stripSourceMap = (text) =>
  text
    .replace(/^[ \t]*\/\/# sourceMappingURL=.*$/gm, "")
    .replace(/^[ \t]*\/\*# sourceMappingURL=.*\*\/[ \t]*$/gm, "")
    .replace(/\n{3,}$/, "\n");

// ---------------------------------------------------------------------------
// Font Awesome
// ---------------------------------------------------------------------------

// Rewrites Font Awesome's stylesheet so it carries its webfonts inline.
//
// Upstream every @font-face points at ../webfonts/<family>.woff2, a binary file
// next to the CSS. A BSP page is a text object and cannot carry one, so the
// font travels as a base64 data URI inside the stylesheet instead - which is
// also why the v4/v5 alias families are dropped: each of them would repeat the
// whole font, and nothing in this repository uses those class names.
function inlineFontAwesome(source, pkg) {
  const keep = new Set(config.fontAwesome.families);
  const inlined = new Map();

  const dataUri = (file) => {
    if (!inlined.has(file)) {
      const bytes = readFileSync(join(NODE_MODULES, pkg, "webfonts", file));
      inlined.set(file, `data:font/woff2;base64,${bytes.toString("base64")}`);
    }
    return inlined.get(file);
  };

  let dropped = 0;
  const out = source.replace(/@font-face\{[^}]*\}/g, (block) => {
    const family = /font-family:"([^"]+)"/.exec(block)?.[1];
    if (!family || !keep.has(family)) {
      dropped += 1;
      return "";
    }
    const woff2 = /url\(\.\.\/webfonts\/([^)]+\.woff2)\)/.exec(block)?.[1];
    if (!woff2) throw new Error(`no woff2 source in @font-face for ${family}`);

    // The whole src list is replaced: the truetype fallback would 404 on a
    // system without the webfonts directory, and every browser that runs UI5
    // reads woff2.
    return block.replace(
      /src:[^};]*/,
      `src:url("${dataUri(woff2)}") format("woff2")`,
    );
  });

  console.log(
    `  fontawesome: inlined ${inlined.size} webfont(s), dropped ${dropped} alias @font-face rule(s)`,
  );
  return out;
}

// ---------------------------------------------------------------------------
// vendoring
// ---------------------------------------------------------------------------

function vendor(entry) {
  const version = packageVersion(entry.package);
  let content = read(entry.package, entry.file);

  if (entry.generator === "fontawesome") content = inlineFontAwesome(content, entry.package);

  content = stripSourceMap(content);

  const wrapped = entry.kind === "css" ? wrapCss(content) : wrapJs(content);

  // A pointer written some other way would still 404 - catch it here rather
  // than in a customer's network tab.
  if (wrapped.includes("sourceMappingURL")) {
    throw new Error(
      `${entry.target}: still carries a sourceMappingURL comment - ` +
        `extend stripSourceMap() in tools/vendor.mjs`,
    );
  }

  // The wrapper aims for DEFAULT_MAX and app2bsp enforces 255; a line that is
  // still over the aim had no break opportunity in it. Report rather than
  // discover it on the customer's import.
  const over = overlongLines(wrapped, 255);
  if (over.length) {
    throw new Error(
      `${entry.target}: ${over.length} line(s) longer than 255 characters ` +
        `(${over.slice(0, 5).join(", ")}) - a BSP page cannot carry them`,
    );
  }

  writeFileSync(join(LIB_DIR, entry.target), wrapped, "utf8");
  console.log(
    `  ${entry.package}@${version} ${entry.file} -> ${config.libDir}/${entry.target} ` +
      `(${(wrapped.length / 1024).toFixed(0)} kB, longest line ` +
      `${Math.max(...wrapped.split("\n").map((l) => l.length))})`,
  );
  return version;
}

// The licence texts travel with the code they cover - the BSP is where these
// libraries are redistributed, so the attribution belongs in it.
function writeLicences(versions) {
  const blocks = [
    "Third-party libraries vendored into this BSP.",
    "",
    "Each of them is redistributed unchanged apart from line breaks and a",
    "removed source-map comment; see tools/wrap-lines.mjs and tools/vendor.mjs",
    "in abap2UI5-addons/custom-controls for why.",
    "",
  ];

  const seen = new Set();
  for (const entry of config.entries) {
    if (seen.has(entry.package)) continue;
    seen.add(entry.package);

    const dir = join(NODE_MODULES, entry.package);
    const file = readdirSync(dir).find((name) => /^licen[cs]e/i.test(name));
    const meta = JSON.parse(readFileSync(join(dir, "package.json"), "utf8"));

    blocks.push(
      "=".repeat(76),
      `${entry.package} ${versions.get(entry.package)}  -  ${meta.license ?? "see below"}`,
      `${meta.homepage ?? ""}`.trim(),
      "=".repeat(76),
      "",
      file ? readFileSync(join(dir, file), "utf8").trimEnd() : "(no licence file in the package)",
      "",
    );
  }

  // a licence paragraph is often written as one very long line, and a BSP
  // page cannot carry it either
  writeFileSync(join(LIB_DIR, "licenses.txt"), `${wrapText(blocks.join("\n"))}\n`, "utf8");
  console.log(`  licenses.txt -> ${seen.size} package(s)`);
}

// ---------------------------------------------------------------------------
// the generated module
// ---------------------------------------------------------------------------

function writeLibUrls(urls, fontUri) {
  const body = Object.entries(urls)
    .map(([key, value]) => `    ${key}: ${value},`)
    .join("\n");

  const header = local
    ? [
        "// Local build: every library is vendored into this BSP under lib/, so a",
        "// browser without internet access can still render every control. The paths",
        "// are resolved through sap.ui.require.toUrl, which knows where the BSP is",
        "// whether the app runs standalone, from a BSP or inside the Launchpad.",
      ]
    : [
        "// CDN build: every library is fetched from jsDelivr on first use, once per",
        "// URL. To run without internet access, either override the liburl/cssurl",
        "// property of the control from ABAP, or install the `local` branch of this",
        "// repository, which ships the libraries inside the BSP.",
      ];

  const content = [
    "// GENERATED FILE - do not edit.",
    "//",
    "// Written by tools/vendor.mjs from tools/libs.json. The versions come from",
    "// package.json, so the URL a system loads and the version this repository was",
    "// tested against are the same by construction.",
    "//",
    ...header,
    "sap.ui.define([], () => {",
    '  "use strict";',
    "",
    ...(local
      ? [
          `  const lib = (file) => sap.ui.require.toUrl("${config.resourceRoot}/${config.libDir}/" + file);`,
          "",
        ]
      : []),
    "  return {",
    `    build: ${JSON.stringify(local ? "local" : "cdn")},`,
    body,
    "",
    "    // Directory holding <family>.woff2 and the metadata JSON the UI5",
    "    // IconPool needs. Empty switches the IconPool registration off - see",
    "    // the fontAwesome comment in tools/libs.json.",
    `    fontAwesomeFontUri: ${JSON.stringify(fontUri)},`,
    "  };",
    "});",
    "",
  ].join("\n");

  writeFileSync(LIB_URLS, content, "utf8");
}

// ---------------------------------------------------------------------------

console.log(`vendor: ${local ? "local" : "cdn"} build`);

if (existsSync(LIB_DIR)) rmSync(LIB_DIR, { recursive: true });

const urls = {};
const versions = new Map();

if (local) {
  mkdirSync(LIB_DIR, { recursive: true });
  for (const entry of config.entries) {
    versions.set(entry.package, vendor(entry));
    urls[entry.key] = `lib(${JSON.stringify(entry.target)})`;
  }
  writeLicences(versions);
} else {
  for (const entry of config.entries) {
    const version = packageVersion(entry.package);
    versions.set(entry.package, version);
    urls[entry.key] = JSON.stringify(entry.cdn.replace("{version}", version));
  }
}

writeLibUrls(urls, local ? "" : config.fontAwesome.cdnFontUri);

console.log(`vendor: wrote app/webapp/cc/LibUrls.js (wrap target ${DEFAULT_MAX} chars)`);
console.log("vendor: run 'npm run app2bsp' to regenerate the BSP artefacts");
