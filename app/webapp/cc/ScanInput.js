// z2ui5_cci.cc.ScanInput - a sap.m.Input for barcode scanning: it keeps the
// focus, selects its content when focused, beeps and vibrates when its value
// state turns to Error, and switches the soft keyboard on and off in the
// browser. Everything here runs without a roundtrip; the backend sees only
// what it binds (value, valueState, keyboard) and the events.
//
// Why sap.m.Input and not z2ui5.cc.InputExt of the abap2UI5 frontend: that
// control adds one thing, the HTML inputmode as a property, and it lives in
// the frontend's deferred custom-control bundle. A control of this BSP that
// extends it would depend on the frontend release installed next to it and
// would fail on every system whose frontend has no InputExt yet. The
// inputmode is re-implemented below the same way InputExt does it (written
// without re-rendering, repeated in onAfterRendering).
//
// The control delegates, it never decides: it shows no popup and no toast.
// Whether an input is wrong is the backend's call (valueState); the control
// only turns that into a sound and a vibration.
//
//   keepFocus       after every response that touches the control (its
//                   rendering, any property the model writes), after a
//                   popup (dialog, popover, busy indicator) closed and when
//                   the focus fell to the page body, the focus goes back
//                   into the field. Never while another text field, an
//                   iframe or a popup holds the focus, never while a popup
//                   is open, never into a hidden, disabled or read-only
//                   field, never while the user has text selected on the
//                   page. Several fields with keepFocus: the one rendered
//                   last wins. A field inside a dialog counts only the
//                   popups above its own dialog (a scan field in a popup
//                   view keeps its focus there).
//   selectOnFocus   the content is selected when the field gets the focus,
//                   so the next scan replaces it
//   beepOnError     a short beep (WebAudio oscillator, no audio file) when
//   vibrateOnError  the value state turns to Error, and navigator.vibrate.
//                   Browsers allow both only after the user interacted with
//                   the page; before that, and where the API is missing, the
//                   control stays silent. "Turns to Error" is a change of
//                   valueState to Error on a rendered field, or - because a
//                   second wrong scan in a row leaves the value state at
//                   Error and the model fires nothing for it - the first
//                   model update after a submit or change while the state
//                   is Error (30 s at most).
//   keyboard        on: the field takes inputMode (the HTML inputmode, empty
//   inputMode       for the browser's default); off: inputmode "none" keeps
//                   the soft keyboard down while the scanner still types.
//                   Bind keyboard two-way; showKeyboardToggle draws a
//                   keyboard icon at the end of the field that switches it.
//
// UI5 1.71: every module used is in 1.71; isDestroyed( ) (1.93) is probed;
// InputBase.addEndIcon is the protected API sap.m.Input itself draws its
// value help icon with, in 1.71 as in current releases.
sap.ui.define(["sap/m/Input", "sap/m/InputRenderer"], (Input, InputRenderer) => {
  "use strict";

  // the complete inputmode keyword list of the HTML standard
  const HTML_MODES = ["decimal", "email", "none", "numeric", "search", "tel", "text", "url"];

  // <input type> values that take no text - focus there is no typing
  const NO_TEXT_TYPES = [
    "button", "checkbox", "color", "file", "hidden", "image", "radio", "range",
    "reset", "submit",
  ];

  const ERROR = "Error";
  const AWAIT_MS = 30000;
  const POLL_MS = 250;

  const logError = (message, error) =>
    console.error(error === undefined ? message : `${message}:`, error ?? "");

  const destroyed = (obj) =>
    Boolean(obj && (typeof obj.isDestroyed === "function" ? obj.isDestroyed() : obj.bIsDestroyed));

  // --- the pure part, for tools/scan-input.test.mjs -------------------------

  // "" for the browser's default, a keyword, or null for an unknown value
  const normalizeMode = (raw) => {
    if (raw === undefined || raw === null || raw === "") return "";
    const mode = String(raw).trim().toLowerCase();
    if (!mode) return "";
    return HTML_MODES.indexOf(mode) === -1 ? null : mode;
  };

  // the inputmode the field gets: off is always "none"
  const effectiveMode = (keyboard, inputMode) => {
    if (!keyboard) return "none";
    const mode = normalizeMode(inputMode);
    return mode === null ? "" : mode;
  };

  // does focus on this element mean the user is typing there?
  const isTextEntry = (el) => {
    if (!el || !el.tagName) return false;
    const tag = String(el.tagName).toUpperCase();
    if (tag === "TEXTAREA" || tag === "SELECT" || tag === "IFRAME") return true;
    if (tag === "INPUT") {
      return NO_TEXT_TYPES.indexOf(String(el.type || "text").toLowerCase()) === -1;
    }
    return el.isContentEditable === true;
  };

  // null: the field may take the focus now; otherwise why not. "popup" is
  // the one reason that ends by itself - the caller watches for it.
  const whyNot = (f) => {
    if (!f.keepFocus) return "off";
    if (!f.rendered) return "not rendered";
    if (!f.visible) return "hidden";
    if (!f.enabled || !f.editable) return "disabled";
    if (f.documentHidden) return "document hidden";
    if (f.hasFocus) return "has focus";
    if (f.popupOpen || f.activeInPopup) return "popup";
    if (f.activeIsTextEntry) return "typing elsewhere";
    if (f.textSelected) return "text selected";
    return null;
  };

  // does this value state change deserve a beep?
  //   previous, next  the value state before and after
  //   rendered        a field the user already sees - the first state of a
  //                   new field is no news
  //   awaiting        a submit or change is waiting for its answer
  const errorSignal = (s) => {
    if (s.next !== ERROR || !s.rendered) return false;
    return s.previous !== ERROR || s.awaiting === true;
  };

  // --- the page: one set of listeners for every instance ---------------------

  const page = {
    instances: [], // rendered instances, the last rendered last
    activated: false, // the user interacted with the page
    audio: null,
    timer: null,
    poll: null,
    listening: false,
  };

  const isShown = (el) => {
    if (!el || !el.getClientRects || el.getClientRects().length === 0) return false;
    try {
      return window.getComputedStyle(el).visibility !== "hidden";
    } catch (e) {
      return true;
    }
  };

  const zIndexOf = (el) => {
    try {
      const z = parseInt(window.getComputedStyle(el).zIndex, 10);
      return Number.isNaN(z) ? 0 : z;
    } catch (e) {
      return 0;
    }
  };

  // the popup (dialog) the field itself sits in, or null for a field on
  // the page
  const ownPopupOf = (root) =>
    root && root.closest ? root.closest("[data-sap-ui-popup]") : null;

  // an open UI5 popup - dialog, popover, menu, busy indicator, block layer -
  // that is not a toast and not one of the field's own (suggestions, value
  // state message, ids "<id>-..."). A field inside a dialog counts only what
  // lies ABOVE that dialog: its own dialog and the block layer under it are
  // no reason to keep the focus away.
  const popupOpen = (own, root) => {
    const ownPopup = ownPopupOf(root);
    const floor = ownPopup ? zIndexOf(ownPopup) : null;
    const above = (el) => floor === null || zIndexOf(el) > floor;
    const layer = document.getElementById("sap-ui-blocklayer-popup");
    if (isShown(layer) && above(layer)) return true;
    const popups = document.querySelectorAll("[data-sap-ui-popup]");
    for (let i = 0; i < popups.length; i++) {
      const el = popups[i];
      if (!isShown(el)) continue;
      if (el.classList && el.classList.contains("sapMMessageToast")) continue;
      if (own && el.id && el.id.indexOf(`${own}-`) === 0) continue;
      if (ownPopup && (el === ownPopup || el.contains(root))) continue;
      if (!above(el)) continue;
      return true;
    }
    return false;
  };

  const textSelected = () => {
    try {
      const sel = window.getSelection && window.getSelection();
      return Boolean(sel && !sel.isCollapsed && String(sel).trim() !== "");
    } catch (e) {
      return false;
    }
  };

  const wantsAudio = () => page.instances.some((i) => i.getBeepOnError());

  const unlockAudio = () => {
    if (!wantsAudio()) return;
    try {
      if (!page.audio) {
        const Ctx = window.AudioContext || window.webkitAudioContext;
        if (!Ctx) return;
        page.audio = new Ctx();
      }
      if (page.audio.state === "suspended" && page.audio.resume) {
        page.audio.resume().catch(() => {});
      }
    } catch (e) {
      logError("ScanInput: audio not available", e);
    }
  };

  const beep = () => {
    const ctx = page.audio;
    if (!page.activated || !ctx) return;
    try {
      if (ctx.state === "suspended" && ctx.resume) ctx.resume().catch(() => {});
      const t = ctx.currentTime;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "square";
      osc.frequency.setValueAtTime(440, t);
      gain.gain.setValueAtTime(0.0001, t);
      gain.gain.exponentialRampToValueAtTime(0.25, t + 0.01);
      gain.gain.exponentialRampToValueAtTime(0.0001, t + 0.25);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(t);
      osc.stop(t + 0.26);
    } catch (e) {
      logError("ScanInput: beep failed", e);
    }
  };

  const vibrate = () => {
    if (!page.activated || !navigator.vibrate) return;
    try {
      navigator.vibrate(200);
    } catch (e) {
      logError("ScanInput: vibrate failed", e);
    }
  };

  const stopPoll = () => {
    clearInterval(page.poll);
    page.poll = null;
  };

  // give the focus to the field that may take it - the one rendered last
  const run = () => {
    page.timer = null;
    if (!page.instances.length) {
      stopPoll();
      return;
    }
    let blocked = false;
    for (let i = page.instances.length - 1; i >= 0; i--) {
      const inst = page.instances[i];
      let reason;
      try {
        reason = whyNot(inst._facts());
      } catch (e) {
        logError("ScanInput: focus check failed", e);
        continue;
      }
      if (reason === "has focus") {
        stopPoll();
        return;
      }
      if (reason === null) {
        inst._takeFocus();
        stopPoll();
        return;
      }
      if (reason === "popup") blocked = true;
    }
    // a popup closes without telling anyone - look again until it is gone
    if (blocked && !page.poll) page.poll = setInterval(run, POLL_MS);
    if (!blocked) stopPoll();
  };

  const schedule = (delay) => {
    if (page.timer !== null || !page.instances.length) return;
    page.timer = setTimeout(run, delay || 0);
  };

  const onActivate = () => {
    page.activated = true;
    unlockAudio();
  };

  // the focus fell out of an element to nowhere - a re-render removed it,
  // a click on empty space; look a moment later where it ended up
  const onFocusOut = (e) => {
    if (e.relatedTarget) return;
    setTimeout(() => {
      const active = document.activeElement;
      if (!active || active === document.body || active === document.documentElement) {
        schedule(0);
      }
    }, 50);
  };

  const onVisible = () => {
    if (!document.hidden) schedule(0);
  };

  const listen = (on) => {
    if (on === page.listening) return;
    page.listening = on;
    const method = on ? "addEventListener" : "removeEventListener";
    ["pointerdown", "mousedown", "touchend", "keydown"].forEach((name) =>
      document[method](name, onActivate, true),
    );
    document[method]("focusout", onFocusOut, true);
    document[method]("visibilitychange", onVisible);
  };

  const register = (inst) => {
    const i = page.instances.indexOf(inst);
    if (i !== -1) page.instances.splice(i, 1);
    page.instances.push(inst);
    listen(true);
  };

  const unregister = (inst) => {
    const i = page.instances.indexOf(inst);
    if (i !== -1) page.instances.splice(i, 1);
    if (!page.instances.length) {
      listen(false);
      stopPoll();
      clearTimeout(page.timer);
      page.timer = null;
    }
  };

  // --- the control ------------------------------------------------------------

  const ScanInput = Input.extend("z2ui5_cci.cc.ScanInput", {
    metadata: {
      properties: {
        keepFocus: { type: "boolean", defaultValue: false },
        selectOnFocus: { type: "boolean", defaultValue: false },
        beepOnError: { type: "boolean", defaultValue: false },
        vibrateOnError: { type: "boolean", defaultValue: false },
        // soft keyboard on (inputMode) or off ("none") - bind two-way
        keyboard: { type: "boolean", defaultValue: true },
        // HTML inputmode while the keyboard is on; empty: browser default
        inputMode: { type: "string", defaultValue: "" },
        // a keyboard icon at the end of the field that switches `keyboard`
        showKeyboardToggle: { type: "boolean", defaultValue: false },
        keyboardToggleTooltip: { type: "string", defaultValue: "Keyboard" },
      },
      events: {
        // the user switched the keyboard with the icon
        keyboardChange: { parameters: { keyboard: { type: "boolean" } } },
      },
    },

    // Input's own: without it UI5 asks the server for ScanInputRenderer.js
    renderer: InputRenderer,

    // --- properties the renderer draws nothing from: no re-render ---------

    setKeepFocus(value) {
      this.setProperty("keepFocus", value, true);
      if (this.getKeepFocus() && this.getDomRef()) schedule(0);
      return this;
    },

    setSelectOnFocus(value) {
      this.setProperty("selectOnFocus", value, true);
      return this;
    },

    setBeepOnError(value) {
      this.setProperty("beepOnError", value, true);
      return this;
    },

    setVibrateOnError(value) {
      this.setProperty("vibrateOnError", value, true);
      return this;
    },

    setKeyboard(value) {
      this.setProperty("keyboard", value, true);
      this._applyMode();
      this._applyToggleState();
      return this;
    },

    setInputMode(value) {
      this.setProperty("inputMode", value, true);
      this._applyMode();
      return this;
    },

    setKeyboardToggleTooltip(value) {
      this.setProperty("keyboardToggleTooltip", value, true);
      this._applyToggleState();
      return this;
    },

    // Every property write passes here - the model's after a response
    // included. Two things hang on it: a value state that turns to Error,
    // and the focus going back after a response.
    setProperty(name, value, suppress) {
      const previous = name === "valueState" ? this.getProperty("valueState") : undefined;
      const result = Input.prototype.setProperty.apply(this, arguments);
      try {
        this._afterProperty(name, previous, suppress);
      } catch (e) {
        logError("ScanInput: property hook failed", e);
      }
      return result;
    },

    _afterProperty(name, previous) {
      if (destroyed(this)) return;
      const rendered = Boolean(this.getDomRef());
      if (name === "valueState") {
        const signal = errorSignal({
          previous,
          next: this.getProperty("valueState"),
          rendered,
          awaiting: false,
        });
        if (signal) {
          this._awaiting = 0;
          this._signal();
        }
      }
      // the first update after a submit answers it: an Error that stayed
      // Error is a new error all the same
      if (this._awaitArmed && this._awaiting && !this._awaitCheck) {
        this._awaitCheck = setTimeout(() => {
          this._awaitCheck = null;
          const fresh = Date.now() - this._awaiting < AWAIT_MS;
          this._awaiting = 0;
          if (destroyed(this) || !fresh) return;
          const v = this.getValueState();
          if (errorSignal({ previous: v, next: v, rendered: Boolean(this.getDomRef()), awaiting: true })) {
            this._signal();
          }
        }, 0);
      }
      if (rendered && this.getKeepFocus()) schedule(0);
    },

    _signal() {
      const now = Date.now();
      if (this._lastSignal && now - this._lastSignal < 300) return;
      this._lastSignal = now;
      if (this.getBeepOnError()) beep();
      if (this.getVibrateOnError()) vibrate();
    },

    // arm in the next task: the setValue of the same Enter is no answer
    _await() {
      this._awaiting = Date.now();
      this._awaitArmed = false;
      setTimeout(() => {
        this._awaitArmed = true;
      }, 0);
    },

    fireSubmit() {
      this._await();
      return Input.prototype.fireSubmit.apply(this, arguments);
    },

    fireChange() {
      this._await();
      return Input.prototype.fireChange.apply(this, arguments);
    },

    // --- inputmode -------------------------------------------------------------

    _htmlMode() {
      const raw = this.getInputMode();
      if (normalizeMode(raw) === null && this._refusedMode !== raw) {
        this._refusedMode = raw;
        logError(`ScanInput: inputMode "${raw}" is not an HTML inputmode keyword - ignored`);
      }
      return effectiveMode(this.getKeyboard(), raw);
    },

    _applyMode() {
      const dom = this.getFocusDomRef();
      if (!dom || !dom.setAttribute || dom === this.getDomRef()) return;
      const mode = this._htmlMode();
      if (mode) dom.setAttribute("inputmode", mode);
      else if (this._renderedMode) dom.setAttribute("inputmode", this._renderedMode);
      else dom.removeAttribute("inputmode");
    },

    // --- the keyboard toggle -----------------------------------------------------

    _getToggle() {
      if (this._toggle && !destroyed(this._toggle)) return this._toggle;
      // sap.m.Input 1.71 takes the FIRST end icon for its value help icon,
      // so that one has to exist before ours
      const icons = this.getAggregation("_endIcon") || [];
      if (!icons.length && typeof this._getValueHelpIcon === "function") {
        try {
          const vhi = this._getValueHelpIcon();
          if (vhi) vhi.setProperty("visible", Boolean(this.getShowValueHelp()), true);
        } catch (e) {
          logError("ScanInput: value help icon", e);
        }
      }
      this._toggle = this.addEndIcon({
        id: `${this.getId()}-kbd`,
        src: "sap-icon://keyboard-and-mouse",
        useIconTooltip: false,
        noTabStop: true,
        press: () => this._onToggle(),
      });
      return this._toggle;
    },

    _onToggle() {
      try {
        if (!this.getEnabled() || !this.getEditable()) return;
        const next = !this.getKeyboard();
        this.setKeyboard(next);
        this.fireKeyboardChange({ keyboard: next });
        // still inside the tap: blur and focus make the browser show or hide
        // the soft keyboard for the new inputmode
        const dom = this.getFocusDomRef();
        if (dom && dom.focus) {
          if (document.activeElement === dom && dom.blur) dom.blur();
          dom.focus();
        }
      } catch (e) {
        logError("ScanInput: keyboard toggle failed", e);
      }
    },

    _applyToggleState() {
      const icon = this._toggle;
      if (!icon || destroyed(icon)) return;
      const on = this.getKeyboard();
      // the pressed look sap.m uses for its own field icons
      if (on) this.addStyleClass("sapMInputBaseIconPressed");
      else this.removeStyleClass("sapMInputBaseIconPressed");
      const dom = icon.getDomRef();
      if (dom) {
        dom.setAttribute("aria-pressed", on ? "true" : "false");
        dom.setAttribute("title", this.getKeyboardToggleTooltip());
      }
    },

    // --- focus -----------------------------------------------------------------

    _facts() {
      const root = this.getDomRef();
      const dom = this.getFocusDomRef();
      const active = document.activeElement;
      const rendered = Boolean(root && dom && document.body && document.body.contains(root));
      return {
        keepFocus: this.getKeepFocus(),
        rendered,
        visible: rendered && this.getVisible() && isShown(root),
        enabled: this.getEnabled(),
        editable: this.getEditable(),
        documentHidden: document.hidden === true,
        hasFocus: Boolean(rendered && active && root.contains(active)),
        popupOpen: popupOpen(this.getId(), root),
        activeInPopup: Boolean(
          active &&
            active.closest &&
            active.closest("[data-sap-ui-popup]") &&
            active.closest("[data-sap-ui-popup]") !== ownPopupOf(root),
        ),
        activeIsTextEntry: isTextEntry(active),
        textSelected: textSelected(),
      };
    },

    _takeFocus() {
      const dom = this.getFocusDomRef();
      if (dom && dom.focus) dom.focus();
    },

    _select() {
      const dom = this.getFocusDomRef();
      if (!dom || document.activeElement !== dom || !dom.value) return;
      try {
        dom.select();
      } catch (e) {
        // an input type without a selection
      }
    },

    onfocusin(event) {
      if (Input.prototype.onfocusin) Input.prototype.onfocusin.apply(this, arguments);
      if (!this.getSelectOnFocus()) return;
      // the mouseup / tap that brought the focus would put the caret back
      this._selectPending = true;
      setTimeout(() => this._select(), 0);
    },

    onmouseup(event) {
      if (Input.prototype.onmouseup) Input.prototype.onmouseup.apply(this, arguments);
      if (!this._selectPending) return;
      this._selectPending = false;
      if (event && event.preventDefault) event.preventDefault();
      this._select();
    },

    ontouchend() {
      if (Input.prototype.ontouchend) Input.prototype.ontouchend.apply(this, arguments);
      if (this._selectPending) setTimeout(() => this._select(), 0);
    },

    onBeforeRendering() {
      Input.prototype.onBeforeRendering.apply(this, arguments);
      try {
        if (this.getShowKeyboardToggle() || this._toggle) {
          // after Input's own onBeforeRendering, which sets visibility on
          // the first end icon in 1.71
          this._getToggle().setProperty("visible", this.getShowKeyboardToggle(), true);
        }
      } catch (e) {
        logError("ScanInput: keyboard toggle", e);
      }
    },

    onAfterRendering() {
      Input.prototype.onAfterRendering.apply(this, arguments);
      try {
        // what sap.m.Input itself rendered (nothing today), so that an empty
        // mode gives that back
        const dom = this.getFocusDomRef();
        this._renderedMode = dom && dom.getAttribute ? dom.getAttribute("inputmode") : null;
        this._applyMode();
        this._applyToggleState();
        register(this);
        if (this.getKeepFocus()) schedule(0);
      } catch (e) {
        logError("ScanInput: after rendering", e);
      }
    },

    exit() {
      unregister(this);
      clearTimeout(this._awaitCheck);
      if (Input.prototype.exit) Input.prototype.exit.apply(this, arguments);
    },
  });

  ScanInput.normalizeMode = normalizeMode;
  ScanInput.effectiveMode = effectiveMode;
  ScanInput.isTextEntry = isTextEntry;
  ScanInput.whyNot = whyNot;
  ScanInput.errorSignal = errorSignal;
  return ScanInput;
});
