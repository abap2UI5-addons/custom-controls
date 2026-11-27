"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo FloorPlan</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_18</em>
"!
"! A block storage seen from above: two halls, 104 lanes, each with a fill
"! level. Zoom with the wheel, the buttons or two fingers, drag to pan - the
"! closer the view, the more a lane says about itself.
"!
"! <em>Nearly full</em> points the lanes above 90 % out and flies to them,
"! <em>Stock taking</em> recounts every lane - the plan is drawn again from
"! the new table and the viewport stays where it is. A click selects a lane
"! and the text above the plan is filled from ABAP.
"!
"! The lanes and their contents are made up.
CLASS z2ui5_cl_cci_sample_18 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA t_item    TYPE z2ui5_cl_cci_floor_plan=>ty_t_item.
    DATA t_area    TYPE z2ui5_cl_cci_floor_plan=>ty_t_area.
    DATA selected  TYPE string.
    DATA highlight TYPE string.
    DATA fit       TYPE string.
    DATA info      TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " not bound, so not PUBLIC - it survives the roundtrip here as well
    DATA round  TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS lanes_fill.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_18 IMPLEMENTATION.

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
                  v = `abap2UI5 - FloorPlan` ).

    DATA(box) = page->ele( `VBox`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).

    DATA(bar) = box->ele( `HBox`
        )->a( n = `alignItems`
              v = `Center`
        )->a( n = `class`
              v = `sapUiSmallMarginBottom` ).

    bar->tag( `Button`
        )->a( n = `text`
              v = `Nearly full`
        )->a( n = `press`
              v = client->_event( `FULL` ) ).
    bar->tag( `Button`
        )->a( n = `text`
              v = `Show all`
        )->a( n = `press`
              v = client->_event( `ALL` )
        )->a( n = `class`
              v = `sapUiTinyMarginBegin` ).
    bar->tag( `Button`
        )->a( n = `text`
              v = `Stock taking`
        )->a( n = `press`
              v = client->_event( `COUNT` )
        )->a( n = `class`
              v = `sapUiTinyMarginBegin` ).
    bar->tag( `Text`
        )->a( n = `text`
              v = client->_bind( info )
        )->a( n = `class`
              v = `sapUiSmallMarginBegin` ).

    z2ui5_cl_cci_floor_plan=>render(
        view          = box
        items         = client->_bind( t_item )
        areas         = client->_bind( t_area )
        selectedkeys  = client->_bind( selected )
        highlightkeys = client->_bind( highlight )
        fitkeys       = client->_bind( fit )
        selectionmode = z2ui5_cl_cci_floor_plan=>cs_selection_mode-single
        height        = `70vh`
        itempress     = client->_event( val = `LANE`
                                        arg = `${$parameters>/key}` ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `LANE`.
        " selected already carries what the CONTROL wrote into the model
        DATA(lv_key) = client->get_event_arg( ).
        IF selected IS INITIAL.
          info = `Nothing selected.`.
        ELSE.
          DATA(ls_item) = VALUE #( t_item[ key = lv_key ] OPTIONAL ).
          info = |Lane { ls_item-title }: { ls_item-text }, { ls_item-info }|.
        ENDIF.

      WHEN `FULL`.
        CLEAR highlight.
        LOOP AT t_item INTO ls_item WHERE fill > '0.9'.
          highlight = |{ highlight }{ COND #( WHEN highlight IS NOT INITIAL THEN `,` ) }{ ls_item-key }|.
        ENDLOOP.
        fit  = highlight.
        info = COND #( WHEN highlight IS INITIAL
                       THEN `No lane is above 90 %.`
                       ELSE `Lanes above 90 % - the plan flew to them.` ).

      WHEN `ALL`.
        CLEAR highlight.
        CLEAR fit.
        info = `The whole plan.`.

      WHEN `COUNT`.
        round = round + 1.
        lanes_fill( ).
        CLEAR highlight.
        info = |Stock taking { round } - the viewport stayed where it was.|.

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    " plan units are metres: a lane is 2.7 m wide and 12 m deep, with 0.3 m
    " between two lanes and an 8 m aisle between the two blocks of a hall
    t_area = VALUE #(
      ( key = `H1` x = 0  y = 0 width = 84 height = 36 title = `Hall 1` )
      ( key = `H2` x = 90 y = 0 width = 78 height = 36 title = `Hall 2` ) ).

    CLEAR t_item.
    DO 4 TIMES.
      DATA(lv_block) = sy-index.
      " blocks 1 and 2 are hall 1 with 27 lanes each, 3 and 4 hall 2 with 25
      DATA(lv_lanes) = COND i( WHEN lv_block <= 2 THEN 27 ELSE 25 ).
      DATA(lv_left)  = COND i( WHEN lv_block <= 2 THEN 2 ELSE 92 ).
      DATA(lv_top)   = COND i( WHEN lv_block MOD 2 = 1 THEN 2 ELSE 22 ).

      DO lv_lanes TIMES.
        DATA(lv_number) = lv_block * 1000 + sy-index.
        INSERT VALUE #( key    = |{ lv_number }|
                        title  = |{ lv_number }|
                        x      = lv_left + ( sy-index - 1 ) * 3
                        y      = lv_top
                        width  = '2.7'
                        height = 12
                        " the upper block fills from the wall towards the
                        " aisle, the lower one the other way round
                        dir    = COND #( WHEN lv_block MOD 2 = 1
                                         THEN z2ui5_cl_cci_floor_plan=>cs_dir-down
                                         ELSE z2ui5_cl_cci_floor_plan=>cs_dir-up ) )
               INTO TABLE t_item.
      ENDDO.
    ENDDO.

    lanes_fill( ).

    info = `Zoom in to read the lanes, click one to select it.`.

  ENDMETHOD.

  METHOD lanes_fill.

    " no random numbers: the same picture on every system, and a new one
    " with every stock taking
    LOOP AT t_item ASSIGNING FIELD-SYMBOL(<item>).

      DATA(lv_seed)    = ( sy-tabix * 37 + round * 53 ) MOD 101.
      DATA(lv_percent) = COND i( WHEN lv_seed MOD 9 = 0 THEN 0 ELSE lv_seed ).

      <item>-fill    = lv_percent / 100.
      <item>-blocked = xsdbool( sy-tabix MOD 23 = 0 ).
      <item>-state   = COND #( WHEN lv_percent = 0  THEN z2ui5_cl_cci_floor_plan=>cs_state-none
                               WHEN lv_percent > 90 THEN z2ui5_cl_cci_floor_plan=>cs_state-error
                               WHEN lv_percent > 70 THEN z2ui5_cl_cci_floor_plan=>cs_state-warning
                               ELSE z2ui5_cl_cci_floor_plan=>cs_state-success ).
      <item>-text    = COND #( WHEN lv_percent = 0
                               THEN `empty`
                               ELSE |Board { 8 + ( sy-tabix MOD 6 ) * 3 } mm| ).
      <item>-info    = COND #( WHEN <item>-blocked = abap_true
                               THEN `blocked`
                               ELSE |{ lv_percent } %| ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
