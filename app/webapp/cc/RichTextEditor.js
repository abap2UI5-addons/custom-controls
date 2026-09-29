// z2ui5_cci.cc.RichTextEditor - a WYSIWYG editor for HTML, bound to an ABAP
// string.
//
// UI5's own sap.ui.richtexteditor.RichTextEditor ships with SAPUI5 only, and
// abap2UI5 bootstraps OpenUI5 unless told otherwise - where that control does
// not exist and the view fails to load. This one runs on both: SunEditor 3
// (MIT), loaded on first use like every library of this BSP - from jsDelivr on
// `main`, from the BSP itself on the `local` branch.
//
// How it talks to ABAP:
//
//   value    the HTML, bound two-way with client->_bind( ). The model follows
//            the typing - SunEditor reports a change once the typing pauses -
//            and is brought fully up to date when the editor loses focus,
//            which happens before a button elsewhere can start a roundtrip.
//   change   fired when the editor loses focus holding a different value than
//            when it got it: the moment to validate or save, not a roundtrip
//            per keystroke.
//
// A value the backend sets is written into the editor without re-rendering the
// control, and the editor's own echo of it is not written back: SunEditor
// normalizes what it is given (plain text gains a <p>), and an app should get
// back what it sent until somebody actually edits it.
//
// The HTML goes through DOMPurify on the way in and on the way out unless
// `sanitize` is off - the value ends up in some other page one day, and what
// comes in may have been typed by somebody else.
//
// The editor follows the UI5 theme: SunEditor draws with CSS variables, and the
// ones for surfaces, text, borders and toolbar states are mapped to UI5 theme
// parameters below, with SunEditor's own light values as the fallback.
sap.ui.define(
  ["sap/ui/core/Control", "z2ui5_cci/cc/Util", "z2ui5_cci/cc/LibUrls"],
  (Control, Util, LibUrls) => {
    "use strict";

    const LIB_URL = LibUrls.sunEditor;
    const CSS_URL = LibUrls.sunEditorCss;
    const PURIFY_URL = LibUrls.domPurify;

    // What business text needs, and nothing that reaches a server: no video,
    // audio or embeds (third-party frames), no math (a CDN library), no
    // galleries or uploads (a server endpoint), no print or preview (a new
    // window with its own page). An image is inserted as a data URI.
    const DEFAULT_TOOLBAR = [
      ["undo", "redo"],
      ["blockStyle", "font", "fontSize"],
      ["bold", "underline", "italic", "strike", "subscript", "superscript"],
      ["fontColor", "backgroundColor", "removeFormat"],
      ["align", "list_numbered", "list_bulleted", "outdent", "indent"],
      ["table", "link", "image", "hr"],
      ["fullScreen", "codeView"],
    ];

    // The plugins a toolbar may use - the default one and any the app writes.
    // Deliberately a list rather than SUNEDITOR.plugins as a whole: several of
    // the others talk to a server or type-ahead on every `/` and `@`.
    const PLUGINS = [
      "align",
      "anchor",
      "backgroundColor",
      "blockquote",
      "blockStyle",
      "codeBlock",
      "font",
      "fontColor",
      "fontSize",
      "hr",
      "image",
      "lineHeight",
      "link",
      "list",
      "list_bulleted",
      "list_numbered",
      "paragraphStyle",
      "table",
      "textStyle",
    ];

    // UI5 language tags SunEditor spells differently. Its files are named
    // after a code of its own (se for Swedish, pt_br, zh_cn), and SAP systems
    // still hand out iw for Hebrew.
    const LANG_ALIASES = { sv: "se", iw: "he", pt: "pt_br", zh: "zh_cn" };

    // Every language but English is a file of its own, listed in LibUrls as
    // sunEditorLang_<code> - so a language is available exactly when this
    // BSP's build carries it. English is in the bundle.
    function langCode(tag) {
      const t = String(tag || "").toLowerCase().replace(/-/g, "_");
      const primary = t.split("_")[0];
      if (!primary || primary === "en") return "";
      // traditional Chinese has no file, and simplified is not a stand-in
      if (primary === "zh" && /_(tw|hk|mo|hant)/.test(t)) return "";
      for (const code of [t, LANG_ALIASES[primary], primary]) {
        if (code && LibUrls[`sunEditorLang_${code}`]) return code;
      }
      return "";
    }

    // `undo,redo|bold,italic|link` -> [["undo","redo"],["bold","italic"],["link"]]
    // - groups by `|`, buttons by `,`, which reads better in an ABAP literal
    // than the nested JSON array SunEditor takes.
    function toButtonList(val) {
      return String(val || "")
        .split("|")
        .map(Util.toList)
        .filter((group) => group.length);
    }

    // SunEditor puts its pop-ups - the link and image controllers, the
    // dropdowns - into a wrapper of their own at the end of <body>, outside
    // this control, so that wrapper is themed as well. Every SunEditor on an
    // abap2UI5 page is one of these controls. The doubled class outranks
    // SunEditor's own `.sun-editor`, whose stylesheet loads after this one.
    const STYLE_ID = "z2ui5_cci-richtexteditor-style";
    const STYLE = `
.z2ui5_cciRichTextEditor .sun-editor,
.sun-editor.sun-editor-carrier-wrapper {
  font-family: var(--sapFontFamily, "Helvetica Neue", Arial, sans-serif);
}
.z2ui5_cciRichTextEditor .sun-editor,
.z2ui5_cciRichTextEditor .sun-editor-editable,
.sun-editor.sun-editor-carrier-wrapper {
  --se-main-background-color: var(--sapGroup_ContentBackground, #fff);
  --se-main-font-color: var(--sapTextColor, #333);
  --se-main-color: var(--sapTextColor, #18181b);
  --se-main-color-lighter: var(--sapContent_LabelColor, #4c4c4d);
  --se-main-border-color: var(--sapField_BorderColor, #d1d1d1);
  --se-main-divider-color: var(--sapGroup_TitleBorderColor, #e1e1e1);
  --se-main-out-color: var(--sapList_BorderColor, #dadada);
  --se-main-outline-color: var(--sapContent_FocusColor, #b1b1b1);
  --se-main-shadow-color: var(--sapContent_ShadowColor, #ececec);
  --se-statusbar-font-color: var(--sapContent_LabelColor, #666);
  --se-edit-background-color: var(--sapField_Background, #fff);
  --se-edit-font-color: var(--sapField_TextColor, #333);
  --se-caret-color: var(--sapField_TextColor, #333);
  --se-placeholder-color: var(--sapField_PlaceholderTextColor, #bbb);
  --se-edit-anchor: var(--sapLinkColor, #0056b3);
  --se-edit-font-pre: var(--sapContent_LabelColor, #666);
  --se-edit-font-quote: var(--sapContent_LabelColor, #999);
  --se-edit-background-pre: var(--sapBackgroundColor, #f9f9f9);
  --se-edit-border-table: var(--sapList_BorderColor, #cecece);
  --se-edit-hr-color: var(--sapGroup_TitleBorderColor, #333);
  --se-hover-light-color: var(--sapButton_Lite_Hover_Background, #e1e1e1);
  --se-hover-light2-color: var(--sapButton_Lite_Hover_Background, #e6e6e6);
  --se-hover-light3-color: var(--sapButton_Lite_Hover_Background, #d9d9d9);
  --se-active-light-color: var(--sapButton_Selected_Background, #e6f2ff);
  --se-active-light2-color: var(--sapButton_Selected_Background, #eaf3ff);
  --se-active-light3-color: var(--sapButton_Selected_Hover_Background, #d0e3ff);
  --se-active-light4-color: var(--sapButton_Selected_Hover_Background, #dbeaff);
  --se-active-dark3-color: var(--sapButton_Selected_TextColor, #4592ff);
  --se-active-dark5-color: var(--sapButton_Selected_TextColor, #1275ff);
  --se-modal-background-color: var(--sapGroup_ContentBackground, #fff);
  --se-modal-color: var(--sapTextColor, #333);
  --se-modal-border-color: var(--sapGroup_TitleBorderColor, #e5e5e5);
  --se-modal-anchor-color: var(--sapLinkColor, #004cff);
  --se-modal-preview-color: var(--sapContent_LabelColor, #666);
  --se-modal-file-input-background-color: var(--sapField_Background, #f9f9f9);
  --se-dropdown-font-color: var(--sapTextColor, #555);
  --se-controller-background-color: var(--sapGroup_ContentBackground, #fff);
  --se-controller-color: var(--sapTextColor, #333);
  --se-controller-border-color: var(--sapField_BorderColor, #999);
  --se-table-picker-color: var(--sapField_Background, #f5f5f5);
  --se-table-picker-border-color: var(--sapField_BorderColor, #ddd);
  --se-table-picker-highlight-color: var(--sapButton_Selected_Background, #cce0ff);
  --se-input-btn-border-color: var(--sapField_BorderColor, #ccc);
  --se-code-view-background-color: var(--sapField_Background, #fff);
  --se-code-view-color: var(--sapField_TextColor, #24292f);
  --se-code-view-line-background-color: var(--sapBackgroundColor, #f6f8fa);
  --se-code-view-line-color: var(--sapContent_LabelColor, #57606a);
  --se-content-font-family: var(--sapFontFamily, "Helvetica Neue");
}
`;

    function injectStyle() {
      if (document.getElementById(STYLE_ID)) return;
      const tag = document.createElement("style");
      tag.id = STYLE_ID;
      tag.textContent = STYLE;
      document.head.appendChild(tag);
    }

    return Control.extend("z2ui5_cci.cc.RichTextEditor", {
      metadata: {
        properties: {
          // the HTML - bind it two-way to the ABAP string that carries it
          value: { type: "string", defaultValue: "" },
          editable: { type: "boolean", defaultValue: true },
          width: { type: "string", defaultValue: "100%" },
          // Height of the editing area, below the toolbar. Empty lets it grow
          // with the text; set it and the text scrolls inside it instead.
          height: { type: "string", defaultValue: "" },
          placeholder: { type: "string", defaultValue: "" },
          // The toolbar as button groups: `undo,redo|bold,italic|link`. Empty
          // is the default toolbar above. The names are SunEditor's.
          toolbar: { type: "string", defaultValue: "" },
          // SunEditor's language code (de, fr, pt_br, ...). Empty follows the
          // UI5 language; English, or a language without a file, is English.
          language: { type: "string", defaultValue: "" },
          // Runs the HTML through DOMPurify in both directions. Turning it off
          // trusts whatever the value holds - only for text written by your
          // own developers, never for text a user typed.
          sanitize: { type: "boolean", defaultValue: true },
          libUrl: { type: "string", defaultValue: LIB_URL },
          cssUrl: { type: "string", defaultValue: CSS_URL },
          purifyUrl: { type: "string", defaultValue: PURIFY_URL },
          // where the language file is loaded from - the file itself, for the
          // language the control ends up with
          langUrl: { type: "string", defaultValue: "" },
        },
        events: {
          // the editor lost focus holding a different value than it got it with
          change: { parameters: { value: { type: "string" } } },
        },
      },

      init() {
        this._editor = null; // the SunEditor instance, once created
        this._holder = null; // the element it lives in - kept across renders
        this._ready = false; // true from SunEditor's onload on
        this._signature = ""; // the options it was created with
        this._known = ""; // the HTML the editor and the model last agreed on
        this._focusValue = null; // the value when the editor got focus
        this._ticket = 0; // invalidates a creation still waiting for libraries
      },

      _host() {
        return document.getElementById(`${this.getId()}-host`);
      },

      // Everything the editor is created with except value and editable, which
      // are applied to the running editor. Changing any of it creates a new one.
      _optionsSignature() {
        return JSON.stringify([
          this.getHeight(),
          this.getPlaceholder(),
          this.getToolbar(),
          this._langCode(),
          this.getSanitize(),
          this.getLibUrl(),
          this.getCssUrl(),
          this.getLangUrl(),
        ]);
      },

      _langCode() {
        return langCode(this.getLanguage() || document.documentElement.getAttribute("lang"));
      },

      // The HTML as it may leave or enter the editor.
      _clean(html) {
        const value = html || "";
        if (!value || !this.getSanitize()) return value;
        // sanitizing was asked for and is not possible: nothing, rather than
        // the value unchecked
        return window.DOMPurify ? window.DOMPurify.sanitize(value) : "";
      },

      // What the editor holds, as the model would get it.
      _read() {
        if (!this._ready) return this._known;
        return this._editor.isEmpty() ? "" : this._clean(this._editor.$.html.get());
      },

      setValue(value) {
        const previous = this.getValue();
        // No re-render - a new value goes into the running editor, and
        // re-rendering would only move it out of the page and back.
        this.setProperty("value", value, true);
        if (this.getValue() !== previous) this._write(this.getValue());
        return this;
      },

      setEditable(editable) {
        this.setProperty("editable", editable, true);
        if (this._ready) this._editor.$.ui.readOnly(!this.getEditable());
        return this;
      },

      // A value from the model into the editor. Its onChange echo is recognised
      // by `_known` and not written back.
      _write(value) {
        if (!this._ready) return; // onload applies whatever value is current
        const html = this._clean(value);
        if (html === this._read()) {
          this._known = html;
          return;
        }
        this._editor.$.html.set(html);
        this._known = this._read();
      },

      // The editor's content into the model - on SunEditor's onChange, and
      // once more when it loses focus, because onChange waits for the typing
      // to pause and a click on a button elsewhere does not.
      _publish() {
        if (!this._ready) return;
        const html = this._read();
        if (html === this._known) return;
        this._known = html;
        this.setProperty("value", html, true);
      },

      _onLoad(signature) {
        if (Util.isDestroyed(this) || signature !== this._signature) return;
        this._ready = true;
        this._known = this._read();
        // the value may have moved while the editor was being built
        if (this._clean(this.getValue()) !== this._createdWith) this._write(this.getValue());
        if (!this.getEditable()) this._editor.$.ui.readOnly(true);
      },

      _onFocus() {
        this._focusValue = this.getValue();
      },

      _onBlur() {
        this._publish();
        const value = this.getValue();
        if (this._focusValue !== null && value !== this._focusValue) {
          this.fireChange({ value });
        }
        this._focusValue = null;
      },

      _load() {
        const libs = [
          Util.loadStyle(this.getCssUrl()),
          Util.loadScript(this.getLibUrl(), () => typeof window.SUNEDITOR !== "undefined"),
        ];
        if (this.getSanitize()) {
          libs.push(
            Util.loadScript(this.getPurifyUrl(), () => typeof window.DOMPurify !== "undefined"),
          );
        }
        const lang = this._langCode();
        const langUrl = this.getLangUrl() || (lang ? LibUrls[`sunEditorLang_${lang}`] : "");
        if (lang && langUrl) {
          libs.push(Util.loadScript(langUrl, () => Boolean(window.SUNEDITOR_LANG?.[lang])));
        }
        return Promise.all(libs);
      },

      _build(signature) {
        this._ticket += 1;
        const ticket = this._ticket;
        this._load()
          .then(() => {
            if (Util.isDestroyed(this) || ticket !== this._ticket) return;
            this._create(signature);
          })
          .catch((e) => {
            if (Util.isDestroyed(this) || ticket !== this._ticket) return;
            Util.logError("RichTextEditor: library not available", e);
            // The text is still worth showing when the editor is not - as
            // text, so nothing in it is interpreted.
            const host = this._host();
            if (host) host.textContent = this.getValue() || "";
          });
      },

      _create(signature) {
        const host = this._host();
        if (!host) return;

        // SunEditor builds its DOM inside this element, which the control
        // creates rather than renders: UI5 replaces what it rendered on every
        // re-render, and the editor would go with it (see onBeforeRendering).
        const holder = document.createElement("div");
        const target = document.createElement("div");
        holder.appendChild(target);
        host.appendChild(holder);
        this._holder = holder;
        this._signature = signature;
        this._createdWith = this._clean(this.getValue());

        const lang = this._langCode();
        const plugins = {};
        for (const name of PLUGINS) {
          if (window.SUNEDITOR.plugins?.[name]) plugins[name] = window.SUNEDITOR.plugins[name];
        }
        const buttons = toButtonList(this.getToolbar());

        try {
          this._editor = window.SUNEDITOR.create(target, {
            value: this._createdWith,
            plugins,
            buttonList: buttons.length ? buttons : DEFAULT_TOOLBAR,
            width: "100%",
            height: Util.toCssSize(this.getHeight()) || "auto",
            placeholder: this.getPlaceholder(),
            lang: lang ? window.SUNEDITOR_LANG?.[lang] : undefined,
            events: {
              onload: () => this._onLoad(signature),
              onChange: () => this._publish(),
              onFocus: () => this._onFocus(),
              onBlur: () => this._onBlur(),
            },
          });
        } catch (e) {
          Util.logError(`RichTextEditor (${this.getId()}): could not create the editor`, e);
          this._destroyEditor();
          host.textContent = this.getValue() || "";
        }
      },

      _destroyEditor() {
        // a creation still waiting for its libraries must not land afterwards
        this._ticket += 1;
        if (this._editor) {
          try {
            this._editor.destroy();
          } catch (e) {
            Util.logError("RichTextEditor: could not destroy the editor", e);
          }
        }
        this._editor = null;
        this._ready = false;
        if (this._holder) this._holder.remove();
        this._holder = null;
      },

      onBeforeRendering() {
        // Take the editor out of the page while UI5 renders: what UI5 renders
        // is replaced, and the editor - its text, its undo history - would go
        // with it. onAfterRendering puts it back.
        if (this._holder) this._holder.remove();
      },

      onAfterRendering() {
        injectStyle();
        const host = this._host();
        if (!host) return;

        const signature = this._optionsSignature();
        if (this._holder && signature === this._signature) {
          host.appendChild(this._holder);
          return;
        }
        this._destroyEditor();
        this._build(signature);
      },

      exit() {
        this._destroyEditor();
      },

      renderer: {
        apiVersion: 2,
        render(rm, control) {
          rm.openStart("div", control);
          rm.class("z2ui5_cciRichTextEditor");
          const width = Util.toCssSize(control.getWidth());
          if (width) rm.style("width", width);
          rm.openEnd();
          // the editor gets an element of its own, so what UI5 writes on the
          // control's node and what SunEditor builds never meet
          rm.openStart("div", `${control.getId()}-host`);
          rm.openEnd();
          rm.close("div");
          rm.close("div");
        },
      },
    });
  },
);
