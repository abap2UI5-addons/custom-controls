// Generates one ABAP holder class per custom control under app/cc/.
//
// The .js file is the single source of truth; the generated ABAP class only
// carries it as a string so the control can be shipped through abapGit
// without a BSP. Same idea as abap2UI5's .github/app2abap/trans2abap.js, cut
// down to what a control library needs.
//
// Run: npm run js2abap
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const SRC_DIR = "app/cc";
const OUT_DIR = "src";
const PREFIX = "zcl_testcc_";

// ABAP backtick literals escape a backtick by doubling it; nothing else needs
// escaping in that literal form.
function toAbapLiteral(line) {
  return "`" + line.replace(/`/g, "``") + "`";
}

function classNameFor(file) {
  return PREFIX + file.replace(/\.js$/, "").toLowerCase() + "_js";
}

function buildClass(clas, control, js) {
  const body = js
    .split(/\r?\n/)
    .map((line) => `             ${toAbapLiteral(line)} && |\\n| &&`);
  // close the concatenation chain with an empty literal so every line above
  // keeps the identical shape (easier diffs when the JS changes)
  body.push("             ``.");
  // the first line carries the assignment instead of the leading blanks
  body[0] = body[0].replace(/^ {13}/, "    result = ");

  return `* =====================================================================
* GENERATED FILE - DO NOT EDIT
* Source: ${SRC_DIR}/${control}.js
* Regenerate with 'npm run js2abap' after changing the JavaScript.
* =====================================================================
CLASS ${clas} DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS get
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS ${clas} IMPLEMENTATION.

  METHOD get.

${body.join("\n")}

  ENDMETHOD.

ENDCLASS.
`;
}

function buildXml(clas, control) {
  return `﻿<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="LCL_OBJECT_CLAS" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
   <VSEOCLASS>
    <CLSNAME>${clas.toUpperCase()}</CLSNAME>
    <LANGU>E</LANGU>
    <DESCRIPT>test-cc - ${control}.js</DESCRIPT>
    <STATE>1</STATE>
    <CLSCCINCL>X</CLSCCINCL>
    <FIXPT>X</FIXPT>
    <UNICODE>X</UNICODE>
   </VSEOCLASS>
  </asx:values>
 </asx:abap>
</abapGit>
`;
}

const files = readdirSync(SRC_DIR).filter((f) => f.endsWith(".js")).sort();
if (files.length === 0) {
  console.error(`no .js files found under ${SRC_DIR}/`);
  process.exit(1);
}

for (const file of files) {
  const js = readFileSync(join(SRC_DIR, file), "utf8").replace(/\n$/, "");
  if (/[^\x00-\x7F]/.test(js)) {
    console.error(`${file}: non-ASCII character - the ABAP repo is 7-bit ASCII`);
    process.exit(1);
  }
  const clas = classNameFor(file);
  const control = file.replace(/\.js$/, "");
  writeFileSync(join(OUT_DIR, `${clas}.clas.abap`), buildClass(clas, control, js));
  writeFileSync(join(OUT_DIR, `${clas}.clas.xml`), buildXml(clas, control));
  console.log(`${file} -> ${OUT_DIR}/${clas}.clas.abap`);
}
