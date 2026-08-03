"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Favicon</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_favicon</em>
"!
"! Type a URL into the input, press Apply, and the browser tab icon follows.
"! The control owns a single link element, so switching between the presets
"! never leaves a stale icon behind - which is what the roundtrip counter in
"! the footer is there to make visible.
CLASS zcl_z2ui5cc_demo_favicon DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_preset,
        name TYPE string,
        href TYPE string,
      END OF ty_s_preset.

    DATA favicon  TYPE string.
    DATA info     TYPE string.
    DATA t_preset TYPE STANDARD TABLE OF ty_s_preset WITH EMPTY KEY.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    DATA mv_changes TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_favicon IMPLEMENTATION.

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

    DATA(box) = view->open( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = |xmlns:{ zcl_z2ui5cc=>c_ns }|
              v = zcl_z2ui5cc=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Favicon`
            )->a( n = `showNavButton`
                  v = `true`
            )->a( n = `navButtonPress`
                  v = client->_event( `BACK` )

            )->open( `VBox`
                )->a( n = `class`
                      v = `sapUiMediumMargin` ).

    " the control itself renders nothing - it only writes into <head>
    box = zcl_z2ui5cc_favicon=>render( view = box
                                       href = client->_bind( favicon ) ).

    box->leaf( `Input`
           )->a( n = `value`
                 v = client->_bind( favicon )
           )->a( n = `placeholder`
                 v = `URL or data: URI of the tab icon`
           )->a( n = `width`
                 v = `100%`

       )->leaf( `Button`
           )->a( n = `text`
                 v = `Apply`
           )->a( n = `type`
                 v = `Emphasized`
           )->a( n = `press`
                 v = client->_event( `APPLY` )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`

       )->leaf( `Text`
           )->a( n = `text`
                 v = client->_bind( info )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`

       )->open( `List`
           )->a( n = `headerText`
                 v = `Presets`
           )->a( n = `items`
                 v = client->_bind( t_preset )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
           )->open( `items`
               )->open( `StandardListItem`
                   )->a( n = `title`
                         v = `{NAME}`
                   )->a( n = `description`
                         v = `{HREF}`
                   )->a( n = `type`
                         v = `Active`
                   )->a( n = `press`
                         v = client->_event( val   = `PRESET`
                                             t_arg = VALUE #( ( `${HREF}` ) ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `APPLY`.
        mv_changes = mv_changes + 1.
        info = |Icon set to { favicon } ({ mv_changes } change(s) so far).|.
        client->view_model_update( ).

      WHEN `PRESET`.
        favicon    = client->get_event_arg( 1 ).
        mv_changes = mv_changes + 1.
        info = |Icon set to { favicon } ({ mv_changes } change(s) so far).|.
        client->view_model_update( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    t_preset = VALUE #(
      ( name = `abap2UI5`
        href = `https://cdn.jsdelivr.net/gh/abap2UI5/abap2UI5/resources/abap2ui5.png` )
      ( name = `red dot (inline SVG, no server needed)`
        href = `data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" ` &&
               `viewBox="0 0 16 16"><circle cx="8" cy="8" r="7" fill="%23d32f2f"/></svg>` ) ).

    favicon = t_preset[ 1 ]-href.
    info    = `Press Apply, then look at the browser tab.`.

  ENDMETHOD.

ENDCLASS.
