"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Barcode</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_barcode</em>
"!
"! Pick a symbology, type a value, and the barcode is drawn in the browser -
"! no image is built in ABAP and none is transferred. Every field is bound, so
"! changing one and pressing Render redraws it.
"!
"! Entering something the symbology cannot encode (letters into an EAN-13, for
"! instance) is worth trying: the control renders the reason in place and
"! reports it back here through the <em>error</em> event.
CLASS zcl_z2ui5cc_demo_barcode DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_type   TYPE zcl_z2ui5cc_barcode=>ty_t_type.
    DATA bcid     TYPE string.
    DATA text     TYPE string.
    DATA options  TYPE string.
    DATA scale    TYPE string.
    DATA height   TYPE string.
    DATA renderas TYPE string.
    DATA info     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS type_apply.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_barcode IMPLEMENTATION.

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

    DATA(page) = view->open( n  = `View`
                             ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        " sap.ui.core.Item - the ComboBox' items live in that namespace
        )->a( n = `xmlns:core`
              v = `sap.ui.core`
        )->a( n = |xmlns:{ zcl_z2ui5cc=>c_ns }|
              v = zcl_z2ui5cc=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Barcode`
            ).

    DATA(box) = page->open( `VBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin` ).

    box->leaf( `Label`
           )->a( n = `text`
                 v = `symbology`
       )->open( `ComboBox`
           )->a( n = `selectedKey`
                 v = client->_bind( bcid )
           )->a( n = `items`
                 v = client->_bind( t_type )
           )->a( n = `width`
                 v = `20rem`
           )->a( n = `change`
                 v = client->_event( `TYPE` )
           )->open( `items`
               )->leaf( n  = `Item`
                        ns = `core`
                   )->a( n = `key`
                         v = `{BCID}`
                   )->a( n = `text`
                         v = `{TEXT}` ).

    box->leaf( `Label`
           )->a( n = `text`
                 v = `value`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->leaf( `Input`
           )->a( n = `value`
                 v = client->_bind( text )
           )->a( n = `width`
                 v = `20rem`

       )->leaf( `Label`
           )->a( n = `text`
                 v = `BWIPP options`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->leaf( `Input`
           )->a( n = `value`
                 v = client->_bind( options )
           )->a( n = `width`
                 v = `20rem`

       )->leaf( `Label`
           )->a( n = `text`
                 v = `scale / height`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    box->open( `HBox`
        )->leaf( `StepInput`
            )->a( n = `value`
                  v = client->_bind( scale )
            )->a( n = `min`
                  v = `1`
            )->a( n = `max`
                  v = `9`
        )->leaf( `StepInput`
            )->a( n = `value`
                  v = client->_bind( height )
            )->a( n = `min`
                  v = `5`
            )->a( n = `max`
                  v = `40`
            )->a( n = `class`
                  v = `sapUiTinyMarginBegin` ).

    box->open( `SegmentedButton`
        )->a( n = `selectedKey`
              v = client->_bind( renderas )
        )->a( n = `class`
              v = `sapUiSmallMarginTop`
        )->open( `items`
            )->leaf( `SegmentedButtonItem`
                )->a( n = `key`
                      v = `canvas`
                )->a( n = `text`
                      v = `canvas`
            )->leaf( `SegmentedButtonItem`
                )->a( n = `key`
                      v = `svg`
                )->a( n = `text`
                      v = `svg` ).

    box->leaf( `Button`
           )->a( n = `text`
                 v = `Render`
           )->a( n = `type`
                 v = `Emphasized`
           )->a( n = `press`
                 v = client->_event( `RENDER` )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    DATA(result) = box->open( `Panel`
                       )->a( n = `headerText`
                             v = `Result`
                       )->a( n = `class`
                             v = `sapUiSmallMarginTop`
                       )->open( `content` ).

    zcl_z2ui5cc_barcode=>render(
        view     = result
        bcid     = client->_bind( bcid )
        text     = client->_bind( text )
        options  = client->_bind( options )
        scale    = client->_bind( scale )
        height   = client->_bind( height )
        renderas = client->_bind( renderas )
        error    = client->_event( `ERROR` ) ).

    result->leaf( `Text`
              )->a( n = `text`
                    v = client->_bind( info ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `TYPE`.
        type_apply( ).
        client->view_model_update( ).

      WHEN `RENDER`.
        info = |Rendered { bcid } as { renderas }.|.
        client->view_model_update( ).

      WHEN `ERROR`.
        info = |{ bcid } refused the value - see the message above.|.
        client->view_model_update( ).

    ENDCASE.

  ENDMETHOD.

  METHOD type_apply.

    " switching the symbology brings its example value and options along -
    " an EAN-13 needs 13 digits, a QR code does not care
    TRY.
        DATA(ls_type) = t_type[ bcid = bcid ].
        text    = ls_type-example.
        options = ls_type-options.
        " empty for a matrix code - a height would stretch it out of square
        height  = ls_type-height.
        info    = |{ ls_type-text } selected.|.
      CATCH cx_sy_itab_line_not_found.
        info = |Unknown symbology { bcid }.|.
    ENDTRY.

  ENDMETHOD.

  METHOD model_init.

    t_type   = zcl_z2ui5cc_barcode=>get_types( ).
    bcid     = t_type[ 1 ]-bcid.
    scale    = `3`.
    renderas = `canvas`.
    type_apply( ).

  ENDMETHOD.

ENDCLASS.
