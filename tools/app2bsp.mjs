// Generates the abapGit BSP artefacts of a BSP from app/webapp/.
//
// Same approach as the abap2UI5-frontend repo's .github/app2bsp/run.js, cut
// down to what a control container needs: every file under app/webapp becomes
// a BSP page, plus the UI5 repository path mapping and the page directory
// (<bsp>.wapa.xml) the abapGit WAPA deserializer reads.
//
// This file is the same, byte for byte, in abap2UI5-addons/custom-controls
// (the BSP Z2UI5_CCI) and abap2UI5-addons/custom-controls-customer (Z2UI5_CCC
// and every customer fork of it): what differs between the two - the BSP name,
// its description and the GUIDs of its ICF parent nodes - is read from
// package.json, `config.bsp`. Change it in one repository, copy it to the
// other.
//
// Run: npm run app2bsp - and commit what it writes. CI regenerates and fails
// on a diff, so a stale page can never ship old JavaScript unnoticed.
import { readdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { join, relative, sep, dirname } from "node:path";

// package.json config.bsp:
//
//   name        the BSP (WAPA) name, e.g. "Z2UI5_CCI" - also the ICF node
//   text        its description, shown in SE80 and on the ICF node
//   icfParents  [{ guid, url }] - the ICF nodes the BSP is served from, see
//               below
const { name: BSP, text: BSP_TEXT, icfParents: ICF_PARENTS } =
  JSON.parse(readFileSync("package.json", "utf8")).config.bsp;

const SOURCE_DIR = "app/webapp";
// the BSP artefacts live in their own subpackage - src/ and src/00 carry the
// ABAP classes and the samples
const TARGET_DIR = "src/01";
const PREFIX = `${BSP.toLowerCase()}.wapa.`;
const MAPPING_PAGE = "UI5RepositoryPathMapping.xml";
const START_PAGE = "index.html";

// ICF nodes the BSP is served from (config.bsp.icfParents). Without them
// abapGit creates the BSP application but no URL resolves to it and the
// browser gets "ICF Node NOT found!". The parents are the SAP standard nodes
// /sap/bc/ui5_ui5/sap/ and /sap/bc/bsp/sap/; abapGit names an SICF file
// <icf_name padded to 15><25-char parent guid>.
//
// The GUIDs are the ones a real system serialized back - do not "correct"
// them by hand; in custom-controls two earlier sets were wrong and abapGit did
// not match them against the standard nodes. Keep them in sync with the file
// names under src/01: the CI job compares the generated tree against what is
// committed, so a SICF file renamed by hand without changing the list fails
// the build.
const ICF_NAME_WIDTH = 15;

// BSP pages are stored on the SAP system as fixed-width 255-character lines.
// abapGit serializes them back exactly like that: every line space-padded to
// 255 characters, LF endings and no newline after the last line. Emitting the
// same format means pulling into SAP and re-serializing produces no diff.
//
// A source line longer than 255 characters has no faithful representation in
// that format - it has to be chopped at character 256, wherever in the syntax
// that lands, and the file the system serves back is then not the file that
// went in - a minified library or a base64 string is broken in the middle of a
// token. So it is refused here rather than discovered as a broken control on a
// customer's system. Break such a line where the syntax allows it: a long
// base64 string in CSS may continue on the next line after a `\`, and in
// custom-controls tools/wrap-lines.mjs breaks the vendored libraries at points
// the JavaScript and CSS grammars treat as whitespace.
const LINE_WIDTH = 255;

// SAP validates a BSP page name on import, and a rejected one fails the whole
// deserialization with a bare
//   CL_O2_API_PAGES=>CREATE_NEW_PAGE sy-subrc=2 (invalid_name)
// - after the generated artefacts looked perfectly fine in git and in CI. So
// the check happens here instead.
//
// The shape below is the one the abap2UI5 frontend BSP has always shipped and
// that is therefore known to import: at most one directory level, and names
// built from letters, digits, underscore and dot only. A two-level path with a
// hyphen in it (`lib/imagemap-editor/bridge.js`) was rejected by a real system;
// which of the two SAP objected to was never established, so neither is used.
const PAGE_SEGMENT = /^[A-Za-z0-9_.]+$/;
const MAX_DEPTH = 1;

function assertPageName(rel) {
  const parts = rel.split("/");
  if (parts.length - 1 > MAX_DEPTH) {
    throw new Error(
      `${rel}: BSP pages may be at most ${MAX_DEPTH} directory level deep`,
    );
  }
  const bad = parts.filter((p) => !PAGE_SEGMENT.test(p));
  if (bad.length) {
    throw new Error(
      `${rel}: BSP page names allow letters, digits, '_' and '.' only - ` +
        `offending: ${bad.join(", ")}`,
    );
  }
}

function collect(dir, base = dir) {
  const files = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, entry.name);
    if (entry.isDirectory()) files.push(...collect(p, base));
    else if (entry.isFile()) files.push(relative(base, p).split(sep).join("/"));
  }
  return files;
}

function toBspPageFormat(content, rel) {
  const lines = content.split(/\r\n|\r|\n/);
  if (lines.length > 1 && lines[lines.length - 1] === "") lines.pop();

  const over = lines
    .map((line, index) => (line.length > LINE_WIDTH ? `${index + 1}:${line.length}` : null))
    .filter(Boolean);
  if (over.length) {
    throw new Error(
      `${rel}: ${over.length} line(s) longer than ${LINE_WIDTH} characters ` +
        `(line:length ${over.slice(0, 5).join(", ")}${over.length > 5 ? ", ..." : ""}) - ` +
        `a BSP page cannot carry them; break the line where the syntax allows it`,
    );
  }

  return lines.map((line) => line.padEnd(LINE_WIDTH)).join("\n");
}

const escapeXml = (v) =>
  v.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const targetFileName = (rel) => PREFIX + rel.replace(/\//g, "_-").toLowerCase();

// every directory between a file and the webapp root needs its own folder
// entry in the mapping, or the UI5 repository refuses the upload
function foldersOf(files) {
  const dirs = new Set();
  for (const f of files) {
    let d = dirname(f);
    while (d && d !== ".") {
      dirs.add(d);
      d = dirname(d);
    }
  }
  return [...dirs].sort();
}

function buildMapping(files) {
  const entry = (path, isFolder) =>
    [
      "",
      "  <MappingEntry",
      `   path              = "${escapeXml(path)}"`,
      `   is_folder         = "${isFolder ? "X" : ""}"`,
      `   internal_rep      = "${isFolder ? "" : "B"}"`,
      `   internal_rep_path = "${isFolder ? "" : escapeXml(path)}" />`,
    ].join("\n");

  const entries = [
    ...foldersOf(files).map((d) => entry(d, true)),
    ...[...files].sort().map((f) => entry(f, false)),
  ];

  return [
    '<?xml version="1.0"?>',
    "",
    '<UI5RepMapping version="1.0" xmlns="sap.ui5.tools.repository.mapping">',
    " <MappingEntries>",
    ...entries,
    "",
    " </MappingEntries>",
    "</UI5RepMapping>",
  ].join("\n");
}

function buildPageItem(page) {
  // the start page carries MIMETYPE/IS_START_PAGE instead of PAGETYPE,
  // matching the abapGit WAPA serializer output
  const typeLines =
    page === START_PAGE
      ? ["      <MIMETYPE>text/html</MIMETYPE>", "      <IS_START_PAGE>X</IS_START_PAGE>"]
      : ["      <PAGETYPE>X</PAGETYPE>"];
  return [
    "    <item>",
    "     <ATTRIBUTES>",
    `      <APPLNAME>${BSP}</APPLNAME>`,
    `      <PAGEKEY>${escapeXml(page.toUpperCase())}</PAGEKEY>`,
    `      <PAGENAME>${escapeXml(page)}</PAGENAME>`,
    ...typeLines,
    "      <LAYOUTLANGU>E</LAYOUTLANGU>",
    "      <VERSION>A</VERSION>",
    "      <LANGU>E</LANGU>",
    "     </ATTRIBUTES>",
    "    </item>",
  ].join("\n");
}

function buildWapaXml(pages) {
  const sorted = [...pages].sort((a, b) =>
    a.toUpperCase() < b.toUpperCase() ? -1 : a.toUpperCase() > b.toUpperCase() ? 1 : 0,
  );
  // abapGit writes its XML with a UTF-8 BOM; emit one so a pull/push cycle
  // produces no diff
  return (
    "﻿" +
    [
      '<?xml version="1.0" encoding="utf-8"?>',
      '<abapGit version="v1.0.0" serializer="LCL_OBJECT_WAPA" serializer_version="v1.0.0">',
      ' <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">',
      "  <asx:values>",
      "   <ATTRIBUTES>",
      `    <APPLNAME>${BSP}</APPLNAME>`,
      "    <APPLCLAS>/UI5/CL_UI5_BSP_APPLICATION</APPLCLAS>",
      `    <APPLEXT>${BSP}</APPLEXT>`,
      "    <SECURITY>X</SECURITY>",
      "    <ORIGLANG>E</ORIGLANG>",
      "    <MODIFLANG>E</MODIFLANG>",
      `    <TEXT>${BSP_TEXT}</TEXT>`,
      "   </ATTRIBUTES>",
      "   <PAGES>",
      ...sorted.map(buildPageItem),
      "   </PAGES>",
      "  </asx:values>",
      " </asx:abap>",
      "</abapGit>",
      "",
    ].join("\n")
  );
}

function buildSicfXml(url) {
  return (
    "﻿" +
    [
      '<?xml version="1.0" encoding="utf-8"?>',
      '<abapGit version="v1.0.0" serializer="LCL_OBJECT_SICF" serializer_version="v1.0.0">',
      ' <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">',
      "  <asx:values>",
      `   <URL>${url}</URL>`,
      "   <ICFSERVICE>",
      `    <ICF_NAME>${BSP}</ICF_NAME>`,
      `    <ORIG_NAME>${BSP.toLowerCase()}</ORIG_NAME>`,
      "   </ICFSERVICE>",
      "   <ICFDOCU>",
      `    <ICF_NAME>${BSP}</ICF_NAME>`,
      "    <ICF_LANGU>E</ICF_LANGU>",
      `    <ICF_DOCU>${BSP_TEXT}</ICF_DOCU>`,
      "   </ICFDOCU>",
      "  </asx:values>",
      " </asx:abap>",
      "</abapGit>",
      "",
    ].join("\n")
  );
}

const sicfFileName = (guid) =>
  `${BSP.toLowerCase().padEnd(ICF_NAME_WIDTH)}${guid}.sicf.xml`;

const files = collect(SOURCE_DIR);
if (files.length === 0) {
  console.error(`no files found under ${SOURCE_DIR}/`);
  process.exit(1);
}

// fail here, not on the customer's import
try {
  files.forEach(assertPageName);
} catch (e) {
  console.error(e.message);
  process.exit(1);
}

// A binary file passes the name check (`font.woff2` is a valid page name), and
// reading it as UTF-8 would replace every invalid byte sequence with U+FFFD -
// the page would import, and serve a corrupted file. So anything that is not
// valid UTF-8 text is refused: BSP pages are text, a binary has to travel as
// base64 inside one (a data URI in CSS, a script carrying it).
const utf8 = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });

// every file is read and checked before anything under src/01 is touched, so
// a refused file leaves the generated BSP as it was
const pages = new Map();
try {
  for (const rel of files) {
    let content;
    try {
      content = utf8.decode(readFileSync(join(SOURCE_DIR, rel)));
    } catch {
      throw new Error(`${rel}: not UTF-8 text - BSP pages are text, so a binary file cannot be one`);
    }
    pages.set(rel, toBspPageFormat(content, rel));
  }
  pages.set(MAPPING_PAGE, toBspPageFormat(buildMapping(files), MAPPING_PAGE));
} catch (e) {
  console.error(e.message);
  process.exit(1);
}

// only the generated artefacts are cleared - src/01 also holds its
// package.devc.xml, which must survive
for (const f of readdirSync(TARGET_DIR)) {
  if (f.startsWith(PREFIX) || f.endsWith(".sicf.xml")) rmSync(join(TARGET_DIR, f));
}

for (const rel of files) {
  writeFileSync(join(TARGET_DIR, targetFileName(rel)), pages.get(rel), "utf8");
  console.log(`${rel} -> ${TARGET_DIR}/${targetFileName(rel)}`);
}

writeFileSync(join(TARGET_DIR, targetFileName(MAPPING_PAGE)), pages.get(MAPPING_PAGE), "utf8");
console.log(`generated ${targetFileName(MAPPING_PAGE)}`);

const pageNames = [...files, MAPPING_PAGE];
writeFileSync(join(TARGET_DIR, `${PREFIX}xml`), buildWapaXml(pageNames), "utf8");
console.log(`generated ${PREFIX}xml with ${pageNames.length} pages`);

for (const parent of ICF_PARENTS) {
  const name = sicfFileName(parent.guid);
  writeFileSync(join(TARGET_DIR, name), buildSicfXml(`${parent.url}${BSP.toLowerCase()}/`), "utf8");
  console.log(`generated ${name} -> ${parent.url}${BSP.toLowerCase()}/`);
}
