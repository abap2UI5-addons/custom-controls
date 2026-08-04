// Generates the abapGit BSP artefacts for the Z2UI5CC control BSP from
// app/webapp/.
//
// Same approach as the abap2UI5-frontend repo's .github/app2bsp/run.js, cut
// down to what a control container needs: every file under app/webapp becomes
// a BSP page, plus the UI5 repository path mapping and the page directory
// (z2ui5cc.wapa.xml) the abapGit WAPA deserializer reads.
//
// Run: npm run app2bsp
import { readdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { join, relative, sep, dirname } from "node:path";

const SOURCE_DIR = "app/webapp";
// the BSP artefacts live in their own subpackage - src/ root carries the
// library and the view builders, src/00 the samples
const TARGET_DIR = "src/01";
const BSP = "Z2UI5CC";
const PREFIX = "z2ui5cc.wapa.";
const MAPPING_PAGE = "UI5RepositoryPathMapping.xml";
const START_PAGE = "index.html";
const BSP_TEXT = "abap2UI5 custom controls";

// ICF nodes the BSP is served from. Without them abapGit creates the BSP
// application but no URL resolves to it and the browser gets
// "ICF Node NOT found!". The parent GUIDs are the SAP standard nodes
// /sap/bc/ui5_ui5/sap/ and /sap/bc/bsp/sap/ and are system-independent.
// abapGit names an SICF file <icf_name padded to 15><25-char parent guid>.
const ICF_PARENTS = [
  { guid: "0ec96042f38e7e75ceadd96a5", url: "/sap/bc/ui5_ui5/sap/" },
  { guid: "cc3e0011031e2f3f4be478dc5", url: "/sap/bc/bsp/sap/" },
];
const ICF_NAME_WIDTH = 15;

// BSP pages are stored on the SAP system as fixed-width 255-character lines.
// abapGit serializes them back exactly like that: every line space-padded to
// 255 characters, longer lines wrapped into 255-character chunks, LF endings
// and no newline after the last line. Emitting the same format means pulling
// into SAP and re-serializing produces no diff.
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

function toBspPageFormat(content) {
  const lines = content.split(/\r\n|\r|\n/);
  if (lines.length > 1 && lines[lines.length - 1] === "") lines.pop();
  const padded = [];
  for (const line of lines) {
    if (line.length <= LINE_WIDTH) {
      padded.push(line.padEnd(LINE_WIDTH));
    } else {
      for (let o = 0; o < line.length; o += LINE_WIDTH) {
        padded.push(line.slice(o, o + LINE_WIDTH).padEnd(LINE_WIDTH));
      }
    }
  }
  return padded.join("\n");
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

// only the generated artefacts are cleared - src also holds the ABAP classes,
// which must survive
for (const f of readdirSync(TARGET_DIR)) {
  if (f.startsWith(PREFIX) || f.endsWith(".sicf.xml")) rmSync(join(TARGET_DIR, f));
}

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

for (const rel of files) {
  const content = readFileSync(join(SOURCE_DIR, rel), "utf8");
  writeFileSync(join(TARGET_DIR, targetFileName(rel)), toBspPageFormat(content), "utf8");
  console.log(`${rel} -> ${TARGET_DIR}/${targetFileName(rel)}`);
}

writeFileSync(
  join(TARGET_DIR, targetFileName(MAPPING_PAGE)),
  toBspPageFormat(buildMapping(files)),
  "utf8",
);
console.log(`generated ${targetFileName(MAPPING_PAGE)}`);

const pages = [...files, MAPPING_PAGE];
writeFileSync(join(TARGET_DIR, `${PREFIX}xml`), buildWapaXml(pages), "utf8");
console.log(`generated ${PREFIX}xml with ${pages.length} pages`);

for (const parent of ICF_PARENTS) {
  const name = sicfFileName(parent.guid);
  writeFileSync(join(TARGET_DIR, name), buildSicfXml(`${parent.url}${BSP.toLowerCase()}/`), "utf8");
  console.log(`generated ${name} -> ${parent.url}${BSP.toLowerCase()}/`);
}
