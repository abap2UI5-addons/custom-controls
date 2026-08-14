"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Validator</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_03</em>
"!
"! A small form with four rules declared in ABAP. Pressing Submit raises the
"! trigger; the control checks the fields in the browser, paints the offending
"! ones red - and the very same roundtrip carries the verdict and the error
"! list back here, which is what the panel underneath shows.
"!
"! Submitting is refused as long as the form is invalid, so the check is not
"! decoration: the backend acts on the result.
CLASS z2ui5_cl_cci_sample_03 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA email    TYPE string.
    DATA quantity TYPE string.
    DATA zipcode  TYPE string.
    DATA comment  TYPE string.

    DATA t_rule  TYPE z2ui5_cl_cci_validator=>ty_t_rule.
    DATA t_error TYPE z2ui5_cl_cci_validator=>ty_t_error.
    DATA trigger TYPE i.
    DATA valid   TYPE abap_bool.
    DATA info    TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_03 IMPLEMENTATION.

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
                  v = `abap2UI5 - Validator`
            ).

    " the rules travel to the frontend as data, not as JavaScript
    z2ui5_cl_cci_validator=>render(
        view      = page
        trigger   = client->_bind( trigger )
        valid     = client->_bind( valid )
        errors    = client->_bind( t_error )
        validated = client->_event( `VALIDATED` )
        rules     = client->_bind( val           = t_rule
                                   custom_filter = NEW z2ui5_cl_cci_json_filter( ) ) ).

    DATA(box) = page->ele( `VBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `e-mail (required, must look like an address)`
       )->tag( `Input`
           )->a( n = `id`
                 v = `email`
           )->a( n = `value`
                 v = client->_bind( email )
           )->a( n = `width`
                 v = `24rem`

       )->tag( `Label`
           )->a( n = `text`
                 v = `quantity (whole number, 1 to 999)`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `Input`
           )->a( n = `id`
                 v = `quantity`
           )->a( n = `value`
                 v = client->_bind( quantity )
           )->a( n = `width`
                 v = `24rem`

       )->tag( `Label`
           )->a( n = `text`
                 v = `zip code (5 digits, optional)`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `Input`
           )->a( n = `id`
                 v = `zipcode`
           )->a( n = `value`
                 v = client->_bind( zipcode )
           )->a( n = `width`
                 v = `24rem`

       )->tag( `Label`
           )->a( n = `text`
                 v = `comment (at most 40 characters)`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `TextArea`
           )->a( n = `id`
                 v = `comment`
           )->a( n = `value`
                 v = client->_bind( comment )
           )->a( n = `width`
                 v = `24rem`

       )->tag( `Button`
           )->a( n = `text`
                 v = `Submit`
           )->a( n = `type`
                 v = `Emphasized`
           )->a( n = `press`
                 v = client->_event( `SUBMIT` )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    box->ele( `Panel`
        )->a( n = `headerText`
              v = `What ABAP got back`
        )->a( n = `class`
              v = `sapUiSmallMarginTop`
        )->ele( `content`
            )->tag( `Text`
                )->a( n = `text`
                      v = client->_bind( info )
            )->ele( `List`
                )->a( n = `items`
                      v = client->_bind( t_error )
                )->a( n = `noDataText`
                      v = `no errors`
                )->ele( `items`
                    )->tag( `StandardListItem`
                        )->a( n = `title`
                              v = `{FIELD}`
                        )->a( n = `description`
                              v = `{MESSAGE}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `SUBMIT`.
        " raising the trigger is the whole call - the control validates while
        " this response travels back, and reports on the next roundtrip
        trigger = trigger + 1.
        info    = |Check { trigger } running...|.

      WHEN `VALIDATED`.
        " valid and t_error already carry what the CONTROL wrote into the model
        IF valid = abap_true.
          info = |Check { trigger }: form is valid - { quantity } x ordered for { email }.|.
        ELSE.
          info = |Check { trigger }: rejected, { lines( t_error ) } field(s) to correct.|.
        ENDIF.

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    t_rule = VALUE #(
      ( field = `email`    required = abap_true format = `email` )
      ( field = `quantity` required = abap_true type = `integer` minimum = 1 maximum = 999 )
      ( field = `zipcode`  pattern  = `^[0-9]{5}$`
        message = `Enter five digits, e.g. 69190` )
      ( field = `comment`  maxlength = 40 ) ).

    email    = `not-an-address`.
    quantity = `0`.
    info     = `Press Submit.`.

  ENDMETHOD.

ENDCLASS.
