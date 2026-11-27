// z2ui5_cci.cc.Clock - the browser's current date and time, ticking every
// second without a roundtrip to ABAP.
//
// It extends sap.m.Button on purpose. An OverflowToolbar moves only buttons
// (and a fixed list of sap.m controls) into its overflow menu, and from 1.71
// on it accepts any class extending sap.m.Button - so the clock can sit in a
// toolbar like any other button, with
// <OverflowToolbarLayoutData priority="AlwaysOverflow"/> in the menu as well.
// Outside a toolbar it renders like a transparent button: an optional icon and
// the time as its text.
//
// The text is the time. getText() returns it, so every rendering - in the
// toolbar, in the overflow menu that renders the button anew when it opens -
// starts with the current value. Between renderings the clock writes only the
// button's text node in the DOM and never calls setText: every property change
// of a toolbar item makes the OverflowToolbar lay itself out again, which
// closes an open overflow menu once a second.
//
// It replaces the usual way to show a clock: a global script, injected with
// the view, that searches every control on the page for a CSS class once a
// second.
sap.ui.define(["sap/m/Button", "sap/m/ButtonRenderer"], (Button, ButtonRenderer) => {
  "use strict";

  const OPTIONS = {
    datetime: {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    },
    date: { year: "numeric", month: "2-digit", day: "2-digit" },
    time: { hour: "2-digit", minute: "2-digit", second: "2-digit" },
    shorttime: { hour: "2-digit", minute: "2-digit" },
  };

  // The pure part, for tools/clock.test.mjs. An unknown format falls back to
  // datetime, an unknown locale to the browser's own.
  const format = (date, kind, locale) => {
    const options = OPTIONS[kind] || OPTIONS.datetime;
    try {
      return date.toLocaleString(locale || undefined, options);
    } catch (e) {
      // RangeError on a malformed locale tag
      return date.toLocaleString(undefined, options);
    }
  };

  const Clock = Button.extend("z2ui5_cci.cc.Clock", {
    metadata: {
      properties: {
        // datetime | date | time | shorttime
        format: { type: "string", defaultValue: "datetime" },
        // BCP 47 tag such as de-DE; empty: the UI5 language, else the browser
        locale: { type: "string", defaultValue: "" },
      },
    },

    // Named, not left out: without a renderer UI5 first asks the server for
    // a z2ui5_cci/cc/ClockRenderer.js that does not exist.
    renderer: ButtonRenderer,

    init() {
      if (Button.prototype.init) Button.prototype.init.apply(this, arguments);
      // a clock is read, not pressed - the caller can still set another type
      this.setType("Transparent");
    },

    _locale() {
      if (this.getLocale()) return this.getLocale();
      try {
        const core = sap.ui.getCore && sap.ui.getCore();
        return core ? core.getConfiguration().getLanguageTag() : "";
      } catch (e) {
        return "";
      }
    },

    getText() {
      return format(new Date(), this.getFormat(), this._locale());
    },

    _tick() {
      if (this.isDestroyed && this.isDestroyed()) return;
      const node =
        document.getElementById(`${this.getId()}-BDI-content`) ||
        this.getDomRef()?.querySelector(".sapMBtnContent");
      if (node) node.textContent = this.getText();
    },

    onAfterRendering() {
      if (Button.prototype.onAfterRendering) {
        Button.prototype.onAfterRendering.apply(this, arguments);
      }
      if (!this._clockTimer) {
        this._clockTimer = setInterval(() => this._tick(), 1000);
      }
    },

    exit() {
      clearInterval(this._clockTimer);
      this._clockTimer = null;
      if (Button.prototype.exit) Button.prototype.exit.apply(this, arguments);
    },
  });

  Clock.format = format;
  return Clock;
});
