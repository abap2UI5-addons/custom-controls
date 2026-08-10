"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Chart.js</p>
"!
"! The ABAP half of the z2ui5ccc.cc.ChartJs custom control: the view builder
"! that emits its XML element, plus the type tree of a Chart.js configuration.
"!
"! Fill a ty_chart structure, bind it to <em>config</em>, and the frontend
"! draws it. The structure mirrors the Chart.js configuration object one to
"! one, so the Chart.js documentation is the reference for what a field means -
"! neither this class nor the control interprets them.
"!
"! Bind it with the camelCase mapper and this library's JSON filter:
"!
"!   config = client->_bind(
"!       val           = ms_chart
"!       custom_filter = NEW z2ui5_cl_cci_json_filter( )
"!       custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
"!                           iv_first_json_upper = abap_false ) )
"!
"! Without the filter every field the app left alone would arrive as 0, ``` or
"! false and override the Chart.js default; without the mapper the field names
"! would stay snake_case and Chart.js would ignore all of them.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_chartjs). The type
"! tree is carried over unchanged, the JavaScript is now a real module in this
"! repository's BSP instead of a string built in ABAP.
CLASS z2ui5_cl_cci_chartjs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    " Data
    TYPES:
      BEGIN OF ty_x_y_r_data,
        x TYPE string,
        y TYPE string,
        r TYPE string,
      END OF ty_x_y_r_data.

    TYPES ty_x_y_r_data_t TYPE STANDARD TABLE OF ty_x_y_r_data WITH EMPTY KEY.
    TYPES ty_bg_color TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_padding,
        bottom TYPE string,
        top    TYPE string,
        left   TYPE string,
        right  TYPE string,
      END OF ty_padding .

    TYPES:
      BEGIN OF ty_font,
        size        TYPE i,
        family      TYPE string,
        weight      TYPE string,
        style       TYPE string,
        line_height TYPE string,
      END OF ty_font .

    TYPES:
      BEGIN OF ty_datalabels_lbl,
        color TYPE string,
        font  TYPE ty_font,
      END OF ty_datalabels_lbl .

    TYPES:
      BEGIN OF ty_datalabels_labels,
        title TYPE ty_datalabels_lbl,
        value TYPE ty_datalabels_lbl,
      END OF ty_datalabels_labels .

    TYPES:
      BEGIN OF ty_datalabels,
        align             TYPE string,
        anchor            TYPE string,
        background_color  TYPE string,
        border_color      TYPE string,
        border_radius     TYPE i,
        border_width      TYPE i,
        clamp             TYPE abap_bool,
        clip              TYPE abap_bool,
        color             TYPE string,
        display           TYPE abap_bool,
        font              TYPE ty_font,
        formatter         TYPE string,
        labels            TYPE ty_datalabels_labels,
        listeners         TYPE string,
        offset            TYPE i,
        opacity           TYPE i,
        padding           TYPE ty_padding,
        rotation          TYPE i,
        text_align        TYPE string,
        text_stroke_color TYPE string,
        text_stroke_width TYPE i,
        text_shadow_blur  TYPE i,
        text_shadow_color TYPE string,
      END OF ty_datalabels .

    TYPES:
      BEGIN OF ty_data_venn,
        sets   TYPE string_table,
        value  TYPE string,
        values TYPE string_table,
      END OF ty_data_venn .

    TYPES ty_data_venn_t TYPE STANDARD TABLE OF ty_data_venn WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_dataset,
        label              TYPE string,
        type               TYPE string,
        data               TYPE string_table,
        data_venn          TYPE ty_data_venn_t,
        data_radial        TYPE ty_x_y_r_data_t,
        border_width       TYPE i,
        border_color       TYPE string,
        border_radius      TYPE i,
        border_skipped     TYPE abap_bool,
        show_line          TYPE abap_bool,
        background_color_t TYPE ty_bg_color,
        background_color   TYPE string,
        hover_offset       TYPE i,
        order              TYPE i,
        fill               TYPE string,
        hidden             TYPE abap_bool,
        point_style        TYPE string,
        point_border_color TYPE string,
        point_radius       TYPE i,
        point_hover_radius TYPE i,
        rtl                TYPE abap_bool,
        datalabels         TYPE ty_datalabels,
        tension            TYPE string,
      END OF ty_dataset.

    TYPES ty_datasets TYPE STANDARD TABLE OF ty_dataset WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_data,
        labels   TYPE string_table,
        datasets TYPE ty_datasets,
      END OF ty_data .

    " Options
    TYPES:
      BEGIN OF ty_custom_canvas_bg_color,
        color TYPE string,
      END OF ty_custom_canvas_bg_color.

    TYPES:
      BEGIN OF ty_autocolors_plugin,
        enabled TYPE abap_bool,
        mode    TYPE string,
        offset  TYPE i,
        repeat  TYPE i,
      END OF ty_autocolors_plugin .

    TYPES:
      BEGIN OF ty_title,
        text      TYPE string,
        display   TYPE abap_bool,
        align     TYPE string,
        color     TYPE string,
        full_size TYPE abap_bool,
        position  TYPE string,
        font      TYPE ty_font,
        padding   TYPE ty_padding,
      END OF ty_title .

    TYPES:
      BEGIN OF ty_labels,
        box_width         TYPE i,
        box_height        TYPE i,
        color             TYPE abap_bool,
        font              TYPE ty_font,
        padding           TYPE i,
        generate_labels   TYPE string,
        filter            TYPE string,
        sort              TYPE string,
        point_style       TYPE string,
        text_align        TYPE string,
        use_point_style   TYPE abap_bool,
        point_style_width TYPE i,
        use_border_radius TYPE abap_bool,
        border_radius     TYPE i,
      END OF ty_labels .

    TYPES:
      BEGIN OF ty_legend,
        position       TYPE string,
        align          TYPE string,
        display        TYPE abap_bool,
        max_height     TYPE i,
        max_width      TYPE i,
        full_size      TYPE i,
        on_click       TYPE string,
        on_hover       TYPE string,
        on_leave       TYPE string,
        reverse        TYPE abap_bool,
        labels         TYPE ty_labels,
        rtl            TYPE abap_bool,
        text_direction TYPE string,
        title          TYPE ty_title,
      END OF ty_legend .

    TYPES:
      BEGIN OF ty_subtitle,
        text    TYPE string,
        display TYPE abap_bool,
        color   TYPE string,
        font    TYPE ty_font,
        padding TYPE ty_padding,
      END OF ty_subtitle .

    TYPES:
      BEGIN OF ty_callback,
        label             TYPE string,
        footer            TYPE string,
        before_title      TYPE string,
        after_title       TYPE string,
        title             TYPE string,
        before_body       TYPE string,
        before_label      TYPE string,
        label_color       TYPE string,
        label_text_color  TYPE string,
        label_point_style TYPE string,
        after_label       TYPE string,
        after_body        TYPE string,
        before_footer     TYPE string,
        after_footer      TYPE string,
      END OF ty_callback .

    TYPES:
      BEGIN OF ty_tooltip,
        callbacks           TYPE ty_callback,
        mode                TYPE string,
        intersect           TYPE abap_bool,
        use_point_style     TYPE abap_bool,
        enabled             TYPE abap_bool,
        display_colors      TYPE abap_bool,
        rtl                 TYPE abap_bool,
        external            TYPE string,
        position            TYPE string,
        item_sort           TYPE string,
        filter              TYPE string,
        background_color    TYPE string,
        title_color         TYPE string,
        title_align         TYPE string,
        border_color        TYPE string,
        text_direction      TYPE string,
        x_align             TYPE string,
        y_align             TYPE string,
        title_font          TYPE ty_font,
        body_font           TYPE ty_font,
        footer_font         TYPE ty_font,
        border_width        TYPE i,
        box_width           TYPE i,
        box_height          TYPE i,
        box_padding         TYPE i,
        title_spacing       TYPE i,
        title_margin_bottom TYPE i,
        body_spacing        TYPE i,
        footer_spacing      TYPE i,
        footer_margin_top   TYPE i,
        caret_padding       TYPE i,
        caret_size          TYPE i,
        corner_radius       TYPE i,
        body_color          TYPE string,
        multikey_background TYPE string,
        body_align          TYPE string,
        footer_color        TYPE string,
        footer_align        TYPE string,
        padding             TYPE ty_padding,
      END OF ty_tooltip .

    TYPES:
      BEGIN OF ty_filler,
        propagate TYPE abap_bool,
      END OF ty_filler .

    TYPES:
      BEGIN OF ty_deferred,
        delay    TYPE i,
        x_offset TYPE string,
        y_offset TYPE string,
      END OF ty_deferred.

    TYPES:
      BEGIN OF ty_label,
        background_color TYPE string,
        content          TYPE string,
        display          TYPE abap_bool,
        font             TYPE ty_font,
        x_value          TYPE string,
        y_value          TYPE string,
      END OF ty_label.

    TYPES:
      BEGIN OF ty_annotations,
        type                    TYPE string,
        border_color            TYPE string,
        border_width            TYPE string,
        background_shadow_color TYPE string,
        background_color        TYPE string,
        click                   TYPE string,
        enter                   TYPE string,
        leave                   TYPE string,
        scaleid                 TYPE string,
        value                   TYPE string,
        draw_time               TYPE string,
        x_max                   TYPE string,
        x_min                   TYPE string,
        x_scaleid               TYPE string,
        y_scaleid               TYPE string,
        y_max                   TYPE string,
        y_min                   TYPE string,
        label                   TYPE ty_label,
        sides                   TYPE string,
        radius                  TYPE string,
        font                    TYPE ty_font,
        x_value                 TYPE string,
        y_value                 TYPE string,
        rotation                TYPE string,
        shadow_blur             TYPE string,
        shadow_offset_x         TYPE string,
        shadow_offset_y         TYPE string,
      END OF ty_annotations.

    TYPES:
      BEGIN OF ty_shapes,
        shape1 TYPE ty_annotations,
        shape2 TYPE ty_annotations,
        shape3 TYPE ty_annotations,
        shape4 TYPE ty_annotations,
        shape5 TYPE ty_annotations,
      END OF ty_shapes.

    TYPES:
      BEGIN OF ty_annotation,
        annotations TYPE ty_shapes,
      END OF ty_annotation.

    TYPES:
      BEGIN OF ty_plugins,
        deferred                       TYPE ty_deferred,
        datalabels                     TYPE ty_datalabels,
        autocolors                     TYPE ty_autocolors_plugin,
        custom_canvas_background_color TYPE ty_custom_canvas_bg_color,
        legend                         TYPE ty_legend,
        title                          TYPE ty_title,
        tooltip                        TYPE ty_tooltip,
        filler                         TYPE ty_filler,
        subtitle                       TYPE ty_subtitle,
        annotation                     TYPE ty_annotation,
      END OF ty_plugins .

    TYPES:
      BEGIN OF ty_point_label,
        display             TYPE abap_bool,
        center_point_labels TYPE abap_bool,
        font                TYPE ty_font,
        backdrop_color      TYPE string,
        backdrop_padding    TYPE ty_padding,
        border_radius       TYPE i,
        callback            TYPE string,
        padding             TYPE i,
      END OF ty_point_label .

    TYPES:
      BEGIN OF ty_ticks,
        step_size           TYPE i,
        count               TYPE i,
        color               TYPE string,
        align               TYPE string,
        cross_align         TYPE string,
        sample_size         TYPE i,
        auto_skip           TYPE abap_bool,
        include_bounds      TYPE abap_bool,
        mirror              TYPE abap_bool,
        auto_skip_padding   TYPE i,
        label_offset        TYPE i,
        max_rotation        TYPE i,
        min_rotation        TYPE i,
        padding             TYPE i,
        max_ticks_limit     TYPE i,
        backdrop_color      TYPE string,
        backdrop_padding    TYPE ty_padding,
        callback            TYPE string,
        display             TYPE abap_bool,
        show_label_backdrop TYPE abap_bool,
        text_stroke_color   TYPE string,
        font                TYPE ty_font,
        text_stroke_width   TYPE i,
        z                   TYPE i,
        precision           TYPE i,
      END OF ty_ticks .

    TYPES:
      BEGIN OF ty_border,
        color       TYPE string,
        display     TYPE abap_bool,
        width       TYPE i,
        dash        TYPE i,
        dash_offset TYPE i,
        z           TYPE i,
      END OF ty_border .

    TYPES:
      BEGIN OF ty_grid,
        color                   TYPE string,
        border_color            TYPE string,
        tick_color              TYPE string,
        border_dash             TYPE string,
        border_dash_offset      TYPE p LENGTH 3 DECIMALS 2,
        circular                TYPE abap_bool,
        line_width              TYPE i,
        draw_on_chart_area      TYPE abap_bool,
        draw_ticks              TYPE abap_bool,
        offset                  TYPE abap_bool,
        tick_border_dash        TYPE i,
        tick_border_dash_offset TYPE i,
        tick_length             TYPE i,
        tick_width              TYPE i,
        z                       TYPE i,
      END OF ty_grid .

    TYPES:
      BEGIN OF ty_angle_lines,
        color              TYPE string,
        border_color       TYPE string,
        display            TYPE abap_bool,
        line_width         TYPE i,
        border_dash        TYPE i,
        border_dash_offset TYPE i,
      END OF ty_angle_lines .

    TYPES:
      BEGIN OF ty_scale,
        begin_at_zero    TYPE abap_bool,
        min              TYPE string,
        max              TYPE string,
        point_labels     TYPE ty_point_label,
        stacked          TYPE abap_bool,
        reverse          TYPE abap_bool,
        align_to_pixels  TYPE abap_bool,
        clip             TYPE abap_bool,
        bounds           TYPE string,
        background_color TYPE string,
        type             TYPE string,
        title            TYPE ty_title,
        weight           TYPE i,
        suggested_min    TYPE i,
        suggested_max    TYPE i,
        stack_weight     TYPE i,
        stack            TYPE string,
        position         TYPE string,
        ticks            TYPE ty_ticks,
        border           TYPE ty_border,
        grid             TYPE ty_grid,
        offset           TYPE abap_bool,
        axis             TYPE string,
        labels           TYPE string_table,
        angle_lines      TYPE ty_angle_lines,
        start_angle      TYPE i,
      END OF ty_scale .

    TYPES:
      BEGIN OF ty_scales,
        y TYPE ty_scale,
        x TYPE ty_scale,
        r TYPE ty_scale,
      END OF ty_scales .

    TYPES:
      BEGIN OF ty_interaction,
        mode              TYPE string,
        intersect         TYPE abap_bool,
        include_invisible TYPE abap_bool,
        axis              TYPE string,
      END OF ty_interaction .

    TYPES:
      BEGIN OF ty_tension,
        duration TYPE i,
        easing   TYPE string,
        from     TYPE i,
        to       TYPE i,
        loop     TYPE abap_bool,
      END OF ty_tension .

    TYPES:
      BEGIN OF ty_animations,
        tension TYPE ty_tension,
      END OF ty_animations .

    TYPES:
      BEGIN OF ty_hover,
        mode     TYPE string,
        intersec TYPE abap_bool,
      END OF ty_hover .

    TYPES:
      BEGIN OF ty_layout,
        auto_padding TYPE abap_bool,
        padding      TYPE ty_padding,
      END OF ty_layout .

    TYPES:
      BEGIN OF ty_point,
        radius             TYPE i,
        rotation           TYPE i,
        border_width       TYPE i,
        hit_radius         TYPE i,
        hover_radius       TYPE i,
        hover_border_width TYPE i,
        point_style        TYPE string,
        background_color   TYPE string,
        border_color       TYPE string,
      END OF ty_point .

    TYPES:
      BEGIN OF ty_line,
        tension                  TYPE i,
        border_cap_style         TYPE string,
        border_width             TYPE i,
        fill                     TYPE string,
        border_dash              TYPE i,
        border_dash_offset       TYPE i,
        border_join_style        TYPE string,
        cubic_interpolation_mode TYPE string,
        cap_bezier_points        TYPE abap_bool,
        stepped                  TYPE abap_bool,
        background_color         TYPE string,
        border_color             TYPE string,
      END OF ty_line .

    TYPES:
      BEGIN OF ty_bar,
        border_width     TYPE i,
        background_color TYPE string,
        border_color     TYPE string,
        border_skipped   TYPE string,
        border_radius    TYPE i,
        inflate_amount   TYPE i,
        point_style      TYPE string,
      END OF ty_bar.

    TYPES:
      BEGIN OF ty_arc,
        border_width       TYPE i,
        background_color   TYPE string,
        border_color       TYPE string,
        border_align       TYPE string,
        border_dash        TYPE i,
        border_dash_offset TYPE i,
        border_join_style  TYPE string,
        circular           TYPE abap_bool,
        angle              TYPE i,
      END OF ty_arc.

    TYPES:
      BEGIN OF ty_elements,
        point TYPE ty_point,
        line  TYPE ty_line,
        bar   TYPE ty_bar,
        arc   TYPE ty_arc,
      END OF ty_elements .

    TYPES:
      BEGIN OF ty_options,
        scales      TYPE ty_scales,
        responsive  TYPE abap_bool,
        plugins     TYPE ty_plugins,
        hover       TYPE ty_hover,
        interaction TYPE ty_interaction,
        animations  TYPE ty_animations,
        layout      TYPE ty_layout,
        elements    TYPE ty_elements,
        index_axis  TYPE string,
        events      TYPE string_table,
      END OF ty_options .

    "ChartJS Configuration
    TYPES:
      BEGIN OF ty_chart ##NEEDED,
        type    TYPE string,
        data    TYPE ty_data,
        options TYPE ty_options,
      END OF ty_chart.

    CONSTANTS:
      "! Plugin names the control knows, for the `plugins` parameter of
      "! render( ). Pass them comma separated - they are loaded in that order,
      "! after Chart.js itself, and registered with it.
      BEGIN OF cs_plugin,
        "! value labels on the data points
        datalabels TYPE string VALUE `datalabels`,
        "! automatic colour per dataset
        autocolors TYPE string VALUE `autocolors`,
        "! animate a chart only once it scrolls into view
        deferred   TYPE string VALUE `deferred`,
        "! lines, boxes and labels drawn over the chart area
        annotation TYPE string VALUE `annotation`,
        "! the `venn` chart type
        venn       TYPE string VALUE `venn`,
        "! the `wordCloud` chart type
        wordcloud  TYPE string VALUE `wordcloud`,
      END OF cs_plugin.

    "! Emit &lt;z2ui5ccc:ChartJs/&gt; into an existing view.
    "!
    "! @parameter view         | the builder positioned at the parent element
    "! @parameter config       | bind of a ty_chart structure, see above
    "! @parameter width        | CSS width of the canvas, e.g. `600px`
    "! @parameter height       | CSS height of the canvas
    "! @parameter plugins      | comma separated plugin names, see cs_plugin
    "! @parameter liburl       | overrides where Chart.js is loaded from
    "! @parameter elementpress | client->_event( ... ) fired on a click into
    "!                           the chart
    "! @parameter result       | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        config        TYPE string
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        plugins       TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        elementpress  TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_chartjs IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>leaf(
        view = view
        name = `ChartJs`
        a    = VALUE #( ( |config={ config }| )
                        ( |width={ width }| )
                        ( |height={ height }| )
                        ( |plugins={ plugins }| )
                        ( |libUrl={ liburl }| )
                        ( |elementPress={ elementpress }| ) ) ).

  ENDMETHOD.

ENDCLASS.
