"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - overview</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_00</em>
"!
"! Front door of this control library: one row per demo app, with the
"! third-party library each control needs, and a button that launches it. Use
"! it to check an installation - if the list renders and a demo runs, the
"! Z2UI5_CCI BSP is deployed and the abap2UI5 frontend resolves the reserved
"! resourceRoot correctly.
"!
"! One row per DEMO, not per control: CodeEditor has no demo of its own, it is
"! the editor inside the Markdown one, so it has no row here either.
CLASS z2ui5_cl_cci_sample_00 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_control,
        name        TYPE string,
        module      TYPE string,
        description TYPE string,
        library     TYPE string,
        app         TYPE string,
      END OF ty_s_control.

    DATA t_controls TYPE STANDARD TABLE OF ty_s_control WITH DEFAULT KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS on_launch.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_00 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).

    view->ele( n  = `View`
               ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 custom controls`

            )->ele( `MessageStrip`
                )->a( n = `text`
                      v = `These controls are delivered by the Z2UI5_CCI BSP, ` &&
                          `not by abap2UI5 or its frontend.`
                )->a( n = `type`
                      v = `Information`
                )->a( n = `showIcon`
                      v = `true`
                )->a( n = `class`
                      v = `sapUiSmallMargin`
            )->end(

            )->ele( `Table`
                )->a( n = `items`
                      v = client->_bind( t_controls )
                " width=auto belongs WITH the margin class: a sap.m.Table is
                " 100% wide by default, so adding a left and right margin makes
                " it 100% + 2rem and the last column hangs off the right edge.
                " `auto` lets the margins come out of the width instead.
                )->a( n = `width`
                      v = `auto`
                )->a( n = `class`
                      v = `sapUiResponsiveMargin`

                " Widths matter here: without them sap.m.Table hands every
                " column as much room as its content wants, and four long text
                " columns push the Demo button clean off the right edge. Only
                " the description is left flexible, so it absorbs the slack and
                " the button column always stays on screen. The fixed ones add
                " up to 49rem, which still leaves the description room on a
                " laptop - anything narrower folds columns away below.
                "
                " demandPopin moves a column under the row instead of squeezing
                " it once the screen is too narrow - on a phone the list keeps
                " the control name and the button, and folds the rest away.
                )->ele( `columns`
                    )->ele( `Column`
                        )->a( n = `width`
                              v = `11rem`
                        )->tag( `Text`
                            )->a( n = `text`
                                  v = `Control`
                    )->end(
                    )->ele( `Column`
                        )->a( n = `width`
                              v = `18rem`
                        )->a( n = `minScreenWidth`
                              v = `Tablet`
                        )->a( n = `demandPopin`
                              v = `true`
                        )->tag( `Text`
                            )->a( n = `text`
                                  v = `Module`
                    )->end(
                    )->ele( `Column`
                        )->a( n = `minScreenWidth`
                              v = `Desktop`
                        )->a( n = `demandPopin`
                              v = `true`
                        )->a( n = `popinDisplay`
                              v = `Inline`
                        )->tag( `Text`
                            )->a( n = `text`
                                  v = `What it does`
                    )->end(
                    " Which third-party library the control pulls in, because
                    " that is what decides whether it runs on a machine with no
                    " internet access. Controls that need none say so - that is
                    " information, not an empty cell.
                    )->ele( `Column`
                        )->a( n = `width`
                              v = `13rem`
                        )->a( n = `minScreenWidth`
                              v = `Tablet`
                        )->a( n = `demandPopin`
                              v = `true`
                        )->tag( `Text`
                            )->a( n = `text`
                                  v = `Library`
                    )->end(
                    )->ele( `Column`
                        )->a( n = `width`
                              v = `7rem`
                        )->a( n = `hAlign`
                              v = `End`
                        )->tag( `Text`
                            )->a( n = `text`
                                  v = `Demo`
                    )->end(
                )->end(

                )->ele( `items`
                    )->ele( `ColumnListItem`
                        )->ele( `cells`
                            )->tag( `Text`
                                )->a( n = `text`
                                      v = `{NAME}`
                            )->tag( `Text`
                                )->a( n = `text`
                                      v = `{MODULE}`
                            )->tag( `Text`
                                )->a( n = `text`
                                      v = `{DESCRIPTION}`
                            )->tag( `Text`
                                )->a( n = `text`
                                      v = `{LIBRARY}`
                            )->tag( `Button`
                                )->a( n = `text`
                                      v = `Open`
                                )->a( n = `icon`
                                      v = `sap-icon://play`
                                )->a( n = `press`
                                      v = client->_event(
                                              val = `LAUNCH`
                                              arg = `${APP}` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get( )-event = `LAUNCH`.
      on_launch( ).
    ENDIF.

  ENDMETHOD.

  METHOD on_launch.

    " the demo class name is resolved on the client from the pressed row
    DATA lv_class TYPE string.
    DATA li_app TYPE REF TO z2ui5_if_app .
    DATA temp1 TYPE string_table.
    DATA temp2 LIKE LINE OF temp1.
    lv_class = to_upper( client->get_event_arg( ) ).
    IF lv_class IS INITIAL.
      RETURN.
    ENDIF.

    " instantiated only to fail early with a readable message - the tab below
    " would otherwise open on a dump

    TRY.
        CREATE OBJECT li_app TYPE (lv_class).
      CATCH cx_root.
        client->message_box_display( text = |Demo app { lv_class } not found.|
                                     type = `error` ).
        RETURN.
    ENDTRY.

    " Open in a new tab rather than navigating: the overview stays put, so
    " trying the next control does not mean walking back first. The URL is
    " relative on purpose - open_new_tab refuses anything that does not
    " resolve to the same origin.

    CLEAR temp1.

    temp2 = |?app_start={ lv_class }|.
    INSERT temp2 INTO TABLE temp1.
    client->follow_up_action( val   = client->cs_event-open_new_tab
                              t_arg = temp1 ).

  ENDMETHOD.

  METHOD model_init.

    " `library` names the third-party code the control loads, because that is
    " what decides whether it works on a machine with no internet access:
    "
    "   none        nothing is fetched - the control is self-contained
    "   from UI5    shipped with the UI5 distribution, so wherever UI5 comes
    "               from, this comes with it
    "   a name      a library loaded on first use, from jsDelivr on `main` and
    "               from this BSP on the `local` branch
    "
    " Deliberately without version numbers: those are pinned in package.json
    " and would rot here on the next bump, with nothing to catch it.
    "
    " CodeEditor has no row of its own - it has no demo of its own either. It
    " is the editor on the left of the Markdown demo, which is where it is
    " shown; a second row launching the very same app was noise.
    DATA temp3 LIKE t_controls.
    DATA temp4 LIKE LINE OF temp3.
    CLEAR temp3.

    temp4-name = `SignaturePad`.
    temp4-module = `z2ui5_cci/cc/SignaturePad`.
    temp4-description = `Canvas for mouse, finger or stylus; hands the stroke over as a base64 PNG`.
    temp4-library = `none`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_01`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `ExportSpreadsheet`.
    temp4-module = `z2ui5_cci/cc/ExportSpreadsheet`.
    temp4-description = `Exports the rows a table is bound to as .xlsx, in the browser`.
    temp4-library = `sap.ui.export, from UI5`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_02`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `Validator`.
    temp4-module = `z2ui5_cci/cc/Validator`.
    temp4-description = `Checks a form against rules declared in ABAP, without a roundtrip`.
    temp4-library = `none`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_03`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `ChartJs`.
    temp4-module = `z2ui5_cci/cc/ChartJs`.
    temp4-description = `Chart.js canvas driven by a bound ABAP structure`.
    temp4-library = `Chart.js`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_04`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `Barcode`.
    temp4-module = `z2ui5_cci/cc/Barcode`.
    temp4-description = `Barcodes and QR codes with bwip-js, rendered in the browser`.
    temp4-library = `bwip-js`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_05`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `DriverJs`.
    temp4-module = `z2ui5_cci/cc/DriverJs`.
    temp4-description = `Product tours and spotlight highlights over your own controls`.
    temp4-library = `driver.js`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_06`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `FontAwesome`.
    temp4-module = `z2ui5_cci/cc/FontAwesome`.
    temp4-description = `Font Awesome as UI5 icons and as CSS classes`.
    temp4-library = `Font Awesome`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_07`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `AnimateCss`.
    temp4-module = `z2ui5_cci/cc/AnimateCss`.
    temp4-description = `Makes the animate.css class names work on any control`.
    temp4-library = `animate.css`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_08`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `ImageMapster`.
    temp4-module = `z2ui5_cci/cc/ImageMapster`.
    temp4-description = `Image map that highlights, selects and reports the region clicked`.
    temp4-library = `none`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_09`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `Markdown`.
    temp4-module = `z2ui5_cci/cc/Markdown`.
    temp4-description = `Renders a bound Markdown string as HTML, sanitized by default`.
    temp4-library = `marked, DOMPurify`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_10`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `BarcodeScanner`.
    temp4-module = `z2ui5_cci/cc/BarcodeScanner`.
    temp4-description = `Scans every barcode in the camera picture at once, into an ABAP table`.
    temp4-library = `zxing-wasm`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_11`.
    INSERT temp4 INTO TABLE temp3.
    temp4-name = `RichTextEditor`.
    temp4-module = `z2ui5_cci/cc/RichTextEditor`.
    temp4-description = `WYSIWYG editor for HTML, bound two-way - on OpenUI5 as on SAPUI5`.
    temp4-library = `SunEditor, DOMPurify`.
    temp4-app = `Z2UI5_CL_CCI_SAMPLE_12`.
    INSERT temp4 INTO TABLE temp3.
    t_controls = temp3.

  ENDMETHOD.

ENDCLASS.
