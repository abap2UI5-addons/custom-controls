"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - NetworkStatus demo</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_13</em>
"!
"! A large status display and a small icon in the footer, both fed by the
"! same browser-side monitor. Switch the browser's developer tools to
"! Offline or to a slow network and watch them change - without a roundtrip.
"! The status is also bound: press Refresh and ABAP shows what the browser
"! reported, which is how an app reads the state before it saves.
"!
"! No `change` event here on purpose: it would start a roundtrip exactly when
"! the browser went offline, and that roundtrip cannot reach the server.
CLASS z2ui5_cl_cci_sample_13 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA status  TYPE string.
    DATA latency TYPE i.
    DATA quality TYPE i.
    DATA info    TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS refresh_info.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_13 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ) IS NOT INITIAL.
      refresh_info( ).
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA root TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA footer TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).


    root = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc` ).

    z2ui5_cl_cci=>xmlns( root ).


    page = root->a( n = `displayBlock`
                          v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Network Status`

            )->tag( `MessageStrip`
                )->a( n = `text`
                      v = `Determined in the browser: the online/offline events plus a ping ` &&
                          `on /sap/public/ping every 5 seconds (activate the service in SICF). ` &&
                          `Switch the developer tools to Offline to try it.`
                )->a( n = `type`
                      v = `Information`
                )->a( n = `showIcon`
                      v = `true`
                )->a( n = `class`
                      v = `sapUiSmallMargin` ).

    " the large display - bound, so ABAP learns the state on the next roundtrip
    page = z2ui5_cl_cci_net_status=>render( view        = page
                                            status      = client->_bind( status )
                                            latency     = client->_bind( latency )
                                            quality     = client->_bind( quality )
                                            iconsize    = `2rem`
                                            showtext    = `true`
                                            showquality = `true`
                                            showdetails = `true`
                                            class       = `sapUiSmallMargin` ).

    page->tag( `Text`
        )->a( n = `text`
              v = client->_bind( info )
        )->a( n = `class`
              v = `sapUiSmallMargin` ).

    " the small one in a footer - an icon only, it never moves into the
    " overflow menu, so it stays visible

    footer = page->ele( `footer`
        )->ele( `OverflowToolbar` ).

    footer = z2ui5_cl_cci_net_status=>render( footer ).

    footer->tag( `ToolbarSpacer`
        )->tag( `Button`
            )->a( n = `text`
                  v = `Refresh`
            )->a( n = `icon`
                  v = `sap-icon://refresh`
            )->a( n = `press`
                  v = client->_event( `REFRESH` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get( )-event = `REFRESH`.
      " status, latency and quality already carry what the browser
      " measured - bound data is written back before the handler runs -
      " and the changed info reaches the view without a call: the
      " framework pushes the model when bound data changed
      refresh_info( ).
    ENDIF.

  ENDMETHOD.

  METHOD refresh_info.

    IF status IS INITIAL.
      info = `ABAP has not heard from the browser yet - press Refresh.`.
      RETURN.
    ENDIF.

    info = |ABAP received: status { status }, latency { latency } ms, { quality } of 4 bars.|.

  ENDMETHOD.

ENDCLASS.
