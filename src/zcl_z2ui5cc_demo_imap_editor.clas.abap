"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo image map editor</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_imap_editor</em>
"!
"! The full round trip, in one app:
"!
"!   1. upload a picture, or keep the floor plan the app draws as an SVG
"!   2. draw the regions on it - rectangle, circle, polygon - and name each one
"!      in the editor's <em>edit</em> mode (the <em>alt</em> attribute becomes
"!      the key)
"!   3. <em>Take over regions</em> collects them into an ABAP table
"!   4. the same table drives the ImageMapster control underneath, and clicking
"!      a region there raises an event in this class
"!
"! So the coordinates never leave the browser as text to be copied by hand;
"! they arrive as data and are used as data. The two controls share the row
"! type, which is why step 3 needs no conversion.
CLASS zcl_z2ui5cc_demo_imap_editor DEFINITION
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

    DATA image     TYPE string.
    DATA filename  TYPE string.
    DATA upload    TYPE string.
    DATA path      TYPE string.
    DATA trigger   TYPE i.
    DATA t_area    TYPE zcl_z2ui5cc_imagemapster=>ty_t_area.
    DATA s_config  TYPE zcl_z2ui5cc_imagemapster=>ty_s_config.
    DATA selected  TYPE string.
    DATA t_log     TYPE STANDARD TABLE OF ty_s_log WITH EMPTY KEY.
    DATA info      TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS image_build.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_imap_editor IMPLEMENTATION.

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
        " the framework's own control namespace - for its FileUploader
        )->a( n = `xmlns:z2ui5`
              v = `z2ui5.cc`
        )->a( n = |xmlns:{ zcl_z2ui5cc=>c_ns }|
              v = zcl_z2ui5cc=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - image map editor`
            )->a( n = `showNavButton`
                  v = `true`
            )->a( n = `navButtonPress`
                  v = client->_event( `BACK` ) ).

    page->open( `headerContent`
        )->leaf( n  = `FileUploader`
                 ns = `z2ui5`
            )->a( n = `value`
                  v = client->_bind( upload )
            )->a( n = `path`
                  v = client->_bind( path )
            )->a( n = `checkDirectUpload`
                  v = `true`
            )->a( n = `placeholder`
                  v = `upload your own picture`
            )->a( n = `fileType`
                  v = `png,jpg,jpeg,gif,bmp`
            )->a( n = `upload`
                  v = client->_event( `UPLOAD` )
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Take over regions`
            )->a( n = `type`
                  v = `Emphasized`
            )->a( n = `press`
                  v = client->_event( `COLLECT` ) ).

    DATA(box) = page->open( `VBox`
                    )->a( n = `class`
                          v = `sapUiSmallMargin` ).

    box->leaf( `MessageStrip`
           )->a( n = `text`
                 v = `Pick a shape in the editor's toolbar, draw it, then ` &&
                     `switch to "edit" and give the region an alt text - that ` &&
                     `becomes its key in ABAP.`
           )->a( n = `type`
                 v = `Information`
           )->a( n = `showIcon`
                 v = `true`
           )->a( n = `class`
                 v = `sapUiSmallMarginBottom` ).

    " the editor - a page of its own, in an iframe
    zcl_z2ui5cc_imagemap_editor=>render(
        view      = box
        src       = client->_bind( image )
        filename  = client->_bind( filename )
        areas     = client->_bind( t_area )
        trigger   = client->_bind( trigger )
        height    = `620px`
        collected = client->_event( `COLLECTED` ) ).

    DATA(result) = box->open( `Panel`
                       )->a( n = `headerText`
                             v = `The regions, back in ABAP`
                       )->a( n = `class`
                             v = `sapUiSmallMarginTop`
                       )->open( `content`
                           )->open( `HBox`
                               )->a( n = `wrap`
                                     v = `Wrap` ).

    DATA(live) = result->open( `VBox`
                     )->a( n = `class`
                           v = `sapUiSmallMargin` ).

    live->leaf( `Text`
            )->a( n = `text`
                  v = client->_bind( info )
            )->a( n = `class`
                  v = `sapUiSmallMarginBottom` ).

    " the very same table now drives the renderer
    zcl_z2ui5cc_imagemapster=>render(
        view         = live
        src          = client->_bind( image )
        areas        = client->_bind( val           = t_area
                                      custom_filter = NEW zcl_z2ui5cc_json_filter( ) )
        selectedkeys = client->_bind( selected )
        areapress    = client->_event( `AREA` )
        width        = `600px`
        config       = client->_bind( val           = s_config
                                      custom_filter = NEW zcl_z2ui5cc_json_filter( )
                                      custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                                          iv_first_json_upper = abap_false ) ) ).

    DATA(side) = result->open( `VBox`
                     )->a( n = `class`
                           v = `sapUiSmallMargin` ).

    side->open( `Table`
        )->a( n = `items`
              v = client->_bind( t_area )
        )->a( n = `width`
              v = `26rem`
        )->a( n = `noDataText`
              v = `nothing collected yet`
        )->open( `columns`
            )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Key`
        )->shut(
            )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Shape`
        )->shut(
            )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Coords`
        )->shut( )->shut(
        )->open( `items`
            )->open( `ColumnListItem`
                )->open( `cells`
                    )->leaf( `Text` )->a( n = `text` v = `{KEY}`
                    )->leaf( `Text` )->a( n = `text` v = `{SHAPE}`
                    )->leaf( `Text` )->a( n = `text` v = `{COORDS}` ).

    side->open( `List`
        )->a( n = `headerText`
              v = `Click log`
        )->a( n = `items`
              v = client->_bind( t_log )
        )->a( n = `width`
              v = `26rem`
        )->a( n = `noDataText`
              v = `click a region on the left`
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

      WHEN `COLLECT`.
        " raising the trigger is the whole call - the control asks the editor
        " page, and the answer arrives with the next roundtrip
        trigger = trigger + 1.
        info    = |Collecting ({ trigger })...|.
        client->view_model_update( ).

      WHEN `COLLECTED`.
        " t_area already carries what the CONTROL wrote into the model
        CLEAR selected.
        IF t_area IS INITIAL.
          info = `The editor reported no regions - draw one first.`.
        ELSE.
          info = |{ lines( t_area ) } region(s) taken over. | &&
                 |The map below is drawn from them.|.
        ENDIF.
        client->view_model_update( ).

      WHEN `UPLOAD`.
        " checkDirectUpload hands the picture over as a base64 data URI
        image    = upload.
        filename = path.
        CLEAR: t_area, t_log, selected.
        info = |{ path } loaded - draw your regions.|.
        client->view_model_update( ).

      WHEN `AREA`.
        INSERT VALUE #( text = |click { lines( t_log ) + 1 }: selection = { selected }| )
               INTO TABLE t_log.
        client->view_model_update( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    image_build( ).
    filename = `floorplan.svg`.
    info     = `Draw a region, then press "Take over regions".`.

    s_config-fill            = abap_true.
    s_config-fill_color      = `0a6ed1`.
    s_config-fill_opacity    = `0.4`.
    s_config-stroke          = abap_true.
    s_config-stroke_color    = `0a6ed1`.
    s_config-stroke_width    = 3.
    s_config-scale_map       = abap_true.
    s_config-is_selectable   = abap_true.
    s_config-is_deselectable = abap_true.

  ENDMETHOD.

  METHOD image_build.

    " the same inline SVG the ImageMapster demo uses, so the app needs no
    " uploaded picture to be useful. `#` has to be percent-encoded - inside a
    " data: URI it would start a fragment.
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
