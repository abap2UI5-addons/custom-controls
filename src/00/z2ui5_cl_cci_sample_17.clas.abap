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

    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
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
    DATA box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA bar TYPE REF TO z2ui5_cl_ui5_view_builder.
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
                  v = `abap2UI5 - GridStack` ).


    box = page->ele( `VBox`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).


    bar = box->ele( `HBox`
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
        DATA lv_id TYPE string.
        FIELD-SYMBOLS <item> LIKE LINE OF t_item.
          DATA temp1 TYPE xsdboolean.

    CASE client->get( )-event.

      WHEN `MOVED`.
        " t_item already carries the positions the CONTROL wrote into the model
        info = |Moved: { client->get_event_arg( ) }|.

      WHEN `PRESSED`.

        lv_id = client->get_event_arg( ).

        LOOP AT t_item ASSIGNING <item>.

          temp1 = boolc( <item>-id = lv_id AND <item>-selected = abap_false ).
          <item>-selected = temp1.
        ENDLOOP.
        info = |Pressed: { lv_id }|.

      WHEN `RESET`.
        model_init( ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    DATA temp1 TYPE z2ui5_cl_cci_gridstack=>ty_t_item.
    DATA temp2 LIKE LINE OF temp1.
    CLEAR temp1.

    CLEAR temp2.
    temp2-id = `A1`.
    temp2-x = 0.
    temp2-y = 0.
    temp2-w = 2.
    temp2-h = 1.
    temp2-text = `A1`.
    temp2-info = `12 pcs`.
    temp2-state = z2ui5_cl_cci_gridstack=>cs_state-success.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-id = `A2`.
    temp2-x = 2.
    temp2-y = 0.
    temp2-w = 4.
    temp2-h = 1.
    temp2-text = `A2`.
    temp2-info = `3 pcs`.
    temp2-state = z2ui5_cl_cci_gridstack=>cs_state-warning.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-id = `A3`.
    temp2-x = 6.
    temp2-y = 0.
    temp2-w = 6.
    temp2-h = 2.
    temp2-text = `A3`.
    temp2-info = `empty`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-id = `B1`.
    temp2-x = 0.
    temp2-y = 1.
    temp2-w = 3.
    temp2-h = 2.
    temp2-text = `B1`.
    temp2-info = `40 pcs`.
    temp2-state = z2ui5_cl_cci_gridstack=>cs_state-success.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-id = `B2`.
    temp2-x = 3.
    temp2-y = 1.
    temp2-w = 3.
    temp2-h = 1.
    temp2-text = `B2`.
    temp2-info = `blocked`.
    temp2-state = z2ui5_cl_cci_gridstack=>cs_state-error.
    temp2-locked = abap_true.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-id = `C1`.
    temp2-x = 6.
    temp2-y = 2.
    temp2-w = 3.
    temp2-h = 2.
    temp2-text = `C1`.
    temp2-info = `empty`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-id = `C2`.
    temp2-x = 9.
    temp2-y = 2.
    temp2-w = 3.
    temp2-h = 2.
    temp2-text = `C2`.
    temp2-info = `7 pcs`.
    temp2-state = z2ui5_cl_cci_gridstack=>cs_state-information.
    INSERT temp2 INTO TABLE temp1.
    t_item = temp1.

    info = `Click a compartment to select it, or switch on Edit and drag one.`.

  ENDMETHOD.

ENDCLASS.
