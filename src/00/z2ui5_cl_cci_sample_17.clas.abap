"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo GridStack</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_17</em>
"!
"! A drawer with compartments, drawn from an ABAP table. With the switch off
"! it is a picture: a click selects a compartment, and the selection is set
"! in ABAP. With the switch on the compartments can be dragged and resized -
"! they snap to the grid, do not overlap and stay inside the drawer.
"!
"! The table below the grid is bound to the same data. It shows that a move
"! is no frontend detail: the control wrote the new position into the model,
"! and the event handler reads it from its own table.
CLASS z2ui5_cl_cci_sample_17 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_item   TYPE z2ui5_cl_cci_gridstack=>ty_t_item.
    DATA editable TYPE abap_bool.
    DATA info     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_17 IMPLEMENTATION.

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
                  v = `abap2UI5 - GridStack` ).

    DATA(box) = page->ele( `VBox`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).

    DATA(bar) = box->ele( `HBox`
        )->a( n = `alignItems`
              v = `Center`
        )->a( n = `class`
              v = `sapUiSmallMarginBottom` ).

    bar->tag( `Label`
        )->a( n = `text`
              v = `Edit`
        )->a( n = `class`
              v = `sapUiTinyMarginEnd` ).
    bar->tag( `Switch`
        )->a( n = `state`
              v = client->_bind( editable ) ).
    bar->tag( `Button`
        )->a( n = `text`
              v = `Reset`
        )->a( n = `press`
              v = client->_event( `RESET` )
        )->a( n = `class`
              v = `sapUiSmallMarginBegin` ).
    bar->tag( `Text`
        )->a( n = `text`
              v = client->_bind( info )
        )->a( n = `class`
              v = `sapUiSmallMarginBegin` ).

    z2ui5_cl_cci_gridstack=>render(
        view       = box
        items      = client->_bind( t_item )
        columns    = `12`
        rows       = `4`
        cellheight = `70`
        editable   = client->_bind( editable )
        change     = client->_event( val = `MOVED`
                                     arg = `${$parameters>/ids}` )
        itempress  = client->_event( val = `PRESSED`
                                     arg = `${$parameters>/id}` ) ).

    box->ele( `Table`
        )->a( n = `items`
              v = client->_bind( t_item )
        )->a( n = `class`
              v = `sapUiSmallMarginTop`
        )->ele( `columns`
            )->ele( `Column`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `Id`
            )->end(
            )->ele( `Column`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `Column`
            )->end(
            )->ele( `Column`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `Row`
            )->end(
            )->ele( `Column`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `Width`
            )->end(
            )->ele( `Column`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `Height`
        )->end( )->end(
        )->ele( `items`
            )->ele( `ColumnListItem`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{ID}`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{X}`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{Y}`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{W}`
                )->tag( `Text`
                    )->a( n = `text`
                          v = `{H}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `MOVED`.
        " t_item already carries the positions the CONTROL wrote into the model
        info = |Moved: { client->get_event_arg( ) }|.

      WHEN `PRESSED`.
        DATA(lv_id) = client->get_event_arg( ).
        LOOP AT t_item ASSIGNING FIELD-SYMBOL(<item>).
          <item>-selected = xsdbool( <item>-id = lv_id AND <item>-selected = abap_false ).
        ENDLOOP.
        info = |Pressed: { lv_id }|.

      WHEN `RESET`.
        model_init( ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    t_item = VALUE #(
      ( id = `A1` x = 0 y = 0 w = 2 h = 1 text = `A1` info = `12 pcs`
        state = z2ui5_cl_cci_gridstack=>cs_state-success )
      ( id = `A2` x = 2 y = 0 w = 4 h = 1 text = `A2` info = `3 pcs`
        state = z2ui5_cl_cci_gridstack=>cs_state-warning )
      ( id = `A3` x = 6 y = 0 w = 6 h = 2 text = `A3` info = `empty` )
      ( id = `B1` x = 0 y = 1 w = 3 h = 2 text = `B1` info = `40 pcs`
        state = z2ui5_cl_cci_gridstack=>cs_state-success )
      ( id = `B2` x = 3 y = 1 w = 3 h = 1 text = `B2` info = `blocked`
        state = z2ui5_cl_cci_gridstack=>cs_state-error locked = abap_true )
      ( id = `C1` x = 6 y = 2 w = 3 h = 2 text = `C1` info = `empty` )
      ( id = `C2` x = 9 y = 2 w = 3 h = 2 text = `C2` info = `7 pcs`
        state = z2ui5_cl_cci_gridstack=>cs_state-information ) ).

    info = `Click a compartment to select it, or switch on Edit and drag one.`.

  ENDMETHOD.

ENDCLASS.
