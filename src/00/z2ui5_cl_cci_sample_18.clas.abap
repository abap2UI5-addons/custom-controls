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
                  v = `abap2UI5 - FloorPlan` ).


    box = page->ele( `VBox`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).


    bar = box->ele( `HBox`
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
        DATA lv_key TYPE string.
          DATA temp1 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item.
          DATA temp2 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item.
          DATA ls_item LIKE temp1.
          DATA temp3 TYPE string.
        DATA temp4 TYPE string.

    CASE client->get( )-event.

      WHEN `LANE`.
        " selected already carries what the CONTROL wrote into the model

        lv_key = client->get_event_arg( ).
        IF selected IS INITIAL.
          info = `Nothing selected.`.
        ELSE.

          CLEAR temp1.

          READ TABLE t_item INTO temp2 WITH KEY key = lv_key.
          IF sy-subrc = 0.
            temp1 = temp2.
          ENDIF.

          ls_item = temp1.
          info = |Lane { ls_item-title }: { ls_item-text }, { ls_item-info }|.
        ENDIF.

      WHEN `FULL`.
        CLEAR highlight.
        LOOP AT t_item INTO ls_item WHERE fill > '0.9'.

          IF highlight IS NOT INITIAL.
            temp3 = `,`.
          ELSE.
            CLEAR temp3.
          ENDIF.
          highlight = |{ highlight }{ temp3 }{ ls_item-key }|.
        ENDLOOP.
        fit  = highlight.

        IF highlight IS INITIAL.
          temp4 = `No lane is above 90 %.`.
        ELSE.
          temp4 = `Lanes above 90 % - the plan flew to them.`.
        ENDIF.
        info = temp4.

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
    DATA temp5 TYPE z2ui5_cl_cci_floor_plan=>ty_t_area.
    DATA temp6 LIKE LINE OF temp5.
      DATA lv_block LIKE sy-index.
      DATA temp7 TYPE i.
      DATA lv_lanes LIKE temp7.
      DATA temp8 TYPE i.
      DATA lv_left LIKE temp8.
      DATA temp9 TYPE i.
      DATA lv_top LIKE temp9.
        DATA lv_number TYPE i.
        DATA temp10 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item.
        DATA temp1 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item-dir.
    CLEAR temp5.

    temp6-key = `H1`.
    temp6-x = 0.
    temp6-y = 0.
    temp6-width = 84.
    temp6-height = 36.
    temp6-title = `Hall 1`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `H2`.
    temp6-x = 90.
    temp6-y = 0.
    temp6-width = 78.
    temp6-height = 36.
    temp6-title = `Hall 2`.
    INSERT temp6 INTO TABLE temp5.
    t_area = temp5.

    CLEAR t_item.
    DO 4 TIMES.

      lv_block = sy-index.
      " blocks 1 and 2 are hall 1 with 27 lanes each, 3 and 4 hall 2 with 25

      IF lv_block <= 2.
        temp7 = 27.
      ELSE.
        temp7 = 25.
      ENDIF.

      lv_lanes = temp7.

      IF lv_block <= 2.
        temp8 = 2.
      ELSE.
        temp8 = 92.
      ENDIF.

      lv_left = temp8.

      IF lv_block MOD 2 = 1.
        temp9 = 2.
      ELSE.
        temp9 = 22.
      ENDIF.

      lv_top = temp9.

      DO lv_lanes TIMES.

        lv_number = lv_block * 1000 + sy-index.

        CLEAR temp10.
        temp10-key = |{ lv_number }|.
        temp10-title = |{ lv_number }|.
        temp10-x = lv_left + ( sy-index - 1 ) * 3.
        temp10-y = lv_top.
        temp10-width = '2.7'.
        temp10-height = 12.

        IF lv_block MOD 2 = 1.
          temp1 = z2ui5_cl_cci_floor_plan=>cs_dir-down.
        ELSE.
          temp1 = z2ui5_cl_cci_floor_plan=>cs_dir-up.
        ENDIF.
        temp10-dir = temp1.
        INSERT temp10
               INTO TABLE t_item.
      ENDDO.
    ENDDO.

    lanes_fill( ).

    info = `Zoom in to read the lanes, click one to select it.`.

  ENDMETHOD.

  METHOD lanes_fill.

    " no random numbers: the same picture on every system, and a new one
    " with every stock taking
    FIELD-SYMBOLS <item> LIKE LINE OF t_item.
      DATA lv_seed TYPE i.
      DATA temp11 TYPE i.
      DATA lv_percent LIKE temp11.
      DATA temp1 TYPE xsdboolean.
      DATA temp12 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item-state.
      DATA temp13 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item-text.
      DATA temp14 TYPE z2ui5_cl_cci_floor_plan=>ty_s_item-info.
    LOOP AT t_item ASSIGNING <item>.


      lv_seed    = ( sy-tabix * 37 + round * 53 ) MOD 101.

      IF lv_seed MOD 9 = 0.
        temp11 = 0.
      ELSE.
        temp11 = lv_seed.
      ENDIF.

      lv_percent = temp11.

      <item>-fill    = lv_percent / 100.

      temp1 = boolc( sy-tabix MOD 23 = 0 ).
      <item>-blocked = temp1.

      IF lv_percent = 0.
        temp12 = z2ui5_cl_cci_floor_plan=>cs_state-none.
      ELSEIF lv_percent > 90.
        temp12 = z2ui5_cl_cci_floor_plan=>cs_state-error.
      ELSEIF lv_percent > 70.
        temp12 = z2ui5_cl_cci_floor_plan=>cs_state-warning.
      ELSE.
        temp12 = z2ui5_cl_cci_floor_plan=>cs_state-success.
      ENDIF.
      <item>-state   = temp12.

      IF lv_percent = 0.
        temp13 = `empty`.
      ELSE.
        temp13 = |Board { 8 + ( sy-tabix MOD 6 ) * 3 } mm|.
      ENDIF.
      <item>-text    = temp13.

      IF <item>-blocked = abap_true.
        temp14 = `blocked`.
      ELSE.
        temp14 = |{ lv_percent } %|.
      ENDIF.
      <item>-info    = temp14.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
