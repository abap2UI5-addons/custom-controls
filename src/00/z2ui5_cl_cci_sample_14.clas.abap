"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Clock demo</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_14</em>
"!
"! Four clocks in the formats the control knows, and one in the overflow menu
"! of the footer - open the menu and the time keeps running while it stays
"! open. All of it ticks in the browser; the backend never hears of it.
CLASS z2ui5_cl_cci_sample_14 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_14 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      IF client->get( )-event = `PRESSED`.
        client->message_toast_display( `A button in the overflow menu - the clock kept ticking.` ).
      ENDIF.
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

    DATA(page) = root->a( n = `displayBlock`
                          v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Clock` ).

    DATA(form) = page->ele( n  = `SimpleForm`
                            ns = `form`
        )->a( n = `editable`
              v = `false`
        )->ele( n  = `content`
                ns = `form` ).

    form->tag( `Label`
        )->a( n = `text`
              v = `datetime (default)` ).
    form = z2ui5_cl_cci_clock=>render( view = form
                                       icon = `sap-icon://history` ).

    form->tag( `Label`
        )->a( n = `text`
              v = `date` ).
    form = z2ui5_cl_cci_clock=>render( view   = form
                                       format = `date`
                                       icon   = `sap-icon://calendar` ).

    form->tag( `Label`
        )->a( n = `text`
              v = `time, en-US` ).
    form = z2ui5_cl_cci_clock=>render( view   = form
                                       format = `time`
                                       locale = `en-US` ).

    form->tag( `Label`
        )->a( n = `text`
              v = `shorttime, de-DE` ).
    z2ui5_cl_cci_clock=>render( view   = form
                                format = `shorttime`
                                locale = `de-DE` ).

    DATA(footer) = page->ele( `footer`
        )->ele( `OverflowToolbar` ).

    footer->tag( `ToolbarSpacer` ).

    " always in the overflow menu, like any other button
    footer = z2ui5_cl_cci_clock=>render( view     = footer
                                         icon     = `sap-icon://history`
                                         priority = `AlwaysOverflow` ).

    footer->ele( `Button`
        )->a( n = `text`
              v = `Another action`
        )->a( n = `press`
              v = client->_event( `PRESSED` )
        )->ele( `layoutData`
            )->tag( `OverflowToolbarLayoutData`
                )->a( n = `priority`
                      v = `AlwaysOverflow` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
