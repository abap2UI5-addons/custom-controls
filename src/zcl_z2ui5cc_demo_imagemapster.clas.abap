"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo ImageMapster</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_imagemapster</em>
"!
"! A floor plan with three rooms as clickable regions. Hovering highlights a
"! room, clicking selects it - and the selection is not a frontend detail: it
"! is written back into the model, so the list on the right and the log below
"! are filled from ABAP, from the same data the map is drawn from.
"!
"! <em>Select all</em> and <em>Clear</em> drive the map from the backend, which
"! is the other direction of the same binding.
"!
"! The plan is an inline SVG built in ABAP, so the demo needs no uploaded image
"! and no server to serve one.
CLASS zcl_z2ui5cc_demo_imagemapster DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_log,
        text TYPE string,
      END OF ty_s_log.

    DATA t_area   TYPE zcl_z2ui5cc_imagemapster=>ty_t_area.
    DATA s_config TYPE zcl_z2ui5cc_imagemapster=>ty_s_config.
    DATA t_log    TYPE STANDARD TABLE OF ty_s_log WITH EMPTY KEY.
    DATA image    TYPE string.
    DATA selected TYPE string.
    DATA info     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS image_build.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_imagemapster IMPLEMENTATION.

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
                  v = `abap2UI5 - ImageMapster`
            )->a( n = `showNavButton`
                  v = `true`
            )->a( n = `navButtonPress`
                  v = client->_event( `BACK` ) ).

    page->open( `headerContent`
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Select all`
            )->a( n = `press`
                  v = client->_event( `ALL` )
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Clear`
            )->a( n = `press`
                  v = client->_event( `CLEAR` ) ).

    DATA(row) = page->open( `HBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin`
                    )->a( n = `wrap`
                          v = `Wrap` ).

    DATA(map) = row->open( `VBox`
                    )->a( n = `width`
                          v = `620px` ).

    zcl_z2ui5cc_imagemapster=>render(
        view         = map
        src          = client->_bind( image )
        selectedkeys = client->_bind( selected )
        areapress    = client->_event( `AREA` )
        width        = `600px`
        areas        = client->_bind( val           = t_area
                                      custom_filter = NEW zcl_z2ui5cc_json_filter( ) )
        config       = client->_bind( val           = s_config
                                      custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                      custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                          iv_first_json_upper = abap_false ) ) ).

    map->leaf( `Text`
           )->a( n = `text`
                 v = client->_bind( info )
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    row->open( `VBox`
        )->a( n = `class`
              v = `sapUiMediumMarginBegin`
        )->open( `List`
            )->a( n = `headerText`
                  v = `Rooms`
            )->a( n = `items`
                  v = client->_bind( t_area )
            )->a( n = `width`
                  v = `18rem`
            )->open( `items`
                )->leaf( `StandardListItem`
                    )->a( n = `title`
                          v = `{ALT}`
                    )->a( n = `description`
                          v = `{KEY}`
        )->shut( )->shut(
        )->open( `List`
            )->a( n = `headerText`
                  v = `Click log`
            )->a( n = `items`
                  v = client->_bind( t_log )
            )->a( n = `width`
                  v = `18rem`
            )->a( n = `noDataText`
                  v = `click a room`
            )->a( n = `class`
                  v = `sapUiSmallMarginTop`
            )->open( `items`
                )->leaf( `StandardListItem`
                    )->a( n = `title`
                          v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `AREA`.
        " selected already carries what the CONTROL wrote into the model
        INSERT VALUE #( text = |click { lines( t_log ) + 1 }: selection = { selected }| )
               INTO TABLE t_log.
        info = COND #( WHEN selected IS INITIAL
                       THEN `Nothing selected.`
                       ELSE |Selected: { selected }| ).
        client->view_model_update( ).

      WHEN `ALL`.
        selected = concat_lines_of( table = VALUE string_table(
                                        FOR ls_area IN t_area ( ls_area-key ) )
                                    sep   = `,` ).
        info     = |Selected from ABAP: { selected }|.
        client->view_model_update( ).

      WHEN `CLEAR`.
        CLEAR selected.
        info = `Cleared from ABAP.`.
        client->view_model_update( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    image_build( ).

    " rect coordinates are x1,y1,x2,y2 - the same the SVG above draws
    t_area = VALUE #(
      ( key = `office`  shape = `rect` coords = `20,20,280,190`  alt = `Office` )
      ( key = `lab`     shape = `rect` coords = `300,20,580,190` alt = `Laboratory` )
      ( key = `storage` shape = `rect` coords = `20,210,580,380` alt = `Storage`
        fillcolor = `f6b93b` ) ).

    " colours are hex without a leading #, the way ImageMapster wants them
    s_config-fill            = abap_true.
    s_config-fill_color      = `0a6ed1`.
    s_config-fill_opacity    = `0.4`.
    s_config-stroke          = abap_true.
    s_config-stroke_color    = `0a6ed1`.
    s_config-stroke_width    = 3.
    s_config-scale_map       = abap_true.
    s_config-is_selectable   = abap_true.
    s_config-is_deselectable = abap_true.

    s_config-render_select-fill         = abap_true.
    s_config-render_select-fill_color   = `107e3e`.
    s_config-render_select-fill_opacity = `0.5`.
    s_config-render_select-stroke       = abap_true.
    s_config-render_select-stroke_color = `107e3e`.
    s_config-render_select-stroke_width = 3.

    info = `Hover a room to highlight it, click to select it.`.

  ENDMETHOD.

  METHOD image_build.

    " an inline SVG floor plan, so the demo needs no uploaded image. `#` has
    " to be percent-encoded - inside a data: URI it would start a fragment.
    DATA(lv_room) = `fill='%23c8d6e5' stroke='%23576574' stroke-width='3'`.
    DATA(lv_text) = `font-family='sans-serif' font-size='26' ` &&
                    `text-anchor='middle' fill='%23222f3e'`.

    image = `data:image/svg+xml,` &&
      `<svg xmlns='http://www.w3.org/2000/svg' width='600' height='400'>` &&
      `<rect width='600' height='400' fill='%23eef1f5'/>` &&
      |<rect x='20' y='20' width='260' height='170' { lv_room }/>| &&
      |<rect x='300' y='20' width='280' height='170' { lv_room }/>| &&
      |<rect x='20' y='210' width='560' height='170' { lv_room }/>| &&
      |<text x='150' y='115' { lv_text }>Office</text>| &&
      |<text x='440' y='115' { lv_text }>Laboratory</text>| &&
      |<text x='300' y='305' { lv_text }>Storage</text>| &&
      `</svg>`.

  ENDMETHOD.

ENDCLASS.
