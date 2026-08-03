"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo app</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo</em>
"!
"! Verifies that a custom control living outside abap2UI5 integrates exactly
"! like a built-in one:
"!   1. the foreign XML namespace resolves and the control renders
"!   2. text/count are bound from the ABAP model into the control
"!   3. clicking writes the raised count BACK into the model (two-way)
"!   4. the press event reaches this class as a normal abap2UI5 event
"!
"! If the counter shown inside the blue box and the value reported in the log
"! below it stay in lockstep, all four paths work.
CLASS zcl_z2ui5cc_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_log,
        text TYPE string,
      END OF ty_s_log.

    DATA label   TYPE string.
    DATA counter TYPE i.
    DATA info    TYPE string.
    DATA t_log   TYPE STANDARD TABLE OF ty_s_log WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client   TYPE REF TO z2ui5_if_client.
    "! roundtrips handled in ABAP - compared against the value the control
    "! wrote into the model, so a broken write-back is immediately visible
    DATA mv_presses TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS info_refresh.

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

    " keep the cursor: factory( ) returns the empty root, every open( )
    " returns the NEW node - the VBox is what the control is added to
    DATA(box) = view->open( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        " the whole integration on the view side: one extra namespace
        " declaration pointing at the control library's module namespace
        )->a( n = |xmlns:{ zcl_z2ui5cc_counter=>c_ns }|
              v = zcl_z2ui5cc_counter=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - custom control from its own BSP`

            )->open( `VBox`
                )->a( n = `class`
                      v = `sapUiMediumMargin`

                )->leaf( `Title`
                    )->a( n = `text`
                          v = `Click the blue box` ).

    " the custom control - emitted by its own ABAP class, unknown to abap2UI5
    box = zcl_z2ui5cc_counter=>render( view    = box
                                      text    = client->_bind( label )
                                      count   = client->_bind( counter )
                                      press   = client->_event( `COUNTER_PRESSED` )
                                      enabled = `true` ).

    box->leaf( `Text`
           )->a( n = `text`
                 v = client->_bind( info )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`

       )->leaf( `Button`
           )->a( n = `text`
                 v = `Reset`
           )->a( n = `press`
                 v = client->_event( `RESET` )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`

       )->open( `List`
           )->a( n = `headerText`
                 v = `Roundtrip log`
           )->a( n = `items`
                 v = client->_bind( t_log )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
           )->open( `items`
               )->leaf( `StandardListItem`
                   )->a( n = `title`
                         v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `COUNTER_PRESSED`.
        " counter already carries the value the CONTROL wrote into the model
        mv_presses = mv_presses + 1.
        INSERT VALUE #( text = |press { mv_presses }: control reported count = { counter }| )
               INTO TABLE t_log.
        info_refresh( ).
        client->view_model_update( ).

      WHEN `RESET`.
        mv_presses = 0.
        counter    = 0.
        CLEAR t_log.
        info_refresh( ).
        client->view_model_update( ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    label   = `presses`.
    counter = 0.
    info_refresh( ).

  ENDMETHOD.

  METHOD info_refresh.

    " computed in ABAP, bound as a finished string - no frontend formatter
    IF mv_presses = counter.
      info = |OK - control count { counter } matches { mv_presses } roundtrip(s) handled in ABAP.|.
    ELSE.
      info = |MISMATCH - control count { counter }, but { mv_presses } roundtrip(s) handled in ABAP.|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
