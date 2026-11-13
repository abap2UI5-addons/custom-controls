"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Barcode</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_05</em>
"!
"! Pick a symbology, type a value, and the barcode is drawn in the browser -
"! no image is built in ABAP and none is transferred. Every field is bound, so
"! changing one and pressing Render redraws it.
"!
"! Entering something the symbology cannot encode (letters into an EAN-13, for
"! instance) is worth trying: the control renders the reason in place and
"! reports it back here through the <em>error</em> event.
CLASS z2ui5_cl_cci_sample_05 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_type   TYPE z2ui5_cl_cci_barcode=>ty_t_type.
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


CLASS z2ui5_cl_cci_sample_05 IMPLEMENTATION.

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
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA result TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).


    page = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        " sap.ui.core.Item - the ComboBox' items live in that namespace
        )->a( n = `xmlns:core`
              v = `sap.ui.core`
        )->a( n = |xmlns:{ z2ui5_cl_cci=>c_ns }|
              v = z2ui5_cl_cci=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Barcode`
            ).


    box = page->ele( `VBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `symbology`
       )->ele( `ComboBox`
           )->a( n = `selectedKey`
                 v = client->_bind( bcid )
           )->a( n = `items`
                 v = client->_bind( t_type )
           )->a( n = `width`
                 v = `20rem`
           )->a( n = `change`
                 v = client->_event( `TYPE` )
           )->ele( `items`
               )->tag( n  = `Item`
                       ns = `core`
                   )->a( n = `key`
                         v = `{BCID}`
                   )->a( n = `text`
                         v = `{TEXT}` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `value`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `Input`
           )->a( n = `value`
                 v = client->_bind( text )
           )->a( n = `width`
                 v = `20rem`

       )->tag( `Label`
           )->a( n = `text`
                 v = `BWIPP options`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `Input`
           )->a( n = `value`
                 v = client->_bind( options )
           )->a( n = `width`
                 v = `20rem`

       )->tag( `Label`
           )->a( n = `text`
                 v = `scale / height`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    box->ele( `HBox`
        )->tag( `StepInput`
            )->a( n = `value`
                  v = client->_bind( scale )
            )->a( n = `min`
                  v = `1`
            )->a( n = `max`
                  v = `9`
        )->tag( `StepInput`
            )->a( n = `value`
                  v = client->_bind( height )
            )->a( n = `min`
                  v = `5`
            )->a( n = `max`
                  v = `40`
            )->a( n = `class`
                  v = `sapUiTinyMarginBegin` ).

    box->ele( `SegmentedButton`
        )->a( n = `selectedKey`
              v = client->_bind( renderas )
        )->a( n = `class`
              v = `sapUiSmallMarginTop`
        )->ele( `items`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`
                      v = `canvas`
                )->a( n = `text`
                      v = `canvas`
            )->tag( `SegmentedButtonItem`
                )->a( n = `key`
                      v = `svg`
                )->a( n = `text`
                      v = `svg` ).

    box->tag( `Button`
           )->a( n = `text`
                 v = `Render`
           )->a( n = `type`
                 v = `Emphasized`
           )->a( n = `press`
                 v = client->_event( `RENDER` )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).


    result = box->ele( `Panel`
                       )->a( n = `headerText`
                             v = `Result`
                       )->a( n = `class`
                             v = `sapUiSmallMarginTop`
                       )->ele( `content` ).

    z2ui5_cl_cci_barcode=>render(
        view     = result
        bcid     = client->_bind( bcid )
        text     = client->_bind( text )
        options  = client->_bind( options )
        scale    = client->_bind( scale )
        height   = client->_bind( height )
        renderas = client->_bind( renderas )
        error    = client->_event( `ERROR` ) ).

    result->tag( `Text`
              )->a( n = `text`
                    v = client->_bind( info ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `TYPE`.
        type_apply( ).

      WHEN `RENDER`.
        info = |Rendered { bcid } as { renderas }.|.

      WHEN `ERROR`.
        info = |{ bcid } refused the value - see the message above.|.

    ENDCASE.

  ENDMETHOD.

  METHOD type_apply.
        DATA ls_type LIKE LINE OF t_type.
        FIELD-SYMBOLS <temp1> LIKE LINE OF t_type.
        DATA temp2 LIKE sy-tabix.

    " switching the symbology brings its example value and options along -
    " an EAN-13 needs 13 digits, a QR code does not care
    TRY.



        temp2 = sy-tabix.
        READ TABLE t_type WITH KEY bcid = bcid ASSIGNING <temp1>.
        sy-tabix = temp2.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ls_type = <temp1>.
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
    FIELD-SYMBOLS <temp1> LIKE LINE OF t_type.
    DATA temp2 LIKE sy-tabix.

    t_type   = z2ui5_cl_cci_barcode=>get_types( ).


    temp2 = sy-tabix.
    READ TABLE t_type INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    bcid     = <temp1>-bcid.
    scale    = `3`.
    renderas = `canvas`.
    type_apply( ).

  ENDMETHOD.

ENDCLASS.
