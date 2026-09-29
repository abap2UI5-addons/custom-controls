"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo BarcodeScanner</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_11</em>
"!
"! Scans every barcode in the camera picture at once. The panels at the
"! bottom are something to scan, drawn by the Barcode control of this library:
"! a test label with four codes on it, and a test pallet of six cartons that
"! carry two articles' labels. Open the demo on a second screen and point a
"! phone at it.
"!
"! <em>distinct</em> takes every code once - the four codes of the label.
"! <em>count</em> counts labels instead - the pallet comes back as two rows,
"! one per article, with the number of its cartons in <em>count</em>.
"!
"! With <em>expected</em> set, the scan completes by itself once that many
"! codes, or in <em>count</em> mode labels, were found; at 0 the user presses
"! OK. Either way the codes arrive in t_code, which is bound to the scanner
"! and to the table below it.
"!
"! The camera needs a secure (https) connection, and the reader needs
"! 'wasm-unsafe-eval' in the script-src of the Content-Security-Policy - the
"! README has the user exit line for it.
CLASS z2ui5_cl_cci_sample_11 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_code   TYPE z2ui5_cl_cci_barcode_scanner=>ty_t_code.
    DATA mode     TYPE string.
    DATA formats  TYPE string.
    DATA expected TYPE i.
    DATA info     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_11 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(page) = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = |xmlns:{ z2ui5_cl_cci=>c_ns }|
              v = z2ui5_cl_cci=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - BarcodeScanner`
            ).

    DATA(box) = page->ele( `VBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `mode - every code once, or every label counted`
       )->ele( `SegmentedButton`
           )->a( n = `selectedKey`
                 v = client->_bind( mode )
           )->a( n = `selectionChange`
                 v = client->_event( `MODE` )
           )->ele( `items`
               )->tag( `SegmentedButtonItem`
                   )->a( n = `key`
                         v = z2ui5_cl_cci_barcode_scanner=>cs_mode-distinct
                   )->a( n = `text`
                         v = `distinct - the test label`
               )->tag( `SegmentedButtonItem`
                   )->a( n = `key`
                         v = z2ui5_cl_cci_barcode_scanner=>cs_mode-count
                   )->a( n = `text`
                         v = `count - the test pallet` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `formats - empty reads every format`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `Input`
           )->a( n = `value`
                 v = client->_bind( formats )
           )->a( n = `placeholder`
                 v = `EAN13,Code128,QRCode,DataMatrix`
           )->a( n = `width`
                 v = `20rem`

       )->tag( `Label`
           )->a( n = `text`
                 v = `expected - the scan completes at this count, 0 waits for OK`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `StepInput`
           )->a( n = `value`
                 v = client->_bind( expected )
           )->a( n = `min`
                 v = `0`
           )->a( n = `max`
                 v = `20`
           )->a( n = `width`
                 v = `20rem` ).

    DATA(scan) = box->ele( `HBox`
                     )->a( n = `class`
                           v = `sapUiSmallMarginTop` ).

    z2ui5_cl_cci_barcode_scanner=>render(
        view     = scan
        codes    = client->_bind( t_code )
        mode     = client->_bind( mode )
        formats  = client->_bind( formats )
        expected = client->_bind( expected )
        text     = `Scan`
        type     = `Emphasized`
        scanned  = client->_event( `SCANNED` )
        error    = client->_event( val = `ERROR`
                                   arg = `${$parameters>/message}` ) ).

    box->tag( `Text`
           )->a( n = `text`
                 v = client->_bind( info )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    DATA(table) = box->ele( `Table`
                      )->a( n = `items`
                            v = client->_bind( t_code )
                      )->a( n = `noDataText`
                            v = `Nothing scanned yet`
                      )->a( n = `class`
                            v = `sapUiSmallMarginTop` ).

    DATA(columns) = table->ele( `columns` ).
    columns->ele( `Column`
        )->tag( `Text`
            )->a( n = `text`
                  v = `Code` ).
    columns->ele( `Column`
        )->tag( `Text`
            )->a( n = `text`
                  v = `Format` ).
    columns->ele( `Column`
        )->a( n = `hAlign`
              v = `End`
        )->tag( `Text`
            )->a( n = `text`
                  v = `Count` ).

    table->ele( `items`
        )->ele( `ColumnListItem`
            )->ele( `cells`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{TEXT}`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{FORMAT}`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{COUNT}` ).

    " Something to scan: a label with four codes of four formats - material,
    " batch, quantity and shipping unit - drawn in the browser by the Barcode
    " control of this library.
    DATA(label) = box->ele( `Panel`
                      )->a( n = `headerText`
                            v = `Test label - scan it from a second screen`
                      )->a( n = `class`
                            v = `sapUiMediumMarginTop`
                      )->ele( `content`
                          )->ele( `HBox`
                              )->a( n = `wrap`
                                    v = `Wrap`
                              )->a( n = `alignItems`
                                    v = `Center` ).

    TYPES:
      BEGIN OF ty_s_symbol,
        bcid    TYPE string,
        text    TYPE string,
        options TYPE string,
        height  TYPE string,
      END OF ty_s_symbol.
    TYPES ty_t_symbol TYPE STANDARD TABLE OF ty_s_symbol WITH EMPTY KEY.

    DATA(symbols) = VALUE ty_t_symbol(
      ( bcid = `ean13`      text = `4006381333931`           options = `includetext guardwhitespace` height = `10` )
      ( bcid = `code128`    text = `BATCH-0815`              options = `includetext`                 height = `10` )
      ( bcid = `qrcode`     text = `QTY:24`                  options = `eclevel=M` )
      ( bcid = `datamatrix` text = `SSCC 003456789012345678` ) ).

    LOOP AT symbols INTO DATA(symbol).
      z2ui5_cl_cci_barcode=>render(
          view    = label->ele( `VBox`
                        )->a( n = `class`
                              v = `sapUiMediumMargin` )
          bcid    = symbol-bcid
          text    = symbol-text
          options = symbol-options
          height  = symbol-height ).
    ENDLOOP.

    " Something to count: six cartons, four of one article and two of
    " another, each with its article's EAN-13. The caption and the large
    " margins are on purpose - the reader takes two equal 1D codes that are
    " closer than half their width one above the other for one symbol, and
    " cartons on a real pallet are much further apart than that.
    DATA(pallet) = box->ele( `Panel`
                       )->a( n = `headerText`
                             v = `Test pallet - six cartons of two articles, for the count mode`
                       )->a( n = `class`
                             v = `sapUiMediumMarginTop`
                       )->ele( `content`
                           )->ele( `HBox`
                               )->a( n = `wrap`
                                     v = `Wrap` ).

    DATA(cartons) = VALUE string_table( ( `4006381333931` ) ( `4006381333931` ) ( `4012345678901` )
                                        ( `4006381333931` ) ( `4006381333931` ) ( `4012345678901` ) ).

    LOOP AT cartons INTO DATA(carton).
      " before the builder runs - its own table operations overwrite sy-tabix
      DATA(number) = sy-tabix.
      DATA(box_carton) = pallet->ele( `VBox`
                               )->a( n = `class`
                                     v = `sapUiLargeMargin` ).
      box_carton->tag( `Text`
                )->a( n = `text`
                      t = |carton { number }| ).
      z2ui5_cl_cci_barcode=>render(
          view    = box_carton
          bcid    = `ean13`
          text    = carton
          scale   = `2`
          options = `includetext guardwhitespace`
          height  = `10` ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `MODE`.
        " each mode has its own thing to scan below, with its own count
        expected = COND #( WHEN mode = z2ui5_cl_cci_barcode_scanner=>cs_mode-count THEN 6 ELSE 4 ).
        info     = COND #( WHEN mode = z2ui5_cl_cci_barcode_scanner=>cs_mode-count
                           THEN `Press Scan and get the whole test pallet into the picture.`
                           ELSE `Press Scan and point the camera at the test label.` ).

      WHEN `SCANNED`.
        " t_code already holds the codes here - bound data is written back
        " into the attribute before the event handler runs
        IF mode = z2ui5_cl_cci_barcode_scanner=>cs_mode-count.
          DATA(labels) = REDUCE i( INIT n = 0
                                   FOR row IN t_code
                                   NEXT n = n + row-count ).
          info = |{ labels } label(s) of { lines( t_code ) } code(s) counted.|.
        ELSE.
          info = |{ lines( t_code ) } code(s) scanned.|.
        ENDIF.

      WHEN `ERROR`.
        info = client->get_event_arg( ).
        client->message_box_display( text = info
                                     type = `error` ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    " the test label at the bottom carries four codes
    mode     = z2ui5_cl_cci_barcode_scanner=>cs_mode-distinct.
    expected = 4.
    info     = `Press Scan and point the camera at the test label.`.

  ENDMETHOD.

ENDCLASS.
