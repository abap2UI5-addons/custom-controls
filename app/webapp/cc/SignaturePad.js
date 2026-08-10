// z2ui5_cci.cc.SignaturePad - a canvas the user signs on with mouse, finger or
// stylus. The stroke is handed to the backend as a base64 PNG in `value`, so
// an app binds `value` with client->_bind( ) and receives the signature in an
// ABAP variable.
//
// Clearing is backend-driven like the rest of abap2UI5: setting the bound
// variable to empty clears the pad on the next roundtrip. clear() exists for
// apps that drive the pad from the frontend.
//
// Ported from the abap2UI5 framework branch (app/webapp/cc/SignaturePad.js).
// The only change of substance: the dependency on z2ui5/core/Lib is gone. That
// module is frontend-internal and not part of the public contract, so a
// control shipped from its own BSP must not reach into it - a refactor there
// would break this control silently. The two helpers it used are inlined below.
sap.ui.define(["sap/ui/core/Control"], (Control) => {
  "use strict";

  // width/height size the pad; a bare number is treated as px.
  const toCssSize = (val) => (/^\d+$/.test(val) ? `${val}px` : val);

  // Replaces Lib.isDestroyed: guards async continuations (image load, resize
  // observer) against a control that was torn down in the meantime.
  const isDestroyed = (obj) => Boolean(obj?.isDestroyed && obj.isDestroyed());

  // Replaces Lib.logError, which files into the frontend's developer tools.
  // A control from its own BSP has no access to that, so log and carry on -
  // never throw out of a lifecycle hook.
  const logError = (message, error) =>
    console.error(error === undefined ? message : `${message}:`, error ?? "");

  return Control.extend("z2ui5_cci.cc.SignaturePad", {
    metadata: {
      properties: {
        // Base64 PNG data URL of the signature; empty when nothing is drawn.
        value: { type: "string", defaultValue: "" },
        width: { type: "string", defaultValue: "100%" },
        height: { type: "string", defaultValue: "200px" },
        lineWidth: { type: "float", defaultValue: 2 },
        lineColor: { type: "string", defaultValue: "#000000" },
        editable: { type: "boolean", defaultValue: true },
      },
      events: {
        change: {
          allowPreventDefault: true,
          parameters: { value: { type: "string" } },
        },
      },
    },

    _canvas() {
      return document.getElementById(`${this.getId()}-canvas`);
    },

    // True while nothing has been drawn and no value was restored - lets an
    // app distinguish "not signed" from "signed" without parsing the PNG.
    isEmpty() {
      return !this._hasStroke;
    },

    clear() {
      const canvas = this._canvas();
      const ctx = canvas?.getContext("2d");
      if (ctx) ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
      this._hasStroke = false;
      // Suppress invalidation - the canvas is already cleared, a re-render
      // would only throw it away and rebuild it identically.
      this.setProperty("value", "", true);
      this.fireChange({ value: "" });
    },

    // Sizes the backing store to the device resolution so strokes stay sharp
    // on retina and mobile screens. Returns true when the store was resized -
    // which also means the canvas was cleared and needs redrawing.
    _resizeCanvas(canvas) {
      const dpr = window.devicePixelRatio || 1;
      const w = Math.round(canvas.clientWidth * dpr);
      const h = Math.round(canvas.clientHeight * dpr);
      // Zero size means the pad is not laid out yet (hidden tab, collapsed
      // panel); resizing to 0 would clear it for nothing.
      if (!w || !h) return false;
      if (canvas.width === w && canvas.height === h) return false;
      canvas.width = w;
      canvas.height = h;
      const ctx = canvas.getContext("2d");
      if (!ctx) return false;
      // Draw in CSS pixels while the backing store carries device pixels.
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.lineCap = "round";
      ctx.lineJoin = "round";
      return true;
    },

    _drawDataURL(canvas, dataUrl) {
      const img = new Image();
      img.onload = () => {
        // The image load is async - the control or the canvas can be gone.
        if (isDestroyed(this)) return;
        const ctx = canvas.getContext("2d");
        if (!ctx) return;
        ctx.clearRect(0, 0, canvas.clientWidth, canvas.clientHeight);
        ctx.drawImage(img, 0, 0, canvas.clientWidth, canvas.clientHeight);
        this._hasStroke = true;
      };
      img.onerror = () =>
        logError("SignaturePad: could not restore the signature image");
      img.src = dataUrl;
    },

    // A re-render replaces the canvas element, so re-observe it every time.
    //
    // The field is NOT called `_observer`: ManagedObject already owns that
    // name for its own ManagedObjectObserver (propertyChange/aggregationChange,
    // no disconnect). Once UI5 sets it, a `if (!this._observer)` guard skips
    // creating ours and the next disconnect() call blows up with
    // "this._observer.disconnect is not a function".
    _observe(canvas) {
      if (typeof ResizeObserver === "undefined") return;
      if (!this._padResizeObserver) {
        this._padResizeObserver = new ResizeObserver(() => {
          if (isDestroyed(this)) return;
          const live = this._canvas();
          if (!live) return;
          // Resizing clears the canvas - redraw the signature afterwards.
          const snapshot = this.getValue();
          if (this._resizeCanvas(live) && snapshot) {
            this._drawDataURL(live, snapshot);
          }
        });
      }
      this._padResizeObserver.disconnect();
      this._padResizeObserver.observe(canvas);
    },

    _attach(canvas) {
      // UI5 can patch the same element in place across renders; attaching
      // again would draw every stroke twice.
      if (canvas._z2ui5_cciAttached) return;
      canvas._z2ui5_cciAttached = true;
      canvas.addEventListener("pointerdown", (e) => this._onDown(e, canvas));
      canvas.addEventListener("pointermove", (e) => this._onMove(e, canvas));
      canvas.addEventListener("pointerup", (e) => this._onUp(e, canvas));
      canvas.addEventListener("pointercancel", (e) => this._onUp(e, canvas));
    },

    _point(event, canvas) {
      const rect = canvas.getBoundingClientRect();
      return { x: event.clientX - rect.left, y: event.clientY - rect.top };
    },

    _onDown(event, canvas) {
      // editable can turn false while the listeners stay attached.
      if (!this.getEditable()) return;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      this._drawing = true;
      // Keep receiving move/up when the pointer leaves the canvas, so a
      // stroke running over the edge does not strand the pad mid-draw.
      if (canvas.setPointerCapture) canvas.setPointerCapture(event.pointerId);
      ctx.strokeStyle = this.getLineColor();
      ctx.lineWidth = this.getLineWidth();
      ctx.beginPath();
      const p = this._point(event, canvas);
      ctx.moveTo(p.x, p.y);
      // A tap without movement must leave a dot, not nothing.
      ctx.lineTo(p.x, p.y);
      ctx.stroke();
      this._hasStroke = true;
      event.preventDefault();
    },

    _onMove(event, canvas) {
      if (!this._drawing) return;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      const p = this._point(event, canvas);
      ctx.lineTo(p.x, p.y);
      ctx.stroke();
      event.preventDefault();
    },

    _onUp(event, canvas) {
      if (!this._drawing) return;
      this._drawing = false;
      if (
        canvas.releasePointerCapture &&
        canvas.hasPointerCapture?.(event.pointerId)
      ) {
        canvas.releasePointerCapture(event.pointerId);
      }
      this._commit(canvas);
    },

    // The value is published on pointerup only, never per move event: a full
    // base64 PNG per mouse move would flood the roundtrip payload.
    _commit(canvas) {
      let dataUrl;
      try {
        dataUrl = canvas.toDataURL("image/png");
      } catch (e) {
        logError("SignaturePad: canvas toDataURL failed", e);
        return;
      }
      if (isDestroyed(this)) return;
      // Suppress invalidation - a re-render would discard the canvas the user
      // just drew on and restore it asynchronously from this very image.
      this.setProperty("value", dataUrl, true);
      this.fireChange({ value: dataUrl });
    },

    onAfterRendering() {
      const canvas = this._canvas();
      if (!canvas) return;
      this._resizeCanvas(canvas);
      const val = this.getValue();
      // An empty value means the backend cleared the signature; the freshly
      // rendered canvas is already blank, so only the flag has to follow.
      if (val) this._drawDataURL(canvas, val);
      else this._hasStroke = false;
      if (this.getEditable()) this._attach(canvas);
      this._observe(canvas);
    },

    exit() {
      if (this._padResizeObserver) {
        this._padResizeObserver.disconnect();
        this._padResizeObserver = null;
      }
    },

    renderer: {
      apiVersion: 2,
      render(oRm, oControl) {
        oRm.openStart("div", oControl);
        oRm.style("width", toCssSize(oControl.getWidth()));
        oRm.style("height", toCssSize(oControl.getHeight()));
        oRm.openEnd();

        oRm.openStart("canvas", `${oControl.getId()}-canvas`);
        oRm.style("width", "100%");
        oRm.style("height", "100%");
        oRm.style("display", "block");
        // Without touch-action:none a finger stroke scrolls the page instead
        // of drawing - the classic signature-pad bug on touch devices.
        oRm.style("touch-action", "none");
        oRm.style(
          "cursor",
          oControl.getEditable() ? "crosshair" : "not-allowed",
        );
        // Theme variables with a fallback, so the pad also looks right when
        // it renders outside a loaded theme.
        oRm.style("border", "1px solid var(--sapField_BorderColor, #89919a)");
        oRm.style("border-radius", "var(--sapField_BorderCornerRadius, 4px)");
        oRm.style("background", "var(--sapField_Background, #ffffff)");
        oRm.openEnd();
        oRm.close("canvas");

        oRm.close("div");
      },
    },
  });
});
