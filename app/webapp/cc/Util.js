// z2ui5cc.cc.Util - the few helpers every control in this library needs.
//
// It exists because most controls here wrap a third-party library that lives
// on a CDN, and because several of them have to find another control by the id
// an abap2UI5 app gave it. Both jobs are easy to get subtly wrong (loading the
// same script twice, resolving an id against the wrong view), so they live in
// one place.
//
// Deliberately NOT a dependency on z2ui5/core/Lib: that module is
// frontend-internal and not part of the public contract, so a control shipped
// from its own BSP must not reach into it - a refactor there would break the
// control silently.
sap.ui.define(["sap/ui/core/Element"], (Element) => {
  "use strict";

  // one promise per URL, so ten charts on one page load Chart.js once
  const scripts = new Map();
  const styles = new Map();

  const logError = (message, error) =>
    console.error(error === undefined ? message : `${message}:`, error ?? "");

  // Guards async continuations (script load, resize observer) against a
  // control that was torn down in the meantime.
  const isDestroyed = (obj) => Boolean(obj?.isDestroyed && obj.isDestroyed());

  // A bare number is treated as px, everything else is passed through.
  const toCssSize = (val) =>
    val === undefined || val === null || val === ""
      ? ""
      : /^-?\d+(\.\d+)?$/.test(String(val))
        ? `${val}px`
        : String(val);

  // Loads a script tag once and resolves when it is ready.
  //
  // `isReady` lets a caller skip the whole thing when the library is already
  // on the page - a system that ships Chart.js in its own BSP or in the
  // Launchpad shell never has to reach a CDN.
  function loadScript(url, isReady) {
    if (typeof isReady === "function" && isReady()) return Promise.resolve();
    if (!url) return Promise.reject(new Error("no library URL configured"));
    if (scripts.has(url)) return scripts.get(url);

    const pending = new Promise((resolve, reject) => {
      const tag = document.createElement("script");
      tag.src = url;
      tag.async = true;
      tag.addEventListener("load", () => resolve());
      tag.addEventListener("error", () =>
        reject(new Error(`could not load ${url}`)),
      );
      document.head.appendChild(tag);
    });

    // A failed load must not be cached as failed forever - a later render
    // (or a corrected URL) has to be able to try again.
    pending.catch(() => scripts.delete(url));
    scripts.set(url, pending);
    return pending;
  }

  // Same for a stylesheet. Resolving on load is rarely interesting for CSS,
  // but a caller that wants to render only afterwards can await it.
  function loadStyle(url) {
    if (!url) return Promise.resolve();
    if (styles.has(url)) return styles.get(url);

    const pending = new Promise((resolve, reject) => {
      const tag = document.createElement("link");
      tag.rel = "stylesheet";
      tag.href = url;
      tag.addEventListener("load", () => resolve());
      tag.addEventListener("error", () =>
        reject(new Error(`could not load ${url}`)),
      );
      document.head.appendChild(tag);
    });

    pending.catch(() => styles.delete(url));
    styles.set(url, pending);
    return pending;
  }

  // Loads a list of scripts strictly in order. Plugins usually have to come
  // after the library they extend, so Promise.all is wrong here.
  function loadScripts(urls) {
    return urls.reduce(
      (chain, url) => chain.then(() => loadScript(url)),
      Promise.resolve(),
    );
  }

  // The view a control was rendered into - the scope an abap2UI5 app's
  // control ids are relative to.
  function ownerView(control) {
    let node = control;
    while (node) {
      if (node.isA && node.isA("sap.ui.core.mvc.View")) return node;
      node = node.getParent ? node.getParent() : null;
    }
    return null;
  }

  // Resolves the id an abap2UI5 app wrote in the view (`id = 'myTable'`) to
  // the control instance.
  //
  // Three attempts, because the same app id can end up in three different
  // scopes: the main view, a nested view, or a popup/popover fragment. The
  // last attempt scans the element registry for an id ending in `--<id>`,
  // which covers every prefixing scheme without the control having to know
  // which view it landed in - that is what the old
  // z2ui5.oView/oViewNest/oViewPopup cascade was doing by hand.
  function resolveControl(control, id) {
    if (!id) return null;

    const view = ownerView(control);
    const local = view && view.byId(id);
    if (local) return local;

    const global = Element.getElementById ? Element.getElementById(id) : null;
    if (global) return global;

    try {
      const suffix = `--${id}`;
      const hits = Element.registry.filter((el) => el.getId().endsWith(suffix));
      if (hits.length === 1) return hits[0];
      if (hits.length > 1) {
        logError(
          `Util.resolveControl: id '${id}' is ambiguous, ${hits.length} controls match`,
        );
      }
    } catch (e) {
      // Element.registry is not part of every UI5 version - not finding the
      // control is a normal outcome, not a reason to throw out of a hook.
      logError("Util.resolveControl: element registry unavailable", e);
    }

    return null;
  }

  // Comma separated attribute value -> trimmed, non-empty list. XML views
  // hand array-typed properties over as strings, so the controls take plain
  // strings and split them here.
  const toList = (val) =>
    String(val || "")
      .split(",")
      .map((entry) => entry.trim())
      .filter(Boolean);

  return {
    isDestroyed,
    loadScript,
    loadScripts,
    loadStyle,
    logError,
    ownerView,
    resolveControl,
    toCssSize,
    toList,
  };
});
