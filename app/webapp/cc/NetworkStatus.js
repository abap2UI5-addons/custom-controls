// z2ui5_cci.cc.NetworkStatus - shows whether the browser is online and the
// server answers: a coloured icon, optionally with a text, signal bars and the
// measured latency. Everything runs in the browser, no roundtrip to ABAP.
//
// Three states:
//
//   online       network present; if a ping URL is set, it answered
//   unreachable  network present, but the ping got no answer in time
//   offline      the browser has no network at all (navigator.onLine)
//
// navigator.onLine = false is a sure offline; true only means some network
// is there, which is why the control also pings. The default ping URL is the
// SAP ICF service /sap/public/ping - no logon, no ABAP roundtrip, no session.
// It has to be active in SICF; when it answers with an HTTP error the server
// is still reachable, and the details say which status came back.
//
// Every instance with the same ping settings shares one monitor: one listener
// set and one ping loop, however many status icons a page shows. The monitor
// stops with its last instance and keeps its last result, so the control a
// new view_display renders shows the known state at once instead of starting
// from nothing.
//
// The state is written into the DOM, never by re-rendering this control.
// status, latency and quality are still properties - bind them and the
// backend sees the state on the next roundtrip; the event `change` fires when
// the state changes. An OverflowToolbar observes every property change of its
// content - a suppressed invalidation included - and lays itself out again,
// which closes its open overflow menu: with a ping every 5 seconds the menu
// closed after a few seconds. So the control implements
// sap.m.IOverflowToolbarContent and names these three as unrelated to its
// size; the toolbar then leaves its layout - and its menu - alone.
//
// Ported from the S5S apps (/KRO/UI501_CL_APP_VIEW=>get_net_status_js and
// /KRO/UI508_CL_APP_003), which injected the same logic as a global script
// and polled every control on the page once a second for a CSS class.
sap.ui.define(["sap/ui/core/Control", "sap/ui/core/Icon"], (Control, Icon) => {
  "use strict";

  const ICON = {
    online: "sap-icon://connected",
    unreachable: "sap-icon://connected",
    offline: "sap-icon://disconnected",
  };

  const COLOR = {
    online: "Positive",
    unreachable: "Critical",
    offline: "Negative",
  };

  // Network Information API (Chromium only): effectiveType -> signal bars,
  // used until the first ping has a latency.
  const LEVELS = { "slow-2g": 1, "2g": 2, "3g": 3, "4g": 4 };

  // The pure part: browser facts in, displayed state out. Kept free of the
  // DOM and of UI5 so tools/network-status.test.mjs can call it directly.
  //
  //   facts.online      navigator.onLine !== false
  //   facts.ping        null (no ping yet / none configured) or
  //                     { ok, ms, status } - ok false means no answer
  //   facts.connection  navigator.connection or null
  const evaluate = (facts) => {
    const ping = facts.ping;
    const conn = facts.connection;
    const result = { status: "online", latency: -1, quality: 0, details: [] };

    if (!facts.online) {
      result.status = "offline";
      return result;
    }
    if (ping && ping.ok === false) {
      result.status = "unreachable";
      return result;
    }
    if (ping && ping.ok === true) {
      result.latency = ping.ms;
      // under 250 ms 4 bars, under 500 ms 3, under 750 ms 2, else 1
      result.quality = 4 - Math.min(3, Math.floor(ping.ms / 250));
      result.details.push(`${ping.ms} ms`);
      if (!/^2/.test(String(ping.status))) {
        result.details.push(`HTTP ${ping.status}`);
      }
    } else if (conn && LEVELS[conn.effectiveType]) {
      result.quality = LEVELS[conn.effectiveType];
    }
    if (conn && conn.effectiveType) {
      result.details.push(String(conn.effectiveType).toUpperCase());
      if (conn.downlink) result.details.push(`${conn.downlink} Mbit/s`);
    }
    return result;
  };

  const logError = (message, error) =>
    console.error(error === undefined ? message : `${message}:`, error ?? "");

  // --- the shared monitor ---------------------------------------------------

  const monitors = new Map();

  const facts = (monitor) => ({
    online: navigator.onLine !== false,
    ping: monitor.ping,
    connection: navigator.connection || null,
  });

  const notify = (monitor) => {
    const state = evaluate(facts(monitor));
    monitor.listeners.forEach((listener) => {
      try {
        listener(state);
      } catch (e) {
        logError("NetworkStatus: listener failed", e);
      }
    });
  };

  const doPing = (monitor) => {
    if (!monitor.url || !window.fetch) return;
    // no network - nothing to ask; a hidden tab does not need to know
    if (navigator.onLine === false || document.hidden) return;
    if (monitor.pending) return;
    monitor.pending = true;

    const start = performance.now();
    const controller =
      typeof AbortController === "function" ? new AbortController() : null;
    let done = false;
    const finish = (ping) => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      monitor.pending = false;
      monitor.ping = ping;
      notify(monitor);
    };
    const timer = setTimeout(() => {
      if (controller) controller.abort();
      finish({ ok: false, ms: null, status: 0 });
    }, monitor.timeout);

    // The timestamp and no-store keep any cache from answering for the
    // server; credentials stay home - the ping needs no session.
    const sep = monitor.url.indexOf("?") === -1 ? "?" : "&";
    fetch(`${monitor.url}${sep}_=${Date.now()}`, {
      cache: "no-store",
      credentials: "omit",
      signal: controller ? controller.signal : undefined,
    }).then(
      (response) =>
        finish({
          ok: true,
          ms: Math.round(performance.now() - start),
          status: response.status,
        }),
      () => finish({ ok: false, ms: null, status: 0 }),
    );
  };

  const start = (monitor) => {
    monitor.onOnline = () => {
      // the old result says nothing about the new connection
      monitor.ping = null;
      notify(monitor);
      doPing(monitor);
    };
    monitor.onChange = () => notify(monitor);
    monitor.onVisible = () => {
      if (!document.hidden) doPing(monitor);
    };
    window.addEventListener("online", monitor.onOnline);
    window.addEventListener("offline", monitor.onChange);
    document.addEventListener("visibilitychange", monitor.onVisible);
    if (navigator.connection && navigator.connection.addEventListener) {
      navigator.connection.addEventListener("change", monitor.onChange);
    }
    if (monitor.url) {
      monitor.interval = setInterval(() => doPing(monitor), monitor.every);
      doPing(monitor);
    }
  };

  const stop = (monitor) => {
    window.removeEventListener("online", monitor.onOnline);
    window.removeEventListener("offline", monitor.onChange);
    document.removeEventListener("visibilitychange", monitor.onVisible);
    if (navigator.connection && navigator.connection.removeEventListener) {
      navigator.connection.removeEventListener("change", monitor.onChange);
    }
    clearInterval(monitor.interval);
    monitor.interval = null;
  };

  // Returns the unsubscribe function.
  const subscribe = (url, every, timeout, listener) => {
    const key = `${url}|${every}|${timeout}`;
    let monitor = monitors.get(key);
    if (!monitor) {
      monitor = { url, every, timeout, ping: null, listeners: new Set() };
      monitors.set(key, monitor);
    }
    monitor.listeners.add(listener);
    if (monitor.listeners.size === 1) start(monitor);
    listener(evaluate(facts(monitor)));
    return () => {
      monitor.listeners.delete(listener);
      if (monitor.listeners.size === 0) stop(monitor);
    };
  };

  // --- the control ------------------------------------------------------------

  const NetworkStatus = Control.extend("z2ui5_cci.cc.NetworkStatus", {
    metadata: {
      // getOverflowToolbarConfig( ) below - see the header
      interfaces: ["sap.m.IOverflowToolbarContent"],
      properties: {
        // Written by the control - bind them to read the state in ABAP.
        // status: online | unreachable | offline
        status: { type: "string", defaultValue: "" },
        // ping round trip in ms, -1 while unknown
        latency: { type: "int", defaultValue: -1 },
        // 0 - 4 signal bars
        quality: { type: "int", defaultValue: 0 },

        // false: no ping, only the browser's own online flag. A switch of
        // its own because an empty attribute cannot be told from a missing
        // one - the ABAP builder drops both.
        ping: { type: "boolean", defaultValue: true },
        pingUrl: { type: "string", defaultValue: "/sap/public/ping" },
        pingInterval: { type: "int", defaultValue: 5000 },
        pingTimeout: { type: "int", defaultValue: 3000 },

        iconSize: { type: "string", defaultValue: "" },
        showText: { type: "boolean", defaultValue: false },
        showQuality: { type: "boolean", defaultValue: false },
        showDetails: { type: "boolean", defaultValue: false },

        textOnline: { type: "string", defaultValue: "Online" },
        textUnreachable: {
          type: "string",
          defaultValue: "Server not reachable",
        },
        textOffline: { type: "string", defaultValue: "Offline" },
      },
      aggregations: {
        _icon: { type: "sap.ui.core.Icon", multiple: false, visibility: "hidden" },
      },
      events: {
        // fired when status changes, not on every new latency. A roundtrip
        // event bound here fires when the browser goes offline too - and
        // that roundtrip cannot reach the server.
        change: {
          parameters: {
            status: { type: "string" },
            latency: { type: "int" },
          },
        },
      },
    },

    _getIcon() {
      let icon = this.getAggregation("_icon");
      if (!icon) {
        icon = new Icon({
          src: ICON.online,
          color: "Neutral",
          decorative: false,
        });
        this.setAggregation("_icon", icon, true);
      }
      return icon;
    },

    _text(status) {
      if (status === "offline") return this.getTextOffline();
      if (status === "unreachable") return this.getTextUnreachable();
      return this.getTextOnline();
    },

    _apply(state) {
      if (this.isDestroyed && this.isDestroyed()) return;
      // the last state this control showed - not getStatus( ), which a
      // binding can overwrite with what the backend sent back
      const previous = this._shown;
      this._shown = state.status;
      const label = this._text(state.status);
      const details = state.details.join(" · ");

      // suppress invalidation - see the header; a binding still writes back
      this.setProperty("status", state.status, true);
      this.setProperty("latency", state.latency, true);
      this.setProperty("quality", state.quality, true);

      const icon = this._getIcon();
      if (icon.getSrc() !== ICON[state.status]) icon.setSrc(ICON[state.status]);
      if (icon.getColor() !== COLOR[state.status]) {
        icon.setColor(COLOR[state.status]);
      }
      if (icon.getAlt() !== label) icon.setAlt(label);

      const dom = this.getDomRef();
      if (dom) {
        dom.title = details ? `${label} - ${details}` : label;
        const text = dom.querySelector(".z2ui5cciNetText");
        if (text) text.textContent = label;
        const detail = dom.querySelector(".z2ui5cciNetDetails");
        if (detail) detail.textContent = details;
        dom.querySelectorAll(".z2ui5cciNetBar").forEach((bar, index) => {
          bar.style.background =
            index < state.quality
              ? "var(--sapContent_IconColor, #0064d9)"
              : "var(--sapContent_DisabledTextColor, #c4c4c4)";
        });
      }

      if (previous && previous !== state.status) {
        this.fireChange({ status: state.status, latency: state.latency });
      }
    },

    // sap.m.IOverflowToolbarContent: the state the ping writes changes
    // nothing about the control's size, so a toolbar must not lay itself out
    // again for it - that closed an open overflow menu on every ping. The
    // status icon never goes into the overflow menu itself.
    getOverflowToolbarConfig() {
      return {
        canOverflow: false,
        propsUnrelatedToSize: ["status", "latency", "quality"],
      };
    },

    _pingUrl() {
      return this.getPing() ? this.getPingUrl() : "";
    },

    onAfterRendering() {
      const key = `${this._pingUrl()}|${this.getPingInterval()}|${this.getPingTimeout()}`;
      if (this._unsubscribe && this._key === key) {
        // re-rendered with the same settings - the DOM is new, fill it in
        this._apply(this._state);
        return;
      }
      if (this._unsubscribe) this._unsubscribe();
      this._key = key;
      this._unsubscribe = subscribe(
        this._pingUrl(),
        Math.max(1000, this.getPingInterval()),
        Math.max(500, this.getPingTimeout()),
        (state) => {
          this._state = state;
          this._apply(state);
        },
      );
    },

    exit() {
      if (this._unsubscribe) this._unsubscribe();
      this._unsubscribe = null;
    },

    renderer: {
      apiVersion: 2,
      render(oRm, oControl) {
        const icon = oControl._getIcon();
        if (oControl.getIconSize()) icon.setSize(oControl.getIconSize());

        oRm.openStart("span", oControl);
        oRm.attr("role", "status");
        oRm.style("display", "inline-flex");
        oRm.style("align-items", "center");
        oRm.style("gap", "0.5rem");
        oRm.style("vertical-align", "middle");
        oRm.openEnd();

        oRm.renderControl(icon);

        if (oControl.getShowText()) {
          oRm.openStart("span");
          oRm.class("z2ui5cciNetText");
          oRm.style("color", "var(--sapTextColor, #1d2d3e)");
          oRm.openEnd();
          oRm.close("span");
        }

        if (oControl.getShowQuality()) {
          oRm.openStart("span");
          oRm.attr("aria-hidden", "true");
          oRm.style("display", "inline-flex");
          oRm.style("align-items", "flex-end");
          oRm.style("gap", "2px");
          oRm.style("height", "1rem");
          oRm.openEnd();
          for (let i = 1; i <= 4; i++) {
            oRm.openStart("span");
            oRm.class("z2ui5cciNetBar");
            oRm.style("width", "4px");
            oRm.style("height", `${i * 25}%`);
            oRm.style("border-radius", "1px");
            oRm.style("background", "var(--sapContent_DisabledTextColor, #c4c4c4)");
            oRm.openEnd();
            oRm.close("span");
          }
          oRm.close("span");
        }

        if (oControl.getShowDetails()) {
          oRm.openStart("span");
          oRm.class("z2ui5cciNetDetails");
          oRm.style("color", "var(--sapContent_LabelColor, #556b82)");
          oRm.openEnd();
          oRm.close("span");
        }

        oRm.close("span");
      },
    },
  });

  NetworkStatus.evaluate = evaluate;
  return NetworkStatus;
});
