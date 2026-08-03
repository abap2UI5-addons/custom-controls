// Bridge between the vendored image-map editor and the UI5 control hosting it
// in an iframe (z2ui5cc.cc.ImageMapEditor).
//
// The editor is a standalone page with its own global CSS reset - that is why
// it runs in an iframe rather than inside the UI5 DOM - so the only way in and
// out is postMessage. Three messages, all with a `type` and nothing that is
// not plain data:
//
//   in   z2ui5cc.editor.load    { image, filename }   show this picture
//   in   z2ui5cc.editor.collect {}                    hand me what was drawn
//   out  z2ui5cc.editor.ready   {}                    page is up, send an image
//   out  z2ui5cc.editor.areas   { areas: [...] }      what was drawn
//
// Origins: the reply always goes back to the window and origin the request
// came from, never to a remembered one - so a page that was never asked
// anything gets told nothing.
(function () {
  "use strict";

  var TYPE_LOAD = "z2ui5cc.editor.load";
  var TYPE_COLLECT = "z2ui5cc.editor.collect";
  var TYPE_READY = "z2ui5cc.editor.ready";
  var TYPE_AREAS = "z2ui5cc.editor.areas";

  // Turns the editor's own "to html" output into plain rows. Parsing its
  // markup rather than reaching into its internals keeps the patch to the
  // vendored file down to a single exported reference: the <area> element is
  // the editor's documented output and the shape ImageMapster consumes.
  function collectAreas() {
    var app = window.z2ui5ccEditorApp;
    if (!app || typeof app.getHTMLCode !== "function") return [];

    var markup = app.getHTMLCode();
    if (!markup) return [];

    var doc = new DOMParser().parseFromString(
      "<map>" + markup + "</map>",
      "text/html",
    );

    return Array.prototype.map.call(
      doc.querySelectorAll("area"),
      function (area, index) {
        var alt = area.getAttribute("alt") || "";
        var title = area.getAttribute("title") || "";
        return {
          // ImageMapster addresses an area by key; fall back to a stable
          // generated one so an area the user did not name is still
          // selectable from ABAP.
          KEY: alt || title || "area" + (index + 1),
          SHAPE: area.getAttribute("shape") || "",
          // the editor separates with ", " - ImageMapster and the HTML spec
          // both want a bare comma list
          COORDS: (area.getAttribute("coords") || "").replace(/\s+/g, ""),
          ALT: alt,
          TITLE: title,
          HREF: area.getAttribute("href") || "",
        };
      },
    );
  }

  function post(target, origin, type, payload) {
    if (!target) return;
    try {
      target.postMessage(
        Object.assign({ type: type }, payload || {}),
        origin || "*",
      );
    } catch (e) {
      console.error("imagemap-editor bridge: postMessage failed:", e);
    }
  }

  window.addEventListener("message", function (event) {
    var data = event.data;
    if (!data || typeof data !== "object") return;

    if (data.type === TYPE_LOAD) {
      if (typeof window.loadJsEditor !== "function") {
        console.error("imagemap-editor bridge: editor.js did not load");
        return;
      }
      try {
        window.loadJsEditor(data.image || "", data.filename || "");
      } catch (e) {
        console.error("imagemap-editor bridge: could not open the image:", e);
      }
      return;
    }

    if (data.type === TYPE_COLLECT) {
      post(event.source, event.origin, TYPE_AREAS, { areas: collectAreas() });
    }
  });

  // The host cannot know when this page finished parsing, so say so. It
  // answers with the image to edit.
  //
  // This is the one message sent to `*`: there is no request to reply to yet,
  // so the parent's origin is unknown. It carries no data - only "I am up" -
  // and the areas still go exclusively to whoever asked for them.
  function announce() {
    post(window.parent, "*", TYPE_READY, {});
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", announce);
  } else {
    announce();
  }
})();
