"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - SignaturePad demo</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_01</em>
"!
"! Captures a delivery receipt signature and hands it to ABAP as a base64 PNG.
"! The captured string is bound straight back into an sap.m.Image, so what you
"! see below the pad is proof that the drawing really arrived in the backend.
"!
"! Ported from the abap2UI5 framework branch for issue #1257; the control now
"! ships from this repository's BSP instead of from the framework.
CLASS z2ui5_cl_cci_sample_01 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip.
    " `signature` carries a full base64 PNG, so it is deliberately the only
    " large attribute; everything else stays small.
    DATA delivery_note TYPE string.
    DATA recipient     TYPE string.
    DATA signature     TYPE string.
    DATA signed_info   TYPE string.
    DATA has_signature TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS on_save.
    "! Derives the display state from `signature`. Kept free of the client so
    "! the state logic is unit-testable without a roundtrip.
    METHODS refresh_signature_state.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_01 IMPLEMENTATION.

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

    DATA(root) = view->open( n  = `View`
                             ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`
              v = `sap.ui.core`
        )->a( n = `xmlns:form`
              v = `sap.ui.layout.form` ).

    " the whole integration on the view side - one namespace declaration
    z2ui5_cl_cci=>xmlns( root ).

    DATA(box) = root->a( n = `displayBlock`
                         v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Signature Capture`

            )->open( n  = `SimpleForm`
                     ns = `form`
                )->a( n = `editable`
                      v = `true`
                )->open( n  = `content`
                         ns = `form`

                    )->leaf( n  = `Title`
                             ns = `core`
                        )->a( n = `text`
                              v = `Delivery`

                    )->leaf( `Label`
                        )->a( n = `text`
                              v = `Delivery note`
                    )->leaf( `Input`
                        )->a( n = `value`
                              v = client->_bind( delivery_note )

                    )->leaf( `Label`
                        )->a( n = `text`
                              v = `Received by`
                    )->leaf( `Input`
                        )->a( n = `value`
                              v = client->_bind( recipient )

                )->shut(
            )->shut(

            )->open( `VBox`
                )->a( n = `class`
                      v = `sapUiSmallMargin`

                )->leaf( `Label`
                    )->a( n = `text`
                          v = `Signature` ).

    " the custom control - emitted by its own ABAP class, unknown to abap2UI5
    box = z2ui5_cl_cci_signature_pad=>render( view   = box
                                              value  = client->_bind( signature )
                                              height = `200px`
                                              change = client->_event( `SIGNED` ) ).

    box->open( `HBox`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`

           )->leaf( `Button`
               )->a( n = `text`
                     v = `Clear`
               )->a( n = `icon`
                     v = `sap-icon://eraser`
               )->a( n = `press`
                     v = client->_event( `CLEAR` )

           )->leaf( `Button`
               )->a( n = `text`
                     v = `Save`
               )->a( n = `type`
                     v = `Emphasized`
               )->a( n = `class`
                     v = `sapUiTinyMarginBegin`
               )->a( n = `press`
                     v = client->_event( `SAVE` )
       )->shut(

       " Proof that the drawing really arrived in ABAP: the very same string
       " is bound back into an Image.
       )->open( `Panel`
           )->a( n = `headerText`
                 v = `Stored signature`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
           )->a( n = `visible`
                 v = z2ui5_cl_ai_xml=>as_bool( has_signature )

           )->open( `content`
               )->leaf( `Image`
                   )->a( n = `src`
                         v = client->_bind( signature )
                   )->a( n = `alt`
                         v = `Captured signature`
                   )->a( n = `height`
                         v = `120px`
               )->leaf( `Text`
                   )->a( n = `text`
                         v = client->_bind( signed_info ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `SIGNED`.
        " `signature` already carries the base64 PNG here - bound data is
        " written back into the attribute before the event handler runs.
        refresh_signature_state( ).
        client->view_model_update( ).

      WHEN `CLEAR`.
        " Clearing is backend-driven: emptying the bound attribute blanks the
        " pad on the next roundtrip, no frontend call needed.
        signature = ``.
        refresh_signature_state( ).
        client->view_model_update( ).

      WHEN `SAVE`.
        on_save( ).

    ENDCASE.

  ENDMETHOD.

  METHOD on_save.

    IF signature IS INITIAL.
      client->message_toast_display( `Please sign before saving.` ).
      RETURN.
    ENDIF.

    " A real app would strip the `data:image/png;base64,` prefix, decode the
    " remainder into an XSTRING and store it (MIME repository, ArchiveLink, a
    " transparent table). The decoding API differs per ABAP release, so this
    " sample stops at the string to stay portable.
    client->message_box_display( |Signature for delivery note { delivery_note } | &&
                                 |received by { recipient } would be stored now.| ).

  ENDMETHOD.

  METHOD refresh_signature_state.

    IF signature IS INITIAL.
      has_signature = abap_false.
      signed_info   = ``.
      RETURN.
    ENDIF.

    has_signature = abap_true.
    " Payload size, computed in ABAP - the frontend stays thin.
    signed_info   = |Captured { strlen( signature ) } characters of base64 PNG.|.

  ENDMETHOD.

  METHOD model_init.

    delivery_note = `80001234`.
    recipient     = `J. Doe`.

  ENDMETHOD.

ENDCLASS.
