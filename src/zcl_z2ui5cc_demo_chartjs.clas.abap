"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Chart.js</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_chartjs</em>
"!
"! Seven charts built from plain ABAP structures - bar, line, pie, doughnut,
"! bubble, venn and word cloud - in a carousel. Nothing here is JavaScript:
"! every chart is a ty_chart structure bound to the control.
"!
"! <em>Update data</em> changes the structures in ABAP and calls
"! view_model_update( ); the charts animate to the new values instead of being
"! rebuilt. Clicking into a chart fires an event back to this class, which the
"! toast at the bottom of the screen reports.
"!
"! The venn and word cloud pages need the matching plugins, which the control
"! loads because they are listed in `plugins`.
CLASS zcl_z2ui5cc_demo_chartjs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA s_bar       TYPE zcl_z2ui5cc_chartjs=>ty_chart.
    DATA s_line      TYPE zcl_z2ui5cc_chartjs=>ty_chart.
    DATA s_pie       TYPE zcl_z2ui5cc_chartjs=>ty_chart.
    DATA s_doughnut  TYPE zcl_z2ui5cc_chartjs=>ty_chart.
    DATA s_bubble    TYPE zcl_z2ui5cc_chartjs=>ty_chart.
    DATA s_venn      TYPE zcl_z2ui5cc_chartjs=>ty_chart.
    DATA s_wordcloud TYPE zcl_z2ui5cc_chartjs=>ty_chart.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    "! counts the presses, so each update is visibly a different one
    DATA mv_run TYPE i.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS model_update.
    "! move the first value of a dataset to the end
    METHODS rotate
      CHANGING
        val TYPE string_table.

    "! one chart, with the bind and the plugin list every page here needs
    METHODS chart
      IMPORTING
        view    TYPE REF TO z2ui5_cl_ai_xml
        config  TYPE string
        title   TYPE string
        plugins TYPE string OPTIONAL.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_chartjs IMPLEMENTATION.

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

  METHOD chart.

    DATA(box) = view->open( `VBox`
                    )->a( n = `class`
                          v = `sapUiSmallMargin`
                    )->leaf( `Title`
                        )->a( n = `text`
                              v = title
                        )->a( n = `level`
                              v = `H4` ).

    zcl_z2ui5cc_chartjs=>render(
        view         = box
        config       = config
        plugins      = plugins
        width        = `420px`
        height       = `280px`
        elementpress = client->_event( `ELEMENT` ) ).

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
                  v = `abap2UI5 - Chart.js`
            )->a( n = `enableScrolling`
                  v = `false` ).

    page->open( `headerContent`
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Update data`
            )->a( n = `press`
                  v = client->_event( `UPDATE` ) ).

    DATA(carousel) = page->open( `Carousel` ).

    " page 1 - the everyday chart types
    DATA(first) = carousel->open( `VBox` ).
    DATA(row1) = first->open( `HBox`
                     )->a( n = `wrap`
                           v = `Wrap` ).
    chart( view   = row1
           title  = `bar`
           config = client->_bind( val           = s_bar
                                   custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view   = row1
           title  = `line`
           config = client->_bind( val           = s_line
                                   custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view   = row1
           title  = `pie`
           config = client->_bind( val           = s_pie
                                   custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view   = row1
           title  = `doughnut`
           config = client->_bind( val           = s_doughnut
                                   custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).

    " page 2 - the types that need a plugin
    DATA(second) = carousel->open( `VBox` ).
    DATA(row2) = second->open( `HBox`
                     )->a( n = `wrap`
                           v = `Wrap` ).
    chart( view   = row2
           title  = `bubble`
           config = client->_bind( val           = s_bubble
                                   custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view    = row2
           title   = `venn (plugin)`
           plugins = zcl_z2ui5cc_chartjs=>cs_plugin-venn
           config  = client->_bind( val           = s_venn
                                    custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                        iv_first_json_upper = abap_false ) ) ).
    chart( view    = row2
           title   = `word cloud (plugin)`
           plugins = zcl_z2ui5cc_chartjs=>cs_plugin-wordcloud
           config  = client->_bind( val           = s_wordcloud
                                    custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                        iv_first_json_upper = abap_false ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `UPDATE`.
        model_update( ).
        client->view_model_update( ).

      WHEN `ELEMENT`.
        client->message_toast_display( `Chart element clicked - the press event ` &&
                                       `reached ABAP.` ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    DATA ls_dataset TYPE zcl_z2ui5cc_chartjs=>ty_dataset.

    " bar
    s_bar-type = `bar`.
    s_bar-data-labels = VALUE #( ( `Red` ) ( `Blue` ) ( `Yellow` )
                                 ( `Green` ) ( `Purple` ) ( `Orange` ) ).
    ls_dataset-label = `# of votes`.
    ls_dataset-border_width = 1.
    ls_dataset-data = VALUE #( ( `12` ) ( `19` ) ( `3` ) ( `5` ) ( `2` ) ( `3` ) ).
    APPEND ls_dataset TO s_bar-data-datasets.
    s_bar-options-scales-y-begin_at_zero = abap_true.
    s_bar-options-plugins-title-display = abap_true.
    s_bar-options-plugins-title-text = `Votes per colour`.

    " line
    CLEAR ls_dataset.
    s_line-type = `line`.
    s_line-data-labels = VALUE #( ( `Jan` ) ( `Feb` ) ( `Mar` ) ( `Apr` )
                                  ( `May` ) ( `Jun` ) ( `Jul` ) ).
    ls_dataset-label = `Dataset 1`.
    ls_dataset-tension = `0.4`.
    ls_dataset-data = VALUE #( ( `65` ) ( `59` ) ( `80` ) ( `81` )
                               ( `56` ) ( `55` ) ( `40` ) ).
    APPEND ls_dataset TO s_line-data-datasets.
    CLEAR ls_dataset.
    ls_dataset-label = `Dataset 2`.
    ls_dataset-tension = `0.4`.
    ls_dataset-data = VALUE #( ( `100` ) ( `33` ) ( `22` ) ( `19` )
                               ( `11` ) ( `49` ) ( `30` ) ).
    APPEND ls_dataset TO s_line-data-datasets.
    s_line-options-responsive = abap_true.

    " pie
    CLEAR ls_dataset.
    s_pie-type = `pie`.
    s_pie-data-labels = VALUE #( ( `Red` ) ( `Orange` ) ( `Yellow` )
                                 ( `Green` ) ( `Blue` ) ).
    ls_dataset-label = `Share`.
    ls_dataset-data = VALUE #( ( `63.4` ) ( `47.8` ) ( `50.6` ) ( `21.3` ) ( `38.7` ) ).
    APPEND ls_dataset TO s_pie-data-datasets.
    s_pie-options-plugins-legend-position = `bottom`.

    " doughnut - same data, different type
    s_doughnut = s_pie.
    s_doughnut-type = `doughnut`.

    " bubble - x/y/r per point, which is why ty_dataset has data_radial
    CLEAR ls_dataset.
    s_bubble-type = `bubble`.
    ls_dataset-label = `Dataset 1`.
    ls_dataset-data_radial = VALUE #( ( x = `26` y = `79` r = `12.3` )
                                      ( x = `37` y = `65` r = `13.8` )
                                      ( x = `27` y = `24` r = `5.8` )
                                      ( x = `47` y = `36` r = `8.4` )
                                      ( x = `77` y = `65` r = `9.5` ) ).
    APPEND ls_dataset TO s_bubble-data-datasets.
    s_bubble-options-responsive = abap_true.

    " venn - one set list per point, which is why ty_dataset has data_venn
    CLEAR ls_dataset.
    s_venn-type = `venn`.
    s_venn-data-labels = VALUE #( ( `Soccer` )
                                  ( `Tennis` )
                                  ( `Volleyball` )
                                  ( `Soccer + Tennis` )
                                  ( `Soccer + Volleyball` )
                                  ( `Tennis + Volleyball` )
                                  ( `all three` ) ).
    ls_dataset-label = `Sports`.
    ls_dataset-data_venn = VALUE #(
        ( sets = VALUE #( ( `Soccer` ) )                               value = `2` )
        ( sets = VALUE #( ( `Tennis` ) )                               value = `1` )
        ( sets = VALUE #( ( `Volleyball` ) )                           value = `1` )
        ( sets = VALUE #( ( `Soccer` ) ( `Tennis` ) )                  value = `1` )
        ( sets = VALUE #( ( `Soccer` ) ( `Volleyball` ) )              value = `1` )
        ( sets = VALUE #( ( `Tennis` ) ( `Volleyball` ) )              value = `1` )
        ( sets = VALUE #( ( `Soccer` ) ( `Tennis` ) ( `Volleyball` ) ) value = `1` ) ).
    APPEND ls_dataset TO s_venn-data-datasets.

    " word cloud
    CLEAR ls_dataset.
    s_wordcloud-type = `wordCloud`.
    s_wordcloud-data-labels = VALUE #( ( `abap2UI5` ) ( `custom` ) ( `control` )
                                       ( `BSP` ) ( `chart` ) ( `ABAP` ) ( `UI5` ) ).
    ls_dataset-label = `size`.
    ls_dataset-data = VALUE #( ( `90` ) ( `70` ) ( `60` ) ( `50` )
                               ( `40` ) ( `30` ) ( `20` ) ).
    APPEND ls_dataset TO s_wordcloud-data-datasets.

  ENDMETHOD.

  METHOD model_update.

    " Changing the bound structures is enough - the control updates the live
    " charts instead of rebuilding them.
    "
    " Every press has to produce GENUINELY different data, though. Writing the
    " same alternative values again would leave the model unchanged, the
    " property binding would correctly not fire, and the charts would sit
    " still from the second press on - which looks like a broken control but
    " is the binding doing its job. So the datasets are rotated.
    mv_run = mv_run + 1.

    FIELD-SYMBOLS <ds> TYPE zcl_z2ui5cc_chartjs=>ty_dataset.
    LOOP AT s_bar-data-datasets ASSIGNING <ds>.
      rotate( CHANGING val = <ds>-data ).
    ENDLOOP.

    LOOP AT s_line-data-datasets ASSIGNING <ds>.
      rotate( CHANGING val = <ds>-data ).
    ENDLOOP.

    LOOP AT s_pie-data-datasets ASSIGNING <ds>.
      rotate( CHANGING val = <ds>-data ).
    ENDLOOP.

    " the doughnut shares the pie's data on purpose - see model_init( )
    s_doughnut = s_pie.
    s_doughnut-type = `doughnut`.

    LOOP AT s_wordcloud-data-datasets ASSIGNING <ds>.
      rotate( CHANGING val = <ds>-data ).
    ENDLOOP.

    " The bubble chart carries x/y/r points and the venn chart a set list per
    " entry, so neither uses the plain `data` table the others rotate - they
    " need their own shift, or the second carousel page would sit still while
    " the first one updates.
    DATA ls_point TYPE zcl_z2ui5cc_chartjs=>ty_x_y_r_data.
    LOOP AT s_bubble-data-datasets ASSIGNING <ds>.
      IF lines( <ds>-data_radial ) >= 2.
        ls_point = <ds>-data_radial[ 1 ].
        DELETE <ds>-data_radial INDEX 1.
        APPEND ls_point TO <ds>-data_radial.
      ENDIF.
    ENDLOOP.

    " rotate the values across the sets, so the circles resize while the sets
    " themselves stay where they are
    DATA lv_value TYPE string.
    DATA lv_last  TYPE i.
    LOOP AT s_venn-data-datasets ASSIGNING <ds>.
      lv_last = lines( <ds>-data_venn ).
      IF lv_last >= 2.
        lv_value = <ds>-data_venn[ 1 ]-value.
        DO lv_last - 1 TIMES.
          <ds>-data_venn[ sy-index ]-value = <ds>-data_venn[ sy-index + 1 ]-value.
        ENDDO.
        <ds>-data_venn[ lv_last ]-value = lv_value.
      ENDIF.
    ENDLOOP.

    s_bar-options-plugins-title-text = |Votes per colour (update { mv_run })|.

  ENDMETHOD.

  METHOD rotate.

    " first value to the end - small, visible, and different every time
    IF lines( val ) < 2.
      RETURN.
    ENDIF.

    DATA(lv_first) = val[ 1 ].
    DELETE val INDEX 1.
    APPEND lv_first TO val.

  ENDMETHOD.

ENDCLASS.
