"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Gauge</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_16</em>
"!
"! Two gauges on one value. The slider is bound to the same variable as the
"! gauges, so dragging it moves both needles in the browser, without a
"! roundtrip - and <em>Next value</em> sets the value in ABAP, which moves
"! them just the same.
"!
"! The left gauge is the default three-quarter dial with three zones. The
"! right one is a half dial: the same control with another start angle and
"! another scale.
CLASS z2ui5_cl_cci_sample_16 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA value  TYPE i.
    DATA t_zone TYPE z2ui5_cl_cci_gauge=>ty_t_highlight.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_16 IMPLEMENTATION.

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

    DATA(root) = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc` ).

    z2ui5_cl_cci=>xmlns( root ).

    DATA(page) = root->a( n = `displayBlock`
                          v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Gauge` ).

    DATA(box) = page->ele( `VBox`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).

    DATA(row) = box->ele( `HBox`
        )->a( n = `wrap`
              v = `Wrap` ).

    row = z2ui5_cl_cci_gauge=>render( view         = row
                                      value        = client->_bind( value )
                                      title        = `Utilization`
                                      units        = `%`
                                      tickinterval = `10`
                                      highlights   = client->_bind( t_zone )
                                      width        = `300`
                                      height       = `300` ).

    " a half dial: the scale starts on the left and runs half way round
    z2ui5_cl_cci_gauge=>render( view         = row
                                value        = client->_bind( value )
                                title        = `Half dial`
                                startangle   = `90`
                                ticksangle   = `180`
                                tickinterval = `25`
                                minorticks   = `5`
                                valuebox     = `false`
                                width        = `300`
                                height       = `300` ).

    box->tag( `Slider`
        )->a( n = `value`
              v = client->_bind( value )
        )->a( n = `min`
              v = `0`
        )->a( n = `max`
              v = `100`
        )->a( n = `width`
              v = `600px`
        )->a( n = `showAdvancedTooltip`
              v = `true` ).

    box->tag( `Button`
        )->a( n = `text`
              v = `Next value`
        )->a( n = `icon`
              v = `sap-icon://synchronize`
        )->a( n = `press`
              v = client->_event( `NEXT` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get( )-event = `NEXT`.
      " a walk through 0..100 that looks random enough for a demo and needs
      " no class that is missing in one of the ABAP flavours
      value = ( value * 37 + 11 ) MOD 101.
    ENDIF.

  ENDMETHOD.

  METHOD model_init.

    value = 73.

    t_zone = VALUE #( ( low = 0  high = 60  color = `#2b7d2b` )
                      ( low = 60 high = 80  color = `#e9730c` )
                      ( low = 80 high = 100 color = `#bb0000` ) ).

  ENDMETHOD.

ENDCLASS.
