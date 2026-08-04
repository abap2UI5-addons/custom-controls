"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - overview</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_ccont_sample_00</em>
"!
"! Front door of this control library: lists every custom control it ships and
"! launches its demo app. Use it to check an installation - if the list renders
"! and a demo runs, the Z2UI5CC BSP is deployed and the abap2UI5 frontend
"! resolves the reserved resourceRoot correctly.
CLASS z2ui5_cl_ccont_sample_00 DEFINITION
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
        app         TYPE string,
      END OF ty_s_control.

    DATA t_controls TYPE STANDARD TABLE OF ty_s_control WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS on_launch.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccont_sample_00 IMPLEMENTATION.

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

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).

    view->open( n  = `View`
                ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 custom controls`

            )->open( `MessageStrip`
                )->a( n = `text`
                      v = `These controls are delivered by the Z2UI5CC BSP, ` &&
                          `not by abap2UI5 or its frontend.`
                )->a( n = `type`
                      v = `Information`
                )->a( n = `showIcon`
                      v = `true`
                )->a( n = `class`
                      v = `sapUiSmallMargin`
            )->shut(

            )->open( `Table`
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
                " column as much room as its content wants, and three long text
                " columns push the Demo button clean off the right edge. Only
                " the description is left flexible, so it absorbs the slack and
                " the button column always stays on screen.
                "
                " demandPopin moves a column under the row instead of squeezing
                " it once the screen is too narrow - on a phone the list keeps
                " the control name and the button, and folds the rest away.
                )->open( `columns`
                    )->open( `Column`
                        )->a( n = `width`
                              v = `11rem`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `Control`
                    )->shut(
                    )->open( `Column`
                        )->a( n = `width`
                              v = `18rem`
                        )->a( n = `minScreenWidth`
                              v = `Tablet`
                        )->a( n = `demandPopin`
                              v = `true`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `Module`
                    )->shut(
                    )->open( `Column`
                        )->a( n = `minScreenWidth`
                              v = `Desktop`
                        )->a( n = `demandPopin`
                              v = `true`
                        )->a( n = `popinDisplay`
                              v = `Inline`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `What it does`
                    )->shut(
                    )->open( `Column`
                        )->a( n = `width`
                              v = `7rem`
                        )->a( n = `hAlign`
                              v = `End`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `Demo`
                    )->shut(
                )->shut(

                )->open( `items`
                    )->open( `ColumnListItem`
                        )->open( `cells`
                            )->leaf( `Text`
                                )->a( n = `text`
                                      v = `{NAME}`
                            )->leaf( `Text`
                                )->a( n = `text`
                                      v = `{MODULE}`
                            )->leaf( `Text`
                                )->a( n = `text`
                                      v = `{DESCRIPTION}`
                            )->leaf( `Button`
                                )->a( n = `text`
                                      v = `Open`
                                )->a( n = `icon`
                                      v = `sap-icon://play`
                                )->a( n = `press`
                                      v = client->_event(
                                              val   = `LAUNCH`
                                              t_arg = VALUE #( ( `${APP}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.
      WHEN `LAUNCH`.
        on_launch( ).
    ENDCASE.

  ENDMETHOD.

  METHOD on_launch.

    " the demo class name is resolved on the client from the pressed row
    DATA(lv_class) = to_upper( client->get_event_arg( 1 ) ).
    IF lv_class IS INITIAL.
      RETURN.
    ENDIF.

    " instantiated only to fail early with a readable message - the tab below
    " would otherwise open on a dump
    DATA li_app TYPE REF TO z2ui5_if_app ##NEEDED.
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
    client->follow_up_action( val   = client->cs_event-open_new_tab
                              t_arg = VALUE #( ( |?app_start={ lv_class }| ) ) ).

  ENDMETHOD.

  METHOD model_init.

    t_controls = VALUE #(
      ( name        = `SignaturePad`
        module      = `z2ui5cc/cc/SignaturePad`
        description = `Canvas for mouse, finger or stylus; hands the stroke over as a base64 PNG`
        app         = `Z2UI5_CL_CCONT_SAMPLE_01` )
      ( name        = `ExportSpreadsheet`
        module      = `z2ui5cc/cc/ExportSpreadsheet`
        description = `Exports the rows a table is bound to as .xlsx, in the browser`
        app         = `Z2UI5_CL_CCONT_SAMPLE_02` )
      ( name        = `Validator`
        module      = `z2ui5cc/cc/Validator`
        description = `Checks a form against rules declared in ABAP, without a roundtrip`
        app         = `Z2UI5_CL_CCONT_SAMPLE_03` )
      ( name        = `ChartJs`
        module      = `z2ui5cc/cc/ChartJs`
        description = `Chart.js canvas driven by a bound ABAP structure`
        app         = `Z2UI5_CL_CCONT_SAMPLE_04` )
      ( name        = `Barcode`
        module      = `z2ui5cc/cc/Barcode`
        description = `Barcodes and QR codes with bwip-js, rendered in the browser`
        app         = `Z2UI5_CL_CCONT_SAMPLE_05` )
      ( name        = `DriverJs`
        module      = `z2ui5cc/cc/DriverJs`
        description = `Product tours and spotlight highlights over your own controls`
        app         = `Z2UI5_CL_CCONT_SAMPLE_06` )
      ( name        = `FontAwesome`
        module      = `z2ui5cc/cc/FontAwesome`
        description = `Font Awesome as UI5 icons and as CSS classes`
        app         = `Z2UI5_CL_CCONT_SAMPLE_07` )
      ( name        = `AnimateCss`
        module      = `z2ui5cc/cc/AnimateCss`
        description = `Makes the animate.css class names work on any control`
        app         = `Z2UI5_CL_CCONT_SAMPLE_08` )
      ( name        = `ImageMapster`
        module      = `z2ui5cc/cc/ImageMapster`
        description = `Image map that highlights, selects and reports the region clicked`
        app         = `Z2UI5_CL_CCONT_SAMPLE_09` ) ).

  ENDMETHOD.

ENDCLASS.
