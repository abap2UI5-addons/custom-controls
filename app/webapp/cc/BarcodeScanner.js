// z2ui5_cci.cc.BarcodeScanner - scans every barcode in the camera picture at
// once and hands them to ABAP as a table.
//
// sap.ndc.BarcodeScannerButton returns one code per scan, needs SAPUI5, and
// even its multiScan mode (1.115) returns only the code the user taps. This
// control reads ALL codes of each camera frame with zxing-wasm - ZXing-C++
// compiled to WebAssembly, the engine sap.ndc runs as well - outlines them in
// the live picture and collects the distinct ones, until the user confirms or
// until `expected` of them were found. The typical case is a label carrying
// material, batch and quantity as three codes, taken in one go.
//
// The result is written to `codes` as [{ TEXT, FORMAT }] - bind it to an
// internal table with the components TEXT and FORMAT - and `scanned` fires.
//
// What the page has to allow:
//
//   - the camera: getUserMedia exists in a secure context only, so https://
//     (or localhost)
//   - WebAssembly: 'wasm-unsafe-eval' in the script-src of the
//     Content-Security-Policy. abap2UI5's default policy carries it from
//     abap2UI5/abap2UI5#2810 on; an older installation adds it in its exit
//   - on the `main` branch, cdn.jsdelivr.net in script-src and connect-src.
//     The `local` branch ships the reader and its module in this BSP, with
//     the module embedded as base64 (tools/embed-wasm.mjs)
sap.ui.define(
  [
    "sap/ui/core/Control",
    "sap/ui/core/HTML",
    "sap/ui/Device",
    "sap/m/Button",
    "sap/m/Dialog",
    "sap/m/List",
    "sap/m/MessageStrip",
    "sap/m/StandardListItem",
    "sap/m/Title",
    "sap/m/Toolbar",
    "sap/m/ToolbarSpacer",
    "z2ui5_cci/cc/Util",
    "z2ui5_cci/cc/LibUrls",
    "z2ui5_cci/cc/BarcodeCollector",
  ],
  (
    Control,
    HTML,
    Device,
    Button,
    Dialog,
    List,
    MessageStrip,
    StandardListItem,
    Title,
    Toolbar,
    ToolbarSpacer,
    Util,
    LibUrls,
    BarcodeCollector,
  ) => {
    "use strict";

    // The key the local build registers the embedded module under - the file
    // name of the module (tools/embed-wasm.mjs, called from tools/vendor.mjs).
    const MODULE = "zxing_reader.wasm";

    // Frames a code has to be read in before it is accepted (BarcodeCollector).
    // Two cost a fraction of a second and keep a one-off misread of a worn 1D
    // code out of the result.
    const CONFIRMATIONS = 2;

    // Pause between two decoded frames, in ms. The reader runs on the UI
    // thread, and the pause is what keeps the dialog responsive on a slow
    // phone.
    const PAUSE = 60;

    // outline of a code in the picture: accepted, and read but not yet
    // accepted - the positive and the critical semantic colour
    const ACCEPTED = "#107e3e";
    const PENDING = "#e9730c";

    const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

    const stopStream = (stream) => {
      if (stream) for (const track of stream.getTracks()) track.stop();
    };

    // sap.m's own texts for OK and Cancel, so the two buttons follow the
    // user's language without this library shipping translations.
    function mText(key, fallback) {
      try {
        const Lib = sap.ui.require("sap/ui/core/Lib");
        const bundle =
          Lib && Lib.getResourceBundleFor
            ? Lib.getResourceBundleFor("sap.m")
            : sap.ui.getCore().getLibraryResourceBundle("sap.m");
        return (bundle && bundle.getText(key)) || fallback;
      } catch (e) {
        return fallback;
      }
    }

    // The WebAssembly module, as bytes. A `.wasm` URL is fetched. Anything else
    // is a script carrying the module as base64 - what the local build ships,
    // because a BSP page cannot carry a binary - which registers it on
    // window.z2ui5_cci_wasm.
    function loadModule(url) {
      if (/\.wasm([?#]|$)/i.test(url)) {
        return fetch(url).then((response) => {
          if (!response.ok) throw new Error(`could not load ${url} (HTTP ${response.status})`);
          return response.arrayBuffer();
        });
      }

      const embedded = () => window.z2ui5_cci_wasm && window.z2ui5_cci_wasm[MODULE];
      return Util.loadScript(url, () => Boolean(embedded())).then(() => {
        const base64 = embedded();
        if (!base64) throw new Error(`${url} did not register ${MODULE}`);
        const binary = atob(base64);
        const bytes = new Uint8Array(binary.length);
        for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
        return bytes;
      });
    }

    // One reader per page, loaded on the first scan. The module is handed over
    // as bytes (wasmBinary) rather than located by the library, so the reader
    // never reaches for its built-in jsDelivr default - on the local build
    // nothing leaves the SAP system.
    let reader = null;

    function loadReader(libUrl, wasmUrl) {
      if (!reader) {
        reader = Util.loadScript(libUrl, () => typeof window.ZXingWASM !== "undefined")
          .then(() => loadModule(wasmUrl))
          .then((wasmBinary) =>
            window.ZXingWASM.prepareZXingModule({
              overrides: { wasmBinary },
              fireImmediately: true,
            }),
          )
          .then(() => window.ZXingWASM);
        // a failed load is not cached - the next scan tries again
        reader.catch(() => {
          reader = null;
        });
      }
      return reader;
    }

    // The raw DOMException names mean little to the person holding the phone.
    function cameraError(error) {
      switch (error && error.name) {
        case "NotAllowedError":
        case "SecurityError":
          return "Camera access was denied - allow it for this page and try again.";
        case "NotFoundError":
        case "OverconstrainedError":
          return "No camera was found.";
        case "NotReadableError":
        case "AbortError":
          return "The camera is in use by another application.";
        default:
          return `The camera could not be started: ${(error && error.message) || error}`;
      }
    }

    function readerError(error) {
      const message = String((error && error.message) || error);
      // Chrome, Safari: "... because 'unsafe-eval' is not an allowed source of
      // script ...", Firefox: "... blocked by CSP"
      if (/unsafe-eval|blocked by CSP/i.test(message)) {
        return (
          "The Content-Security-Policy of this page blocks WebAssembly - " +
          "add 'wasm-unsafe-eval' to its script-src."
        );
      }
      if (/could not load/i.test(message)) {
        return (
          `${message}. Blocked by the Content-Security-Policy, or no internet access? ` +
          "Allow cdn.jsdelivr.net in script-src and connect-src, or install the local branch."
        );
      }
      return `The barcode reader could not be started: ${message}`;
    }

    return Control.extend("z2ui5_cci.cc.BarcodeScanner", {
      metadata: {
        properties: {
          // The result of the last completed scan: [{ TEXT, FORMAT }]. Bind it
          // to an internal table with the components TEXT and FORMAT.
          codes: { type: "object[]", defaultValue: [] },
          // zxing-wasm format names, comma separated: `EAN13, Code128,
          // DataMatrix`, or a group such as `AllLinear`, `AllMatrix` or
          // `AllRetail`. Empty reads every format. Naming the ones on the label
          // is faster and rules out misreads as a format that is not there.
          formats: { type: "string", defaultValue: "" },
          // The number of distinct codes that completes the scan without OK
          // being pressed - 3 for a label with three codes. Empty or 0: the
          // user confirms. A string like the numbers of Barcode: an abap2UI5
          // model carries an ABAP character field as a JSON string, and UI5
          // rejects "3" for an int-typed property instead of converting it.
          expected: { type: "string", defaultValue: "" },
          // `environment` (the back camera) or `user` (the front camera)
          facingMode: { type: "string", defaultValue: "environment" },
          // one specific camera, by the deviceId the browser reports for it;
          // wins over facingMode
          deviceId: { type: "string", defaultValue: "" },
          // the button
          text: { type: "string", defaultValue: "" },
          icon: { type: "string", defaultValue: "sap-icon://bar-code" },
          type: { type: "string", defaultValue: "Default" },
          enabled: { type: "boolean", defaultValue: true },
          // the dialog title
          title: { type: "string", defaultValue: "" },
          // where the reader and its WebAssembly module come from - a `.wasm`
          // URL, or a script embedding it as the local build does
          libUrl: { type: "string", defaultValue: LibUrls.zxingWasm },
          wasmUrl: { type: "string", defaultValue: LibUrls.zxingWasmBinary },
        },
        aggregations: {
          _button: {
            type: "sap.m.Button",
            multiple: false,
            visibility: "hidden",
          },
        },
        events: {
          // a scan completed and `codes` holds its result
          scanned: { parameters: { count: { type: "int" } } },
          // the camera or the reader could not be started, with the reason
          error: { parameters: { message: { type: "string" } } },
        },
      },

      init() {
        this._session = 0;
        this.setAggregation("_button", new Button({ press: () => this.open() }));
      },

      exit() {
        this._stop();
        // created on the first scan and not an aggregation - destroyed here
        if (this._dialog) this._dialog.destroy();
      },

      // Not in the renderer: setting a property on the button invalidates it,
      // and invalidating a control while rendering it schedules another pass.
      onBeforeRendering() {
        const button = this.getAggregation("_button");
        if (!button) return;
        button.setText(this.getText());
        button.setIcon(this.getIcon());
        button.setType(this.getType());
        button.setEnabled(this.getEnabled());
      },

      // Opens the camera dialog and starts a new scan. Public, so a scan can
      // also be started from the backend with cs_event-control_by_id.
      open() {
        if (this._dialog && this._dialog.isOpen()) return;
        const dialog = this._dialog || this._createDialog();

        this._collector = BarcodeCollector.create({
          expected: this.getExpected(),
          confirmations: CONFIRMATIONS,
        });
        this._list.destroyItems();
        this._syncCount();
        dialog.setTitle(this.getTitle() || "Scan barcodes");
        this._setStatus("Information", "Starting the camera ...");

        this._session += 1;
        const session = this._session;
        // afterClose too: a dialog closed while it is still opening may never
        // report afterOpen, and _start must not wait for it forever with a
        // camera stream in hand
        const opened = new Promise((resolve) => {
          dialog.attachEventOnce("afterOpen", resolve);
          dialog.attachEventOnce("afterClose", resolve);
        });
        dialog.open();
        this._start(session, opened);
      },

      // Completes the scan with what was collected so far - what OK does.
      finish() {
        if (!this._collector) return;
        const rows = this._collector.rows();
        this._stop();
        if (this._dialog) this._dialog.close();
        // the model first, the event second: abap2UI5 sends the model with the
        // event's roundtrip, so the table has to be in it by then
        this.setProperty("codes", rows, true);
        this.fireScanned({ count: rows.length });
      },

      _createDialog() {
        const id = this.getId();

        this._status = new MessageStrip({ showIcon: true }).addStyleClass("sapUiSmallMargin");
        this._count = new Title();
        this._list = new List({
          noDataText: "No code yet",
          headerToolbar: new Toolbar({
            content: [
              this._count,
              new ToolbarSpacer(),
              new Button({
                icon: "sap-icon://refresh",
                tooltip: "Start over",
                press: () => this._restart(),
              }),
            ],
          }),
        });
        this._ok = new Button({
          text: mText("MSGBOX_OK", "OK"),
          type: "Emphasized",
          enabled: false,
          press: () => this.finish(),
        });

        this._dialog = new Dialog({
          contentWidth: "40rem",
          stretch: Device.system.phone,
          horizontalScrolling: false,
          content: [
            this._status,
            // The overlay is laid over the video with the same box and the same
            // object-fit, so a point in the video's own pixels lands on the
            // same spot in both - the outlines are drawn in those pixels.
            // playsinline and muted are what iOS needs to play a live stream
            // inline without a tap.
            new HTML({
              content:
                `<div style="position:relative;height:50vh;min-height:14rem;background:#000;overflow:hidden">` +
                `<video id="${id}-video" playsinline muted autoplay ` +
                `style="position:absolute;top:0;left:0;width:100%;height:100%;object-fit:contain"></video>` +
                `<canvas id="${id}-overlay" ` +
                `style="position:absolute;top:0;left:0;width:100%;height:100%;object-fit:contain;pointer-events:none"></canvas>` +
                `</div>`,
            }),
            this._list,
          ],
          beginButton: this._ok,
          endButton: new Button({
            text: mText("MSGBOX_CANCEL", "Cancel"),
            press: () => this._dialog.close(),
          }),
          afterClose: () => this._stop(),
        });
        return this._dialog;
      },

      _video() {
        return document.getElementById(`${this.getId()}-video`);
      },

      _overlay() {
        return document.getElementById(`${this.getId()}-overlay`);
      },

      // A scan belongs to the session it was started in. Closing the dialog,
      // an error or the control's exit end the session, and every async
      // continuation checks it before touching the camera or the dialog.
      _isLive(session) {
        return (
          session === this._session &&
          !Util.isDestroyed(this) &&
          Boolean(this._dialog && this._dialog.isOpen())
        );
      },

      _stop() {
        this._session += 1;
        stopStream(this._stream);
        this._stream = null;
        const video = this._video();
        if (video) video.srcObject = null;
      },

      _constraints() {
        const video = { width: { ideal: 1920 }, height: { ideal: 1080 } };
        if (this.getDeviceId()) video.deviceId = { exact: this.getDeviceId() };
        else if (this.getFacingMode()) video.facingMode = { ideal: this.getFacingMode() };
        return { audio: false, video };
      },

      _readerOptions() {
        const formats = Util.toList(this.getFormats());
        return formats.length ? { formats } : {};
      },

      async _start(session, opened) {
        const media = navigator.mediaDevices;
        if (!media || !media.getUserMedia) {
          await opened;
          if (this._isLive(session)) {
            this._fail("The camera is only available on a secure (https) connection.");
          }
          return;
        }

        // camera and reader start side by side; allSettled because a camera
        // that started must be stopped again when the reader did not
        const [camera, library] = await Promise.allSettled([
          media.getUserMedia(this._constraints()),
          loadReader(this.getLibUrl(), this.getWasmUrl()),
        ]);
        await opened;

        const stream = camera.status === "fulfilled" ? camera.value : null;
        if (!this._isLive(session) || !stream || library.status !== "fulfilled") {
          stopStream(stream);
          if (!this._isLive(session)) return;
          this._fail(stream ? readerError(library.reason) : cameraError(camera.reason));
          return;
        }

        this._stream = stream;
        const video = this._video();
        if (!video) {
          this._fail("The camera preview could not be created.");
          return;
        }
        video.srcObject = stream;
        try {
          // some browsers ignore autoplay for a srcObject stream
          await video.play();
        } catch (e) {
          Util.logError("BarcodeScanner: video.play() failed", e);
        }
        if (!this._isLive(session)) return;

        const expected = BarcodeCollector.toCount(this.getExpected());
        this._setStatus(
          "Information",
          expected
            ? `Point the camera at the codes - the scan completes at ${expected}.`
            : "Point the camera at the codes, then press OK.",
        );
        this._scan(session, library.value);
      },

      async _scan(session, zxing) {
        const video = this._video();
        const overlay = this._overlay();
        const frame = document.createElement("canvas");
        const context = frame.getContext("2d", { willReadFrequently: true });
        const options = this._readerOptions();

        while (this._isLive(session)) {
          const width = video.videoWidth;
          const height = video.videoHeight;
          // no frame yet right after play(), and none while the stream stalls
          if (width && height && video.readyState >= 2) {
            if (frame.width !== width || frame.height !== height) {
              frame.width = width;
              frame.height = height;
            }
            context.drawImage(video, 0, 0, width, height);

            let results;
            try {
              results = await zxing.readBarcodes(context.getImageData(0, 0, width, height), options);
            } catch (e) {
              if (this._isLive(session)) this._fail(`The barcode reader failed: ${(e && e.message) || e}`);
              return;
            }
            if (!this._isLive(session)) return;

            // A reader that refuses its options - a misspelt format name in
            // `formats` - does not throw. It answers every frame with a result
            // of its own that carries the error and neither text nor format,
            // and the scan would run forever finding nothing.
            const refusal = results.find((result) => result && result.error && !result.format);
            if (refusal) {
              this._fail(`The barcode reader refused its settings: ${refusal.error}`);
              return;
            }

            const added = this._collector.add(results);
            this._outline(overlay, width, height, results);
            if (added.length) this._accept(added);
            if (this._collector.isComplete()) {
              this.finish();
              return;
            }
          }
          await pause(PAUSE);
        }
      },

      // Outlines every code of the frame, in the video's own pixels.
      _outline(overlay, width, height, results) {
        if (!overlay) return;
        if (overlay.width !== width || overlay.height !== height) {
          overlay.width = width;
          overlay.height = height;
        }
        const g = overlay.getContext("2d");
        g.clearRect(0, 0, width, height);
        // about 4px on screen whatever the camera resolution - the picture is
        // shown at roughly half its size in the dialog
        g.lineWidth = Math.max(4, Math.round(width / 160));
        g.lineJoin = "round";
        for (const result of results) {
          const p = result.position;
          if (!p) continue;
          g.strokeStyle = this._collector.isAccepted(result.format, result.text) ? ACCEPTED : PENDING;
          g.beginPath();
          g.moveTo(p.topLeft.x, p.topLeft.y);
          g.lineTo(p.topRight.x, p.topRight.y);
          g.lineTo(p.bottomRight.x, p.bottomRight.y);
          g.lineTo(p.bottomLeft.x, p.bottomLeft.y);
          g.closePath();
          g.stroke();
        }
      },

      _accept(added) {
        for (const code of added) {
          this._list.addItem(
            new StandardListItem({
              title: code.text,
              description: code.format,
              icon: "sap-icon://bar-code",
            }),
          );
        }
        // a short buzz per new code where the device has one (Android)
        if (navigator.vibrate) navigator.vibrate(40);
        this._syncCount();
      },

      // Forgets what was collected and keeps scanning.
      _restart() {
        if (!this._collector) return;
        this._collector.clear();
        this._list.destroyItems();
        this._syncCount();
      },

      _syncCount() {
        const count = this._collector ? this._collector.size() : 0;
        const expected = BarcodeCollector.toCount(this.getExpected());
        this._count.setText(expected ? `${count} / ${expected}` : String(count));
        this._ok.setEnabled(count > 0);
      },

      _setStatus(type, text) {
        this._status.setType(type);
        this._status.setText(text);
      },

      _fail(message) {
        Util.logError(`BarcodeScanner: ${message}`);
        this._stop();
        this._setStatus("Error", message);
        this.fireError({ message });
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          rm.openStart("span", control);
          rm.openEnd();
          rm.renderControl(control.getAggregation("_button"));
          rm.close("span");
        },
      },
    });
  },
);
