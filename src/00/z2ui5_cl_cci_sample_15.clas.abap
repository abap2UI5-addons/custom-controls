"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - ScanInput demo</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_15</em>
"!
"! A scan field as a warehouse app has it: scan (or type and press Enter) a
"! code - eight digits are accepted, anything else is refused with the value
"! state Error, which beeps and vibrates (after your first tap or key on the
"! page; browsers allow sound and vibration only then). The focus stays in
"! the field: press a button, open the dialog and close it - it comes back
"! without a roundtrip. Type into the note field and it stays there. The
"! keyboard icon in the field switches the soft keyboard; ABAP reads the
"! switch with the next roundtrip.
"!
"! Two fields make a focus sequence: an accepted code moves the focus on to
"! the batch field, an entered batch moves it back. ABAP only switches two
"! flags - each field keeps the focus while its flag is on, and the field
"! whose flag turns on takes it from the other one. The batch field turns
"! what is typed into capital letters.
CLASS z2ui5_cl_cci_sample_15 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA scan        TYPE string.
    DATA has_error   TYPE abap_bool.
    DATA message     TYPE string.
    DATA keyboard    TYPE abap_bool.
    DATA note        TYPE string.
    DATA scanned     TYPE string.
    DATA batch       TYPE string.
    DATA focus_code  TYPE abap_bool.
    DATA focus_batch TYPE abap_bool.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS popup_display.
    METHODS on_event.
    METHODS on_scan.
    METHODS on_batch.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_15 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      message    = `Scan a code - eight digits.`.
      focus_code = abap_true.
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
              v = `sap.ui.core.mvc`
        )->a( n = `xmlns:form`
              v = `sap.ui.layout.form` ).

    z2ui5_cl_cci=>xmlns( root ).

    DATA(form) = root->a( n = `displayBlock`
                          v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Scan Input`

            )->ele( n  = `SimpleForm`
                    ns = `form`
                )->a( n = `editable`
                      v = `true`
                )->ele( n  = `content`
                        ns = `form` ).

    form->tag( `Label`
        )->a( n = `text`
              v = `Code` ).

    " valueState from a flag: Error beeps, Success does not
    form = z2ui5_cl_cci_scan_input=>render(
        view                  = form
        id                    = `SCAN`
        value                 = client->_bind( scan )
        valuestate            = |\{= $\{{ client->_bind_path( has_error ) }\} ? 'Error' : 'Success' \}|
        valuestatetext        = client->_bind( message )
        placeholder           = `Scan or type, then Enter`
        inputmode             = `numeric`
        keyboard              = client->_bind( keyboard )
        showkeyboardtoggle    = `true`
        keepfocus             = client->_bind( focus_code )
        selectonfocus         = `true`
        beeponerror           = `true`
        beeponsuccess         = `true`
        vibrateonerror        = `true`
        submit                = client->_event( `SCAN` ) ).

    form->tag( `Label`
        )->a( n = `text`
              v = `Batch` ).

    " the second step of the sequence: it takes the focus when its flag
    " turns on, and writes capital letters
    form = z2ui5_cl_cci_scan_input=>render(
        view          = form
        id            = `BATCH`
        value         = client->_bind( batch )
        placeholder   = `After a code: batch, then Enter`
        uppercase     = `true`
        keepfocus     = client->_bind( focus_batch )
        selectonfocus = `true`
        submit        = client->_event( `BATCH` ) ).

    form->tag( `Label`
        )->a( n = `text`
              v = `Result`
        )->tag( `Text`
            )->a( n = `text`
                  v = client->_bind( message ) ).

    form->tag( `Label`
        )->a( n = `text`
              v = `Scanned`
        )->tag( `Text`
            )->a( n = `text`
                  v = client->_bind( scanned ) ).

    form->tag( `Label`
        )->a( n = `text`
              v = `Note (keeps its focus)`
        )->tag( `Input`
            )->a( n = `value`
                  v = client->_bind( note ) ).

    form->tag( `Label`
        )->a( n = `text`
              v = `Try`
        )->ele( `HBox`
            )->tag( `Button`
                )->a( n = `text`
                      v = `Roundtrip`
                )->a( n = `press`
                      v = client->_event( `PING` )
            )->tag( `Button`
                )->a( n = `text`
                      v = `Open dialog`
                )->a( n = `press`
                      v = client->_event( `POPUP` )
                )->a( n = `class`
                      v = `sapUiTinyMarginBegin` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD popup_display.

    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(dialog) = popup->ele( n  = `FragmentDefinition`
                               ns = `core`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:core`
              v = `sap.ui.core`
        )->ele( `Dialog`
            )->a( n = `title`
                  v = `A dialog` ).

    dialog->tag( `Text`
        )->a( n = `text`
              v = `The scan field does not take the focus while this is open. Close it and the focus is back.`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).

    dialog->ele( `buttons`
        )->tag( `Button`
            )->a( n = `text`
                  v = `Close`
            )->a( n = `press`
                  v = client->follow_up_action( client->cs_event-popup_close ) ).

    client->popup_display( popup->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.
      WHEN `SCAN`.
        on_scan( ).
      WHEN `BATCH`.
        on_batch( ).
      WHEN `PING`.
        message = |Roundtrip done - keyboard { COND #( WHEN keyboard = abap_true THEN `on` ELSE `off` ) }.|.
      WHEN `POPUP`.
        popup_display( ).
    ENDCASE.

  ENDMETHOD.

  METHOD on_scan.

    DATA(code) = condense( scan ).
    " the field is emptied either way - the next scan starts fresh
    CLEAR scan.

    IF strlen( code ) <> 8 OR code CN `0123456789`.
      has_error = abap_true.
      message   = |"{ code }" refused - eight digits expected.|.
      RETURN.
    ENDIF.

    has_error = abap_false.
    message   = |{ code } accepted - now the batch.|.
    scanned   = COND #( WHEN scanned IS INITIAL THEN code ELSE |{ code }, { scanned }| ).

    " the next step: the batch field takes the focus
    focus_code  = abap_false.
    focus_batch = abap_true.

  ENDMETHOD.

  METHOD on_batch.

    " upper case already - the field wrote capital letters
    message = |Batch { condense( batch ) } entered - next code.|.
    CLEAR batch.

    " and back to the first step
    focus_batch = abap_false.
    focus_code  = abap_true.

  ENDMETHOD.

ENDCLASS.
