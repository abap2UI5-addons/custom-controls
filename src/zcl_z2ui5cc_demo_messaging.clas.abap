"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Messaging</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_messaging</em>
"!
"! Shows both directions of the bridge:
"!
"!   frontend -> ABAP  the two inputs are bound with UI5 type constraints
"!                     (maxLength 5, minLength 3). Violating one files a UI5
"!                     message without a roundtrip; the table below fills up
"!                     with it as soon as the next roundtrip happens.
"!   ABAP -> frontend  <em>Add backend message</em> puts a row into the table
"!                     that targets the quantity field - the field turns red
"!                     and the message joins the MessagePopover in the footer.
"!
"! The badge on the footer button counts the rows of the very same table, so
"! frontend and backend view of the message list are visibly the same list.
CLASS zcl_z2ui5cc_demo_messaging DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_message TYPE zcl_z2ui5cc_messaging=>ty_t_item.
    DATA quantity  TYPE string.
    DATA product   TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS popover_display.
    METHODS on_event.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_messaging IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      product = `tomato`.
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).

    DATA(page) = view->open( n  = `View`
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
                  v = `abap2UI5 - Messaging`
            )->a( n = `showNavButton`
                  v = `true`
            )->a( n = `navButtonPress`
                  v = client->_event( `BACK` ) ).

    " the bridge itself - renders nothing, mirrors the UI5 message model
    zcl_z2ui5cc_messaging=>render(
        view           = page
        items          = client->_bind( t_message )
        messageschange = client->_event( `MESSAGES_CHANGED` ) ).

    DATA(form) = page->open( `VBox`
                     )->a( n = `class`
                           v = `sapUiMediumMargin` ).

    form->leaf( `MessageStrip`
            )->a( n = `text`
                  v = `Type more than 5 characters into quantity, or fewer than ` &&
                      `3 into product - UI5 files the message, the table below picks it up.`
            )->a( n = `type`
                  v = `Information`
            )->a( n = `showIcon`
                  v = `true`
            )->a( n = `class`
                  v = `sapUiSmallMarginBottom`

        )->leaf( `Label`
            )->a( n = `text`
                  v = `quantity (maxLength 5)`
        )->leaf( `Input`
            )->a( n = `id`
                  v = `quantity`
            " a plain path plus a UI5 type: the constraint is checked in the
            " frontend and files a message when it is violated
            )->a( n = `value`
                  v = |\{path:'{ client->_bind( val = quantity path = abap_true ) }',| &&
                      |type:'sap.ui.model.type.String',constraints:\{maxLength:5\}\}|
            )->a( n = `width`
                  v = `20rem`

        )->leaf( `Label`
            )->a( n = `text`
                  v = `product (minLength 3)`
            )->a( n = `class`
                  v = `sapUiSmallMarginTop`
        )->leaf( `Input`
            )->a( n = `id`
                  v = `product`
            )->a( n = `value`
                  v = |\{path:'{ client->_bind( val = product path = abap_true ) }',| &&
                      |type:'sap.ui.model.type.String',constraints:\{minLength:3\}\}|
            )->a( n = `width`
                  v = `20rem` ).

    form->open( `Table`
        )->a( n = `items`
              v = client->_bind( t_message )
        )->a( n = `class`
              v = `sapUiSmallMarginTop`
        )->a( n = `noDataText`
              v = `no messages`
        )->open( `headerToolbar`
            )->open( `OverflowToolbar`
                )->leaf( `Title`
                    )->a( n = `text`
                          v = `The message model, as ABAP sees it`
        )->shut( )->shut(
        )->open( `columns`
            )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Type`
        )->shut(
            )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Message`
        )->shut(
            )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Target`
        )->shut( )->shut(
        )->open( `items`
            )->open( `ColumnListItem`
                )->open( `cells`
                    )->leaf( `Text` )->a( n = `text` v = `{TYPE}`
                    )->leaf( `Text` )->a( n = `text` v = `{MESSAGE}`
                    )->leaf( `Text` )->a( n = `text` v = `{TARGET}` ).

    DATA(bar) = page->open( `footer`
                    )->open( `OverflowToolbar` ).

    DATA(button) = bar->open( `Button`
                       )->a( n = `id`
                             v = `messageButton`
                       )->a( n = `icon`
                             v = `sap-icon://message-popup`
                       )->a( n = `press`
                             v = client->_event( `POPOVER` ) ).

    " the badge counts the rows of the bound table - the same list the
    " control keeps in sync with the UI5 message model
    button->open( `customData`
        )->leaf( `BadgeCustomData`
            )->a( n = `key`
                  v = `badge`
            )->a( n = `value`
                  v = |\{= $\{{ client->_bind( val   = t_message
                                               path  = abap_true ) }\}.length\}| ).

    bar->leaf( `ToolbarSpacer`
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Add backend message`
            )->a( n = `press`
                  v = client->_event( `ADD` )
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Clear`
            )->a( n = `press`
                  v = client->_event( `CLEAR` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD popover_display.

    DATA(popover) = z2ui5_cl_ai_xml=>factory( ).

    popover->open( n  = `FragmentDefinition`
                   ns = `core`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:core`
              v = `sap.ui.core`

        )->open( `MessagePopover`
            )->a( n = `placement`
                  v = `Top`
            )->a( n = `items`
                  v = client->_bind( t_message )
            )->open( `items`
                )->leaf( `MessageItem`
                    )->a( n = `type`
                          v = `{TYPE}`
                    )->a( n = `title`
                          v = `{MESSAGE}`
                    )->a( n = `description`
                          v = `{DESCRIPTION}` ).

    client->popover_display( xml   = popover->stringify( )
                             by_id = `messageButton` ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `MESSAGES_CHANGED`.
        " t_message already carries what the CONTROL wrote into the model
        client->view_model_update( ).

      WHEN `ADD`.
        INSERT VALUE #( message = |quantity { quantity } is not on stock|
                        type    = `Error`
                        target  = `quantity/value` )
               INTO TABLE t_message.
        client->view_model_update( ).

      WHEN `CLEAR`.
        CLEAR t_message.
        client->view_model_update( ).

      WHEN `POPOVER`.
        popover_display( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
