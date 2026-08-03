// z2ui5cc.cc.ExportSpreadsheet - a button that exports the rows a table is
// bound to as an .xlsx file, through sap.ui.export.Spreadsheet.
//
// The export runs entirely in the browser and reads the table's binding, so
// the data never makes a second trip to the backend. `columns` describes the
// workbook: one entry per column, in export order, independent of what the
// table happens to show.
//
// Ported from abap2UI5-addons/custom-controls (z2ui5_cl_cc_spreadsheet). Three
// changes of substance:
//
//   1. the old control resolved the table through the frontend globals
//      z2ui5.oView / oViewNest / oViewNest2 / oViewPopup / oViewPopover, tried
//      in turn. Those are frontend internals, so a control from its own BSP
//      must not touch them. This one walks up to the view it was rendered in -
//      which is the right scope for the id in every one of those cases.
//   2. the button was constructed inside the renderer, so every re-render
//      leaked a fresh sap.m.Button. It is now a hidden aggregation, created
//      once in init().
//   3. sap/ui/export/Spreadsheet is loaded lazily on the first press instead
//      of eagerly - it is absent on OpenUI5, where the button now stays
//      disabled with a tooltip saying so.
sap.ui.define(
  ["sap/ui/core/Control", "sap/m/Button", "z2ui5cc/cc/Util"],
  (Control, Button, Util) => {
    "use strict";

    // sap.ui.export ships with SAPUI5 only; OpenUI5 has no xlsx writer.
    const hasExportLib = () => {
      try {
        return String(sap.ui.getVersionInfo().gav || "").includes("com.sap.ui5");
      } catch (e) {
        // getVersionInfo throws when version info was not loaded - assume the
        // library is there and let the require below produce the real error.
        return true;
      }
    };

    return Control.extend("z2ui5cc.cc.ExportSpreadsheet", {
      metadata: {
        properties: {
          // id of the table to export, as the abap2UI5 app wrote it in the view
          tableId: { type: "string", defaultValue: "" },
          // workbook columns: [{ label, property, type, ... }] - the settings
          // sap.ui.export.Spreadsheet accepts per column
          columns: { type: "object[]", defaultValue: [] },
          fileName: { type: "string", defaultValue: "export.xlsx" },
          sheetName: { type: "string", defaultValue: "" },
          text: { type: "string", defaultValue: "" },
          icon: { type: "string", defaultValue: "sap-icon://excel-attachment" },
          type: { type: "string", defaultValue: "Default" },
          tooltip: { type: "string", defaultValue: "" },
          enabled: { type: "boolean", defaultValue: true },
          // Outcome of the last press: `success`, or `error: <reason>`.
          // Bind it two-way and ABAP learns how the export went - an event
          // parameter would not reach the backend, a bound property does.
          status: { type: "string", defaultValue: "" },
        },
        aggregations: {
          _button: {
            type: "sap.m.Button",
            multiple: false,
            visibility: "hidden",
          },
        },
        events: {
          // fired once the file was handed to the browser, or with an error
          // message when the export failed
          exported: {
            parameters: {
              success: { type: "boolean" },
              message: { type: "string" },
            },
          },
        },
      },

      init() {
        this.setAggregation(
          "_button",
          new Button({ press: this.export.bind(this) }),
        );
      },

      _syncButton() {
        const button = this.getAggregation("_button");
        if (!button) return;
        const available = hasExportLib();
        button.setText(this.getText());
        button.setIcon(this.getIcon());
        button.setType(this.getType());
        button.setEnabled(this.getEnabled() && available);
        button.setTooltip(
          available
            ? this.getTooltip()
            : "Spreadsheet export is not available on OpenUI5",
        );
      },

      // The binding that actually holds the rows. sap.m.Table calls the
      // aggregation `items`, sap.ui.table.Table calls it `rows`.
      _binding(table) {
        return table.getBinding("items") || table.getBinding("rows") || null;
      },

      // Publishes the outcome. Suppress invalidation: a re-render would only
      // rebuild the identical button, and the model write-back that carries
      // the status to ABAP happens either way.
      _report(success, message) {
        this.setProperty("status", success ? "success" : `error: ${message}`, true);
        this.fireExported({ success, message });
      },

      _fail(message) {
        Util.logError(`ExportSpreadsheet: ${message}`);
        this._report(false, message);
      },

      export() {
        const table = Util.resolveControl(this, this.getTableId());
        if (!table) {
          this._fail(`no control found for tableId '${this.getTableId()}'`);
          return;
        }

        const binding = this._binding(table);
        if (!binding) {
          this._fail(
            `control '${this.getTableId()}' has no items/rows binding to export`,
          );
          return;
        }

        const columns = this.getColumns() || [];
        if (columns.length === 0) {
          this._fail("no columns configured - nothing to export");
          return;
        }

        const workbook = { columns };
        // sheetName is part of the workbook context, not a top level setting
        if (this.getSheetName()) {
          workbook.context = { sheetName: this.getSheetName() };
        }
        const settings = {
          workbook,
          dataSource: binding,
          fileName: this.getFileName(),
        };

        sap.ui.require(
          ["sap/ui/export/Spreadsheet"],
          (Spreadsheet) => {
            if (Util.isDestroyed(this)) return;
            let sheet;
            try {
              sheet = new Spreadsheet(settings);
            } catch (e) {
              this._fail(`could not build the workbook: ${e.message}`);
              return;
            }
            sheet
              .build()
              .then(() => this._report(true, ""))
              .catch((e) => this._fail(`export failed: ${e && e.message}`))
              .finally(() => sheet.destroy());
          },
          () => this._fail("sap/ui/export/Spreadsheet could not be loaded"),
        );
      },

      // Not in the renderer: setting a property on the button invalidates it,
      // and invalidating a control while rendering it schedules another pass.
      // onBeforeRendering is the hook that allows exactly this.
      onBeforeRendering() {
        this._syncButton();
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
