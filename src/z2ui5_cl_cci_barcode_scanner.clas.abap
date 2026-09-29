"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - BarcodeScanner</p>
"!
"! The ABAP half of the z2ui5_cci.cc.BarcodeScanner custom control: the view
"! builder that emits its XML element, and the table type its result arrives in.
"!
"! The control reads EVERY barcode in the camera picture at once - a label
"! carrying material, batch and quantity as three codes is taken in one scan -
"! and writes the distinct codes into the bound ty_t_code table. In the mode
"! cs_mode-count it counts labels instead: twelve cartons of one article with
"! the same EAN on each come back as one row with count 12. Decoding happens
"! in the browser with zxing-wasm, ZXing-C++ compiled to WebAssembly; no
"! picture is transferred.
"!
"! Two things the page has to allow, see the README: the camera needs a secure
"! (https) connection, and WebAssembly needs 'wasm-unsafe-eval' in the
"! script-src of the Content-Security-Policy.
CLASS z2ui5_cl_cci_barcode_scanner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      "! One scanned code. The control writes the components as upper-case
      "! keys - the default abap2UI5 name mapping - so bind the table without
      "! a custom mapper.
      BEGIN OF ty_s_code,
        "! the decoded content
        text   TYPE string,
        "! zxing-wasm format name, e.g. EAN13, Code128, QRCode, DataMatrix
        format TYPE string,
        "! the labels carrying the code - the most copies of it that were in
        "! the picture at once; always 1 unless the mode is cs_mode-count
        count  TYPE i,
      END OF ty_s_code.
    TYPES ty_t_code TYPE STANDARD TABLE OF ty_s_code WITH EMPTY KEY.

    CONSTANTS:
      "! What a scan collects, for the `mode` parameter of render( ).
      BEGIN OF cs_mode,
        "! every code once, however many labels carry it - the codes of one
        "! label, or cartons whose labels differ (the default)
        distinct TYPE string VALUE `distinct`,
        "! every code as often as it is in the picture at once - identical
        "! labels on a stack of cartons. All of them have to fit into one
        "! picture: a count is never added up over several
        count    TYPE string VALUE `count`,
      END OF cs_mode.

    "! Emit &lt;z2ui5_cci:BarcodeScanner/&gt; into an existing view - a button
    "! that opens the camera.
    "!
    "! @parameter view       | the builder positioned at the parent element
    "! @parameter codes      | client->_bind( ) of a ty_t_code table; receives
    "!                         the codes of every completed scan
    "! @parameter mode       | a cs_mode value; empty is cs_mode-distinct
    "! @parameter formats    | zxing-wasm format names, comma separated, e.g.
    "!                         `EAN13,Code128,DataMatrix`, or a group such as
    "!                         `AllLinear`; empty reads every format
    "! @parameter expected   | number of codes that completes the scan without
    "!                         OK being pressed - in cs_mode-count the number
    "!                         of labels; empty: the user confirms
    "! @parameter text       | button text
    "! @parameter icon       | button icon, sap-icon://bar-code by default
    "! @parameter type       | button type, e.g. `Emphasized`
    "! @parameter enabled    | `true` / `false` - never abap_true, it serializes as X
    "! @parameter title      | dialog title
    "! @parameter facingmode | `environment` (the back camera, the default) or `user`
    "! @parameter deviceid   | one specific camera, by the id the browser reports
    "! @parameter liburl     | overrides where the zxing-wasm reader is loaded from
    "! @parameter wasmurl    | overrides where its WebAssembly module is loaded
    "!                         from - a `.wasm` URL, or a script embedding it
    "! @parameter scanned    | client->_event( ... ) fired when a scan completed;
    "!                         the event parameter `count` is the number of
    "!                         labels, the counts of all rows added up
    "! @parameter error      | client->_event( ... ) fired when the camera or the
    "!                         reader could not be started; the reason is the
    "!                         event parameter `message`
    "! @parameter result     | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        codes         TYPE string
        mode          TYPE string OPTIONAL
        formats       TYPE string OPTIONAL
        expected      TYPE string OPTIONAL
        text          TYPE string OPTIONAL
        icon          TYPE string OPTIONAL
        type          TYPE string OPTIONAL
        enabled       TYPE string OPTIONAL
        title         TYPE string OPTIONAL
        facingmode    TYPE string OPTIONAL
        deviceid      TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        wasmurl       TYPE string OPTIONAL
        scanned       TYPE string OPTIONAL
        error         TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_barcode_scanner IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `BarcodeScanner`
        a    = VALUE #( ( |codes={ codes }| )
                        ( |mode={ mode }| )
                        ( |formats={ formats }| )
                        ( |expected={ expected }| )
                        ( |text={ text }| )
                        ( |icon={ icon }| )
                        ( |type={ type }| )
                        ( |enabled={ enabled }| )
                        ( |title={ title }| )
                        ( |facingMode={ facingmode }| )
                        ( |deviceId={ deviceid }| )
                        ( |libUrl={ liburl }| )
                        ( |wasmUrl={ wasmurl }| )
                        ( |scanned={ scanned }| )
                        ( |error={ error }| ) ) ).

  ENDMETHOD.

ENDCLASS.
