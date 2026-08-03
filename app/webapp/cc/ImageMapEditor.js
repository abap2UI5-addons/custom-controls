// z2ui5cc.cc.ImageMapEditor - draw the regions of an image map, and hand them
// to ABAP as a table.
//
// The companion of z2ui5cc.cc.ImageMapster: that one renders a map, this one
// produces the coordinates for it. Load a picture, draw rectangles, circles
// and polygons over it, name them - and the areas arrive in the model in the
// shape ImageMapster consumes, so an app can draw a map in the morning and
// use it in the afternoon without anyone reading pixel coordinates off a
// screenshot.
//
// It is an IFRAME, not a rendered control, and that is deliberate. The editor
// is a standalone page whose stylesheet opens with a global reset over
// `html, body, div, span, p, a, ul, li, form, input, ...`; the addon this came
// from injected that into the UI5 view and stripped the styling off the whole
// surrounding app, which is why its demo page contained nothing else. An
// iframe gives the editor the document it expects and keeps its CSS and its
// globals to itself.
//
// `editorUrl` defaults to the copy in this BSP but is a plain property, so the
// editor can equally be served from another BSP, a web server or a CDN - the
// protocol below is all that has to hold.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5cc/cc/Util"],
  (Control, Util) => {
    "use strict";

    const TYPE_LOAD = "z2ui5cc.editor.load";
    const TYPE_COLLECT = "z2ui5cc.editor.collect";
    const TYPE_READY = "z2ui5cc.editor.ready";
    const TYPE_AREAS = "z2ui5cc.editor.areas";

    // Resolved against this control's own module, so it keeps working from the
    // Z2UI5CC BSP, from the Launchpad and from the standalone service alike.
    const DEFAULT_URL = sap.ui.require.toUrl(
      "z2ui5cc/lib/imagemap-editor/index.html",
    );

    // postMessage needs a concrete target origin. Same-origin is the normal
    // case (the editor ships in this BSP); for an absolute URL take its
    // origin, so a message is never broadcast wider than the page it is for.
    function originOf(url) {
      try {
        return new URL(url, window.location.href).origin;
      } catch (e) {
        return window.location.origin;
      }
    }

    return Control.extend("z2ui5cc.cc.ImageMapEditor", {
      metadata: {
        properties: {
          // the picture to draw on - URL or data: URI
          src: { type: "string", defaultValue: "" },
          fileName: { type: "string", defaultValue: "" },
          // where the editor page is served from
          editorUrl: { type: "string", defaultValue: DEFAULT_URL },
          width: { type: "string", defaultValue: "100%" },
          height: { type: "string", defaultValue: "600px" },
          // raise it to fetch what was drawn; 0 never collects
          trigger: { type: "int", defaultValue: 0 },
          // written back: [{ KEY, SHAPE, COORDS, ALT, TITLE, HREF }] - the
          // row shape z2ui5cc.cc.ImageMapster takes for its `areas`
          areas: { type: "object[]", defaultValue: [] },
        },
        events: {
          // the editor page is up and has the picture
          ready: {},
          // areas were collected; count saves the app a roundtrip to find out
          collected: { parameters: { count: { type: "int" } } },
        },
      },

      _frame() {
        return document.getElementById(`${this.getId()}-frame`);
      },

      _post(type, payload) {
        const frame = this._frame();
        if (!frame || !frame.contentWindow) return;
        frame.contentWindow.postMessage(
          Object.assign({ type }, payload || {}),
          originOf(this.getEditorUrl()),
        );
      },

      _sendImage() {
        if (!this.getSrc()) return;
        this._post(TYPE_LOAD, {
          image: this.getSrc(),
          filename: this.getFileName(),
        });
      },

      _onMessage(event) {
        const frame = this._frame();
        // Only this control's own iframe is listened to - the window receives
        // messages from anything on the page, including other editors.
        if (!frame || event.source !== frame.contentWindow) return;

        const data = event.data;
        if (!data || typeof data !== "object") return;

        if (data.type === TYPE_READY) {
          this._editorReady = true;
          this._sendImage();
          this.fireReady();
          return;
        }

        if (data.type === TYPE_AREAS) {
          const areas = Array.isArray(data.areas) ? data.areas : [];
          // Suppress invalidation: reloading the iframe would throw away the
          // drawing the user just made. The model write-back that carries the
          // areas to ABAP happens either way.
          this.setProperty("areas", areas, true);
          this.fireCollected({ count: areas.length });
        }
      },

      init() {
        this._messageHandler = this._onMessage.bind(this);
        window.addEventListener("message", this._messageHandler);
      },

      setSrc(value) {
        this.setProperty("src", value, true);
        // A picture that arrives after the page is up is simply loaded; the
        // editor replaces what it was showing.
        if (this._editorReady) this._sendImage();
        return this;
      },

      setTrigger(value) {
        const previous = this.getTrigger();
        this.setProperty("trigger", value, true);
        // Only a real change collects: the property is written on every model
        // update, and asking the editor on an unrelated one would overwrite
        // the app's areas with a half-finished drawing.
        if (value !== previous && value > 0) this._post(TYPE_COLLECT, {});
        return this;
      },

      onAfterRendering() {
        // a re-render replaced the iframe - the page inside it starts over and
        // announces itself again
        this._editorReady = false;
      },

      exit() {
        window.removeEventListener("message", this._messageHandler);
        this._messageHandler = null;
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          rm.openStart("div", control);
          rm.style("width", Util.toCssSize(control.getWidth()));
          rm.style("height", Util.toCssSize(control.getHeight()));
          rm.openEnd();

          rm.openStart("iframe", `${control.getId()}-frame`);
          rm.attr("src", control.getEditorUrl());
          rm.attr("title", "image map editor");
          rm.style("width", "100%");
          rm.style("height", "100%");
          rm.style("border", "1px solid var(--sapGroup_ContentBorderColor, #d9d9d9)");
          rm.openEnd();
          rm.close("iframe");

          rm.close("div");
        },
      },
    });
  },
);
