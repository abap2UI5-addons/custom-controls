"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo driver.js</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_06</em>
"!
"! A small order form with a three step tour over its fields, and a highlight
"! that spotlights the whole panel. Both are declared as ABAP structures -
"! there is no JavaScript in this class, and the steps name the control ids
"! from the view, not CSS selectors.
"!
"! The tour reports back: every step fires an event, so the counter under the
"! form follows along, and the last step closing is what re-enables the
"! buttons.
CLASS z2ui5_cl_cci_sample_06 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA s_tour      TYPE z2ui5_cl_cci_driverjs=>ty_s_config.
    DATA s_highlight TYPE z2ui5_cl_cci_driverjs=>ty_s_step.
    DATA trigger     TYPE i.
    DATA mode        TYPE string.
    DATA css         TYPE string.
    DATA product     TYPE string.
    DATA quantity    TYPE string.
    DATA info        TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_06 IMPLEMENTATION.

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
                  v = `abap2UI5 - driver.js`
            ).

    z2ui5_cl_cci_driverjs=>render(
        view        = page
        trigger     = client->_bind( trigger )
        mode        = client->_bind( mode )
        customcss   = client->_bind( css )
        highlighted = client->_event( `STEP` )
        done        = client->_event( `DONE` )
        config      = client->_bind( val           = s_tour
                                     custom_filter = NEW z2ui5_cl_cci_json_filter( )
                                     custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                         iv_first_json_upper = abap_false ) )
        highlight   = client->_bind( val           = s_highlight
                                     custom_filter = NEW z2ui5_cl_cci_json_filter( )
                                     custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                         iv_first_json_upper = abap_false ) ) ).

    page->ele( `headerContent`
        )->tag( `Button`
            )->a( n = `text`
                  v = `Start tour`
            )->a( n = `type`
                  v = `Emphasized`
            )->a( n = `press`
                  v = client->_event( `TOUR` )
        )->tag( `Button`
            )->a( n = `text`
                  v = `Highlight`
            )->a( n = `press`
                  v = client->_event( `HIGHLIGHT` ) ).

    DATA(panel) = page->ele( `Panel`
                      )->a( n = `id`
                            v = `orderPanel`
                      )->a( n = `headerText`
                            v = `New order`
                      )->a( n = `class`
                            v = `sapUiMediumMargin`
                      )->ele( `content`
                          )->ele( `VBox`
                              )->a( n = `class`
                                    v = `sapUiSmallMargin` ).

    panel->tag( `Label`
             )->a( n = `text`
                   v = `product`
         )->tag( `Input`
             )->a( n = `id`
                   v = `product`
             )->a( n = `value`
                   v = client->_bind( product )
             )->a( n = `width`
                   v = `20rem`

         )->tag( `Label`
             )->a( n = `text`
                   v = `quantity`
             )->a( n = `class`
                   v = `sapUiSmallMarginTop`
         )->tag( `Input`
             )->a( n = `id`
                   v = `quantity`
             )->a( n = `value`
                   v = client->_bind( quantity )
             )->a( n = `width`
                   v = `20rem`

         )->tag( `Button`
             )->a( n = `id`
                   v = `post`
             )->a( n = `text`
                   v = `Post`
             )->a( n = `type`
                   v = `Emphasized`
             )->a( n = `press`
                   v = client->_event( `POST` )
             )->a( n = `class`
                   v = `sapUiSmallMarginTop`

         )->tag( `Text`
             )->a( n = `text`
                   v = client->_bind( info )
             )->a( n = `class`
                   v = `sapUiSmallMarginTop` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `TOUR`.
        mode    = z2ui5_cl_cci_driverjs=>cs_mode-tour.
        trigger = trigger + 1.
        info    = `Tour running...`.

      WHEN `HIGHLIGHT`.
        mode    = z2ui5_cl_cci_driverjs=>cs_mode-highlight.
        trigger = trigger + 1.
        info    = `Highlight shown.`.

      WHEN `STEP`.
        info = `A step was highlighted - the event reached ABAP.`.

      WHEN `DONE`.
        info = `Tour finished.`.

      WHEN `POST`.
        client->message_toast_display( |{ quantity } x { product } posted.| ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    product  = `tomato`.
    quantity = `500`.
    mode     = z2ui5_cl_cci_driverjs=>cs_mode-tour.
    info     = `Press "Start tour".`.

    s_tour-show_progress = abap_true.
    s_tour-progress_text = `{{current}} of {{total}}`.
    s_tour-popover_class = `driverjs-theme`.
    s_tour-allow_close   = abap_true.

    " element is the control id from the view above, nothing else
    s_tour-steps = VALUE #(
      ( element = `product`
        popover-title       = `<strong>What to order</strong>`
        popover-description = `The material. Type at least three characters ` &&
                              `to get a value help.`
        popover-side        = z2ui5_cl_cci_driverjs=>cs_side-right
        popover-align       = z2ui5_cl_cci_driverjs=>cs_align-start )
      ( element = `quantity`
        popover-title       = `<strong>How many</strong>`
        popover-description = `Whole pieces. The unit comes from the material master.`
        popover-side        = z2ui5_cl_cci_driverjs=>cs_side-right
        popover-align       = z2ui5_cl_cci_driverjs=>cs_align-start )
      ( element = `post`
        popover-title       = `<strong>Post it</strong>`
        popover-description = `This sends the order to the backend.`
        popover-side        = z2ui5_cl_cci_driverjs=>cs_side-bottom
        popover-align       = z2ui5_cl_cci_driverjs=>cs_align-start ) ).

    s_highlight-element             = `orderPanel`.
    s_highlight-popover-title       = `<strong>The whole form</strong>`.
    s_highlight-popover-description = `A highlight spotlights one element and ` &&
                                      `has no next/previous buttons.`.

    " theming the popover - the original sample shipped exactly this snippet
    css = `.driver-popover.driverjs-theme {`                                && |\n| &&
          `  background-color: #f5f6f7;`                                    && |\n| &&
          `  color: #000;`                                                  && |\n| &&
          `}`                                                               && |\n| &&
          `.driver-popover.driverjs-theme .driver-popover-title {`          && |\n| &&
          `  font-size: 20px;`                                              && |\n| &&
          `}`                                                               && |\n| &&
          `.driver-popover.driverjs-theme button {`                         && |\n| &&
          `  background-color: #fff;`                                       && |\n| &&
          `  color: #0064d9;`                                               && |\n| &&
          `  text-shadow: none;`                                            && |\n| &&
          `  font-size: 14px;`                                              && |\n| &&
          `  padding: 5px 8px;`                                             && |\n| &&
          `  border-radius: 6px;`                                           && |\n| &&
          `}`                                                               && |\n| &&
          `.driver-popover.driverjs-theme button:hover {`                   && |\n| &&
          `  background-color: #0070f2;`                                    && |\n| &&
          `  color: #fff;`                                                  && |\n| &&
          `}`.

  ENDMETHOD.

ENDCLASS.
