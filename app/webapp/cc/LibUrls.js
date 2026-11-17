// GENERATED FILE - do not edit.
//
// Written by tools/vendor.mjs from tools/libs.json. The versions come from
// package.json, so the URL a system loads and the version this repository was
// tested against are the same by construction.
//
// Local build: every library is vendored into this BSP under lib/, so a
// browser without internet access can still render every control. The paths
// are resolved through sap.ui.require.toUrl, which knows where the BSP is
// whether the app runs standalone, from a BSP or inside the Launchpad.
sap.ui.define([], () => {
  "use strict";

  const lib = (file) => sap.ui.require.toUrl("z2ui5_cci/lib/" + file);

  return {
    build: "local",
    chartJs: lib("chart.umd.js"),
    chartJsDatalabels: lib("chartjs_plugin_datalabels.js"),
    chartJsAutocolors: lib("chartjs_plugin_autocolors.js"),
    chartJsDeferred: lib("chartjs_plugin_deferred.js"),
    chartJsAnnotation: lib("chartjs_plugin_annotation.js"),
    chartJsVenn: lib("chartjs_chart_venn.js"),
    chartJsWordcloud: lib("chartjs_chart_wordcloud.js"),
    bwipJs: lib("bwip_js.js"),
    zxingWasm: lib("zxing_reader.js"),
    zxingWasmBinary: lib("zxing_reader_wasm.js"),
    driverJs: lib("driver.js"),
    driverJsCss: lib("driver.css"),
    animateCss: lib("animate.css"),
    marked: lib("marked.js"),
    domPurify: lib("purify.js"),
    sunEditor: lib("suneditor.js"),
    sunEditorCss: lib("suneditor.css"),
    sunEditorLang_ckb: lib("suneditor_lang_ckb.js"),
    sunEditorLang_cs: lib("suneditor_lang_cs.js"),
    sunEditorLang_da: lib("suneditor_lang_da.js"),
    sunEditorLang_de: lib("suneditor_lang_de.js"),
    sunEditorLang_es: lib("suneditor_lang_es.js"),
    sunEditorLang_fa: lib("suneditor_lang_fa.js"),
    sunEditorLang_fr: lib("suneditor_lang_fr.js"),
    sunEditorLang_he: lib("suneditor_lang_he.js"),
    sunEditorLang_hu: lib("suneditor_lang_hu.js"),
    sunEditorLang_it: lib("suneditor_lang_it.js"),
    sunEditorLang_ja: lib("suneditor_lang_ja.js"),
    sunEditorLang_km: lib("suneditor_lang_km.js"),
    sunEditorLang_ko: lib("suneditor_lang_ko.js"),
    sunEditorLang_lv: lib("suneditor_lang_lv.js"),
    sunEditorLang_nl: lib("suneditor_lang_nl.js"),
    sunEditorLang_pl: lib("suneditor_lang_pl.js"),
    sunEditorLang_pt_br: lib("suneditor_lang_pt_br.js"),
    sunEditorLang_ro: lib("suneditor_lang_ro.js"),
    sunEditorLang_ru: lib("suneditor_lang_ru.js"),
    sunEditorLang_se: lib("suneditor_lang_se.js"),
    sunEditorLang_tr: lib("suneditor_lang_tr.js"),
    sunEditorLang_uk: lib("suneditor_lang_uk.js"),
    sunEditorLang_ur: lib("suneditor_lang_ur.js"),
    sunEditorLang_zh_cn: lib("suneditor_lang_zh_cn.js"),
    fontAwesomeCss: lib("fontawesome.css"),

    // Directory holding <family>.woff2 and the metadata JSON the UI5
    // IconPool needs. Empty switches the IconPool registration off - see
    // the fontAwesome comment in tools/libs.json.
    fontAwesomeFontUri: "",
  };
});
