"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - overview</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo</em>
"!
"! Front door of this control library: lists every custom control it ships and
"! launches its demo app. Use it to check an installation - if the list renders
"! and a demo runs, the Z2UI5CC BSP is deployed and the abap2UI5 frontend
"! resolves the reserved resourceRoot correctly.
CLASS zcl_z2ui5cc_demo DEFINITION
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


CLASS zcl_z2ui5cc_demo IMPLEMENTATION.

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
                )->a( n = `class`
                      v = `sapUiSmallMarginBeginEnd`

                )->open( `columns`
                    )->open( `Column`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `Control`
                    )->shut(
                    )->open( `Column`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `Module`
                    )->shut(
                    )->open( `Column`
                        )->leaf( `Text`
                            )->a( n = `text`
                                  v = `What it does`
                    )->shut(
                    )->open( `Column`
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

    DATA li_app TYPE REF TO z2ui5_if_app.
    TRY.
        CREATE OBJECT li_app TYPE (lv_class).
      CATCH cx_root.
        client->message_box_display( text = |Demo app { lv_class } not found.|
                                     type = `error` ).
        RETURN.
    ENDTRY.

    client->nav_app_call( li_app ).

  ENDMETHOD.

  METHOD model_init.

    t_controls = VALUE #(
      ( name        = `Counter`
        module      = `z2ui5cc/cc/Counter`
        description = `Click target that raises a counter and writes it back into the model`
        app         = `ZCL_Z2UI5CC_DEMO_COUNTER` )
      ( name        = `SignaturePad`
        module      = `z2ui5cc/cc/SignaturePad`
        description = `Canvas for mouse, finger or stylus; hands the stroke over as a base64 PNG`
        app         = `ZCL_Z2UI5CC_DEMO_SIGNATURE` )
      ( name        = `Favicon`
        module      = `z2ui5cc/cc/Favicon`
        description = `Sets the browser tab icon of the running app`
        app         = `ZCL_Z2UI5CC_DEMO_FAVICON` )
      ( name        = `ExportSpreadsheet`
        module      = `z2ui5cc/cc/ExportSpreadsheet`
        description = `Exports the rows a table is bound to as .xlsx, in the browser`
        app         = `ZCL_Z2UI5CC_DEMO_SPREADSHEET` )
      ( name        = `Messaging`
        module      = `z2ui5cc/cc/Messaging`
        description = `Two-way bridge between the UI5 message model and an ABAP table`
        app         = `ZCL_Z2UI5CC_DEMO_MESSAGING` )
      ( name        = `Validator`
        module      = `z2ui5cc/cc/Validator`
        description = `Checks a form against rules declared in ABAP, without a roundtrip`
        app         = `ZCL_Z2UI5CC_DEMO_VALIDATOR` )
      ( name        = `ChartJs`
        module      = `z2ui5cc/cc/ChartJs`
        description = `Chart.js canvas driven by a bound ABAP structure`
        app         = `ZCL_Z2UI5CC_DEMO_CHARTJS` )
      ( name        = `Barcode`
        module      = `z2ui5cc/cc/Barcode`
        description = `Barcodes and QR codes with bwip-js, rendered in the browser`
        app         = `ZCL_Z2UI5CC_DEMO_BARCODE` )
      ( name        = `DriverJs`
        module      = `z2ui5cc/cc/DriverJs`
        description = `Product tours and spotlight highlights over your own controls`
        app         = `ZCL_Z2UI5CC_DEMO_DRIVERJS` )
      ( name        = `FontAwesome`
        module      = `z2ui5cc/cc/FontAwesome`
        description = `Font Awesome as UI5 icons and as CSS classes`
        app         = `ZCL_Z2UI5CC_DEMO_FONT_AWESOME` )
      ( name        = `AnimateCss`
        module      = `z2ui5cc/cc/AnimateCss`
        description = `Makes the animate.css class names work on any control`
        app         = `ZCL_Z2UI5CC_DEMO_ANIMATE_CSS` )
      ( name        = `ImageMapster`
        module      = `z2ui5cc/cc/ImageMapster`
        description = `Image map that highlights, selects and reports the region clicked`
        app         = `ZCL_Z2UI5CC_DEMO_IMAGEMAPSTER` ) ).

  ENDMETHOD.

ENDCLASS.
