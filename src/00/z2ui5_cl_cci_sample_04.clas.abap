"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Chart.js</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_04</em>
"!
"! Seven charts built from plain ABAP structures - bar, line, pie, doughnut,
"! bubble, venn and word cloud - in a carousel. Nothing here is JavaScript:
"! every chart is a ty_chart structure bound to the control.
"!
"! <em>Update data</em> changes the structures in ABAP; the framework pushes
"! the changed model on its own and the charts animate to the new values
"! instead of being rebuilt. Clicking into a chart fires an event back to this
"! class, which the toast at the bottom of the screen reports.
"!
"! The venn and word cloud pages need the matching plugins, which the control
"! loads because they are listed in `plugins`.
CLASS z2ui5_cl_cci_sample_04 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA s_bar       TYPE z2ui5_cl_cci_chartjs=>ty_chart.
    DATA s_line      TYPE z2ui5_cl_cci_chartjs=>ty_chart.
    DATA s_pie       TYPE z2ui5_cl_cci_chartjs=>ty_chart.
    DATA s_doughnut  TYPE z2ui5_cl_cci_chartjs=>ty_chart.
    DATA s_bubble    TYPE z2ui5_cl_cci_chartjs=>ty_chart.
    DATA s_venn      TYPE z2ui5_cl_cci_chartjs=>ty_chart.
    DATA s_wordcloud TYPE z2ui5_cl_cci_chartjs=>ty_chart.

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
        view    TYPE REF TO z2ui5_cl_ui5_view_builder
        config  TYPE string
        title   TYPE string
        plugins TYPE string OPTIONAL.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_04 IMPLEMENTATION.

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

  METHOD chart.

    DATA box TYPE REF TO z2ui5_cl_ui5_view_builder.
    box = view->ele( `VBox`
                    )->a( n = `class`
                          v = `sapUiSmallMargin`
                    )->tag( `Title`
                        )->a( n = `text`
                              v = title
                        )->a( n = `level`
                              v = `H4` ).

    z2ui5_cl_cci_chartjs=>render(
        view         = box
        config       = config
        plugins      = plugins
        width        = `420px`
        height       = `280px`
        elementpress = client->_event( `ELEMENT` ) ).

  ENDMETHOD.

  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA carousel TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA first TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA row1 TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA second TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA row2 TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).


    page = view->ele( n  = `View`
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
                  v = `abap2UI5 - Chart.js`
            )->a( n = `enableScrolling`
                  v = `false` ).

    page->ele( `headerContent`
        )->tag( `Button`
            )->a( n = `text`
                  v = `Update data`
            )->a( n = `press`
                  v = client->_event( `UPDATE` ) ).


    carousel = page->ele( `Carousel` ).

    " page 1 - the everyday chart types

    first = carousel->ele( `VBox` ).

    row1 = first->ele( `HBox`
                     )->a( n = `wrap`
                           v = `Wrap` ).
    chart( view   = row1
           title  = `bar`
           config = client->_bind( val           = s_bar
                                   omit_initial  = abap_true
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view   = row1
           title  = `line`
           config = client->_bind( val           = s_line
                                   omit_initial  = abap_true
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view   = row1
           title  = `pie`
           config = client->_bind( val           = s_pie
                                   omit_initial  = abap_true
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view   = row1
           title  = `doughnut`
           config = client->_bind( val           = s_doughnut
                                   omit_initial  = abap_true
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).

    " page 2 - the types that need a plugin

    second = carousel->ele( `VBox` ).

    row2 = second->ele( `HBox`
                     )->a( n = `wrap`
                           v = `Wrap` ).
    chart( view   = row2
           title  = `bubble`
           config = client->_bind( val           = s_bubble
                                   omit_initial  = abap_true
                                   custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                       iv_first_json_upper = abap_false ) ) ).
    chart( view    = row2
           title   = `venn (plugin)`
           plugins = z2ui5_cl_cci_chartjs=>cs_plugin-venn
           config  = client->_bind( val           = s_venn
                                    omit_initial  = abap_true
                                    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                        iv_first_json_upper = abap_false ) ) ).
    chart( view    = row2
           title   = `word cloud (plugin)`
           plugins = z2ui5_cl_cci_chartjs=>cs_plugin-wordcloud
           config  = client->_bind( val           = s_wordcloud
                                    omit_initial  = abap_true
                                    custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                        iv_first_json_upper = abap_false ) ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `UPDATE`.
        model_update( ).

      WHEN `ELEMENT`.
        client->message_toast_display( `Chart element clicked - the press event ` &&
                                       `reached ABAP.` ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    DATA ls_dataset TYPE z2ui5_cl_cci_chartjs=>ty_dataset.
    DATA temp1 TYPE string_table.
    DATA temp3 TYPE string_table.
    DATA temp5 TYPE string_table.
    DATA temp7 TYPE string_table.
    DATA temp9 TYPE string_table.
    DATA temp11 TYPE string_table.
    DATA temp13 TYPE string_table.
    DATA temp15 TYPE z2ui5_cl_cci_chartjs=>ty_x_y_r_data_t.
    DATA temp16 LIKE LINE OF temp15.
    DATA temp17 TYPE string_table.
    DATA temp19 TYPE z2ui5_cl_cci_chartjs=>ty_data_venn_t.
    DATA temp20 LIKE LINE OF temp19.
    DATA temp2 TYPE string_table.
    DATA temp6 TYPE string_table.
    DATA temp10 TYPE string_table.
    DATA temp14 TYPE string_table.
    DATA temp22 TYPE string_table.
    DATA temp25 TYPE string_table.
    DATA temp27 TYPE string_table.
    DATA temp21 TYPE string_table.
    DATA temp23 TYPE string_table.

    " bar
    s_bar-type = `bar`.

    CLEAR temp1.
    INSERT `Red` INTO TABLE temp1.
    INSERT `Blue` INTO TABLE temp1.
    INSERT `Yellow` INTO TABLE temp1.
    INSERT `Green` INTO TABLE temp1.
    INSERT `Purple` INTO TABLE temp1.
    INSERT `Orange` INTO TABLE temp1.
    s_bar-data-labels = temp1.
    ls_dataset-label = `# of votes`.
    ls_dataset-border_width = 1.

    CLEAR temp3.
    INSERT `12` INTO TABLE temp3.
    INSERT `19` INTO TABLE temp3.
    INSERT `3` INTO TABLE temp3.
    INSERT `5` INTO TABLE temp3.
    INSERT `2` INTO TABLE temp3.
    INSERT `3` INTO TABLE temp3.
    ls_dataset-data = temp3.
    APPEND ls_dataset TO s_bar-data-datasets.
    s_bar-options-scales-y-begin_at_zero = abap_true.
    s_bar-options-plugins-title-display = abap_true.
    s_bar-options-plugins-title-text = `Votes per colour`.

    " line
    CLEAR ls_dataset.
    s_line-type = `line`.

    CLEAR temp5.
    INSERT `Jan` INTO TABLE temp5.
    INSERT `Feb` INTO TABLE temp5.
    INSERT `Mar` INTO TABLE temp5.
    INSERT `Apr` INTO TABLE temp5.
    INSERT `May` INTO TABLE temp5.
    INSERT `Jun` INTO TABLE temp5.
    INSERT `Jul` INTO TABLE temp5.
    s_line-data-labels = temp5.
    ls_dataset-label = `Dataset 1`.
    ls_dataset-tension = `0.4`.

    CLEAR temp7.
    INSERT `65` INTO TABLE temp7.
    INSERT `59` INTO TABLE temp7.
    INSERT `80` INTO TABLE temp7.
    INSERT `81` INTO TABLE temp7.
    INSERT `56` INTO TABLE temp7.
    INSERT `55` INTO TABLE temp7.
    INSERT `40` INTO TABLE temp7.
    ls_dataset-data = temp7.
    APPEND ls_dataset TO s_line-data-datasets.
    CLEAR ls_dataset.
    ls_dataset-label = `Dataset 2`.
    ls_dataset-tension = `0.4`.

    CLEAR temp9.
    INSERT `100` INTO TABLE temp9.
    INSERT `33` INTO TABLE temp9.
    INSERT `22` INTO TABLE temp9.
    INSERT `19` INTO TABLE temp9.
    INSERT `11` INTO TABLE temp9.
    INSERT `49` INTO TABLE temp9.
    INSERT `30` INTO TABLE temp9.
    ls_dataset-data = temp9.
    APPEND ls_dataset TO s_line-data-datasets.
    s_line-options-responsive = abap_true.

    " pie
    CLEAR ls_dataset.
    s_pie-type = `pie`.

    CLEAR temp11.
    INSERT `Red` INTO TABLE temp11.
    INSERT `Orange` INTO TABLE temp11.
    INSERT `Yellow` INTO TABLE temp11.
    INSERT `Green` INTO TABLE temp11.
    INSERT `Blue` INTO TABLE temp11.
    s_pie-data-labels = temp11.
    ls_dataset-label = `Share`.

    CLEAR temp13.
    INSERT `63.4` INTO TABLE temp13.
    INSERT `47.8` INTO TABLE temp13.
    INSERT `50.6` INTO TABLE temp13.
    INSERT `21.3` INTO TABLE temp13.
    INSERT `38.7` INTO TABLE temp13.
    ls_dataset-data = temp13.
    APPEND ls_dataset TO s_pie-data-datasets.
    s_pie-options-plugins-legend-position = `bottom`.

    " doughnut - same data, different type
    s_doughnut = s_pie.
    s_doughnut-type = `doughnut`.

    " bubble - x/y/r per point, which is why ty_dataset has data_radial
    CLEAR ls_dataset.
    s_bubble-type = `bubble`.
    ls_dataset-label = `Dataset 1`.

    CLEAR temp15.

    temp16-x = `26`.
    temp16-y = `79`.
    temp16-r = `12.3`.
    INSERT temp16 INTO TABLE temp15.
    temp16-x = `37`.
    temp16-y = `65`.
    temp16-r = `13.8`.
    INSERT temp16 INTO TABLE temp15.
    temp16-x = `27`.
    temp16-y = `24`.
    temp16-r = `5.8`.
    INSERT temp16 INTO TABLE temp15.
    temp16-x = `47`.
    temp16-y = `36`.
    temp16-r = `8.4`.
    INSERT temp16 INTO TABLE temp15.
    temp16-x = `77`.
    temp16-y = `65`.
    temp16-r = `9.5`.
    INSERT temp16 INTO TABLE temp15.
    ls_dataset-data_radial = temp15.
    APPEND ls_dataset TO s_bubble-data-datasets.
    s_bubble-options-responsive = abap_true.

    " venn - one set list per point, which is why ty_dataset has data_venn
    CLEAR ls_dataset.
    s_venn-type = `venn`.

    CLEAR temp17.
    INSERT `Soccer` INTO TABLE temp17.
    INSERT `Tennis` INTO TABLE temp17.
    INSERT `Volleyball` INTO TABLE temp17.
    INSERT `Soccer + Tennis` INTO TABLE temp17.
    INSERT `Soccer + Volleyball` INTO TABLE temp17.
    INSERT `Tennis + Volleyball` INTO TABLE temp17.
    INSERT `all three` INTO TABLE temp17.
    s_venn-data-labels = temp17.
    ls_dataset-label = `Sports`.

    CLEAR temp19.


    CLEAR temp2.
    INSERT `Soccer` INTO TABLE temp2.
    temp20-sets = temp2.
    temp20-value = `2`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp6.
    INSERT `Tennis` INTO TABLE temp6.
    temp20-sets = temp6.
    temp20-value = `1`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp10.
    INSERT `Volleyball` INTO TABLE temp10.
    temp20-sets = temp10.
    temp20-value = `1`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp14.
    INSERT `Soccer` INTO TABLE temp14.
    INSERT `Tennis` INTO TABLE temp14.
    temp20-sets = temp14.
    temp20-value = `1`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp22.
    INSERT `Soccer` INTO TABLE temp22.
    INSERT `Volleyball` INTO TABLE temp22.
    temp20-sets = temp22.
    temp20-value = `1`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp25.
    INSERT `Tennis` INTO TABLE temp25.
    INSERT `Volleyball` INTO TABLE temp25.
    temp20-sets = temp25.
    temp20-value = `1`.
    INSERT temp20 INTO TABLE temp19.

    CLEAR temp27.
    INSERT `Soccer` INTO TABLE temp27.
    INSERT `Tennis` INTO TABLE temp27.
    INSERT `Volleyball` INTO TABLE temp27.
    temp20-sets = temp27.
    temp20-value = `1`.
    INSERT temp20 INTO TABLE temp19.
    ls_dataset-data_venn = temp19.
    APPEND ls_dataset TO s_venn-data-datasets.

    " word cloud
    CLEAR ls_dataset.
    s_wordcloud-type = `wordCloud`.

    CLEAR temp21.
    INSERT `abap2UI5` INTO TABLE temp21.
    INSERT `custom` INTO TABLE temp21.
    INSERT `control` INTO TABLE temp21.
    INSERT `BSP` INTO TABLE temp21.
    INSERT `chart` INTO TABLE temp21.
    INSERT `ABAP` INTO TABLE temp21.
    INSERT `UI5` INTO TABLE temp21.
    s_wordcloud-data-labels = temp21.
    ls_dataset-label = `size`.

    CLEAR temp23.
    INSERT `90` INTO TABLE temp23.
    INSERT `70` INTO TABLE temp23.
    INSERT `60` INTO TABLE temp23.
    INSERT `50` INTO TABLE temp23.
    INSERT `40` INTO TABLE temp23.
    INSERT `30` INTO TABLE temp23.
    INSERT `20` INTO TABLE temp23.
    ls_dataset-data = temp23.
    APPEND ls_dataset TO s_wordcloud-data-datasets.

  ENDMETHOD.

  METHOD model_update.
    FIELD-SYMBOLS <ds> TYPE z2ui5_cl_cci_chartjs=>ty_dataset.
    DATA ls_point TYPE z2ui5_cl_cci_chartjs=>ty_x_y_r_data.
        FIELD-SYMBOLS <temp25> LIKE LINE OF <ds>-data_radial.
        DATA temp26 LIKE sy-tabix.
    DATA lv_value TYPE string.
    DATA lv_last TYPE i.
        FIELD-SYMBOLS <temp27> LIKE LINE OF <ds>-data_venn.
        DATA temp28 LIKE sy-tabix.
          FIELD-SYMBOLS <temp29> LIKE LINE OF <ds>-data_venn.
          DATA temp30 LIKE sy-tabix.
          FIELD-SYMBOLS <temp30> LIKE LINE OF <ds>-data_venn.
          DATA temp31 LIKE sy-tabix.
        FIELD-SYMBOLS <temp31> LIKE LINE OF <ds>-data_venn.
        DATA temp32 LIKE sy-tabix.

    " Changing the bound structures is enough - the control updates the live
    " charts instead of rebuilding them.
    "
    " Every press has to produce GENUINELY different data, though. Writing the
    " same alternative values again would leave the model unchanged, the
    " property binding would correctly not fire, and the charts would sit
    " still from the second press on - which looks like a broken control but
    " is the binding doing its job. So the datasets are rotated.
    mv_run = mv_run + 1.


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

    LOOP AT s_bubble-data-datasets ASSIGNING <ds>.
      IF lines( <ds>-data_radial ) >= 2.


        temp26 = sy-tabix.
        READ TABLE <ds>-data_radial INDEX 1 ASSIGNING <temp25>.
        sy-tabix = temp26.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        ls_point = <temp25>.
        DELETE <ds>-data_radial INDEX 1.
        APPEND ls_point TO <ds>-data_radial.
      ENDIF.
    ENDLOOP.

    " rotate the values across the sets, so the circles resize while the sets
    " themselves stay where they are


    LOOP AT s_venn-data-datasets ASSIGNING <ds>.
      lv_last = lines( <ds>-data_venn ).
      IF lv_last >= 2.


        temp28 = sy-tabix.
        READ TABLE <ds>-data_venn INDEX 1 ASSIGNING <temp27>.
        sy-tabix = temp28.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        lv_value = <temp27>-value.
        DO lv_last - 1 TIMES.


          temp30 = sy-tabix.
          READ TABLE <ds>-data_venn INDEX sy-index ASSIGNING <temp29>.
          sy-tabix = temp30.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp31 = sy-tabix.
          READ TABLE <ds>-data_venn INDEX sy-index + 1 ASSIGNING <temp30>.
          sy-tabix = temp31.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp29>-value = <temp30>-value.
        ENDDO.


        temp32 = sy-tabix.
        READ TABLE <ds>-data_venn INDEX lv_last ASSIGNING <temp31>.
        sy-tabix = temp32.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp31>-value = lv_value.
      ENDIF.
    ENDLOOP.

    s_bar-options-plugins-title-text = |Votes per colour (update { mv_run })|.

  ENDMETHOD.

  METHOD rotate.
    DATA lv_first LIKE LINE OF val.
    FIELD-SYMBOLS <temp32> LIKE LINE OF val.
    DATA temp33 LIKE sy-tabix.

    " first value to the end - small, visible, and different every time
    IF lines( val ) < 2.
      RETURN.
    ENDIF.




    temp33 = sy-tabix.
    READ TABLE val INDEX 1 ASSIGNING <temp32>.
    sy-tabix = temp33.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_first = <temp32>.
    DELETE val INDEX 1.
    APPEND lv_first TO val.

  ENDMETHOD.

ENDCLASS.
