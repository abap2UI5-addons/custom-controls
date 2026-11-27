"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - spreadsheet export</p>
"!
"! The ABAP half of the z2ui5_cci.cc.ExportSpreadsheet custom control: the view
"! builder that emits its XML element, plus the column configuration type the
"! workbook is described with.
"!
"! Put the control into a table's toolbar, tell it the table's id, and pressing
"! it writes the rows the table is bound to into an .xlsx file. The export runs
"! in the browser and reads the table's binding, so no extra roundtrip is
"! needed and the file never has to be built in ABAP.
"!
"! Requires SAPUI5 - sap.ui.export ships there, not with OpenUI5. On OpenUI5
"! the button renders disabled and says so in its tooltip.
"!
"! Ported from abap2UI5-addons/custom-controls (z2ui5_cl_cc_spreadsheet).
CLASS z2ui5_cl_cci_spreadsheet DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! A column setting whose sap.ui.export default is TRUE: `false`, `true`
    "! (abap_true works as well) or empty for the default. Not abap_bool,
    "! because omit_initial drops an abap_false - the initial value - and the
    "! exporter would fall back to true. Use cs_flag.
    TYPES ty_flag TYPE string.

    CONSTANTS:
      BEGIN OF cs_flag,
        true  TYPE ty_flag VALUE `true`,
        false TYPE ty_flag VALUE `false`,
      END OF cs_flag.

    TYPES:
      "! One workbook column. `property` is the name of the field in the bound
      "! ABAP table, in upper case - that is how abap2UI5 puts it into the model.
      "! Everything else is optional; leave it initial and the exporter's default
      "! applies (bind with omit_initial, see columns below).
      BEGIN OF ty_s_column,
        label             TYPE string,
        property          TYPE string,
        "! String, Number, Currency, Date, DateTime, Time, Boolean, Enumeration
        type              TYPE string,
        width             TYPE i,
        text_align        TYPE string,
        "! decimal places, a number as text: empty keeps the exporter's
        "! default, `0` shows none
        scale             TYPE string,
        delimiter         TYPE abap_bool,
        unit              TYPE string,
        unit_property     TYPE string,
        display_unit      TYPE ty_flag,
        true_value        TYPE string,
        false_value       TYPE string,
        template          TYPE string,
        input_format      TYPE string,
        wrap              TYPE abap_bool,
        auto_scale        TYPE ty_flag,
        timezone          TYPE string,
        timezone_property TYPE string,
        display_timezone  TYPE ty_flag,
        utc               TYPE ty_flag,
      END OF ty_s_column.
    TYPES ty_t_column TYPE STANDARD TABLE OF ty_s_column WITH EMPTY KEY.

    "! Emit &lt;z2ui5_cci:ExportSpreadsheet/&gt; into an existing view.
    "!
    "! Bind `columns` with omit_initial, or the exporter sees a wall of
    "! initial values:
    "!
    "!   columns = client->_bind( val          = mt_columns
    "!                            omit_initial = abap_true )
    "!
    "! The control turns the ABAP field names into the camelCase names the
    "! exporter reads (unit_property -&gt; unitProperty), so no mapper is needed -
    "! the camelCase mapper of older apps still works. display_unit, auto_scale,
    "! display_timezone and utc are ty_flag: cs_flag-false switches them off.
    "!
    "! @parameter view      | the builder positioned at the parent element
    "! @parameter tableid   | id of the table to export, as written in the view
    "! @parameter columns   | bind of a ty_t_column table, see above
    "! @parameter filename  | name the browser saves the file under
    "! @parameter sheetname | name of the worksheet inside the workbook
    "! @parameter text      | button text
    "! @parameter icon      | button icon
    "! @parameter type      | button type, e.g. Emphasized
    "! @parameter tooltip   | button tooltip
    "! @parameter enabled   | `true` / `false` - never abap_true (X) or abap_false (dropped: the default stays) - pass z2ui5_cl_cci=>bool( flag )
    "! @parameter status    | bind two-way to receive `success` / `error: ...`
    "! @parameter exported  | client->_event( ... ) fired after every export
    "! @parameter result    | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        tableid       TYPE string
        columns       TYPE string
        filename      TYPE string OPTIONAL
        sheetname     TYPE string OPTIONAL
        text          TYPE string OPTIONAL
        icon          TYPE string OPTIONAL
        type          TYPE string OPTIONAL
        tooltip       TYPE string OPTIONAL
        enabled       TYPE string OPTIONAL
        status        TYPE string OPTIONAL
        exported      TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_spreadsheet IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `ExportSpreadsheet`
        a    = VALUE #( ( |tableId={ tableid }| )
                        ( |columns={ columns }| )
                        ( |fileName={ filename }| )
                        ( |sheetName={ sheetname }| )
                        ( |text={ text }| )
                        ( |icon={ icon }| )
                        ( |type={ type }| )
                        ( |tooltip={ tooltip }| )
                        ( |enabled={ enabled }| )
                        ( |status={ status }| )
                        ( |exported={ exported }| ) ) ).

  ENDMETHOD.

ENDCLASS.
