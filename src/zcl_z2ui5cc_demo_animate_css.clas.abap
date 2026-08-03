"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo animate.css</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_animate_css</em>
"!
"! A table of animations, each row showing a title that carries the class in
"! the column next to it. One <em>AnimateCss</em> element in the view is what
"! makes those class names mean anything.
"!
"! <em>Replay</em> rebuilds the view, so every animation runs again - the
"! browser only plays a CSS animation when the class arrives, not on every
"! model update. The duration and repeat fields retune all of them at once,
"! because animate.css reads them from CSS variables.
CLASS zcl_z2ui5cc_demo_animate_css DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_row,
        name  TYPE string,
        class TYPE string,
      END OF ty_s_row.

    DATA t_row     TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA duration  TYPE string.
    DATA repeat    TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_demo_animate_css IMPLEMENTATION.

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
                  v = `abap2UI5 - animate.css`
            )->a( n = `showNavButton`
                  v = `true`
            )->a( n = `navButtonPress`
                  v = client->_event( `BACK` ) ).

    " loads the stylesheet and sets the CSS variables the animations read
    zcl_z2ui5cc_animate_css=>render( view     = page
                                     duration = duration
                                     repeat   = repeat ).

    page->open( `headerContent`
        )->leaf( `Label`
            )->a( n = `text`
                  v = `duration`
        )->leaf( `Input`
            )->a( n = `value`
                  v = client->_bind( duration )
            )->a( n = `width`
                  v = `6rem`
        )->leaf( `Label`
            )->a( n = `text`
                  v = `repeat`
        )->leaf( `Input`
            )->a( n = `value`
                  v = client->_bind( repeat )
            )->a( n = `width`
                  v = `4rem`
        )->leaf( `Button`
            )->a( n = `text`
                  v = `Replay`
            )->a( n = `type`
                  v = `Emphasized`
            )->a( n = `press`
                  v = client->_event( `REPLAY` ) ).

    DATA(table) = page->open( `Table`
                      )->a( n = `items`
                            v = client->_bind( t_row )
                      )->a( n = `class`
                            v = `sapUiSmallMargin`
                      )->a( n = `mode`
                            v = `None` ).

    table->open( `columns`
        )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Animated`
        )->shut(
        )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Class`
        )->shut( ).

    " the class comes out of the model, so the whole table is data driven -
    " the animation name and the class that plays it are the same string
    table->open( `items`
        )->open( `ColumnListItem`
            )->open( `cells`
                )->leaf( `Title`
                    )->a( n = `text`
                          v = `{NAME}`
                    )->a( n = `class`
                          v = |{ zcl_z2ui5cc_animate_css=>cs_base } \{CLASS\}|
                )->leaf( `Text`
                    )->a( n = `text`
                          v = `{CLASS}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `REPLAY`.
        " a full view_display( ), not a model update: the browser plays a CSS
        " animation when the class arrives on a fresh element
        view_display( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    duration = `1s`.
    repeat   = `1`.

    t_row = VALUE #(
      ( name = `bounce`     class = zcl_z2ui5cc_animate_css=>cs_attention-bounce )
      ( name = `flash`      class = zcl_z2ui5cc_animate_css=>cs_attention-flash )
      ( name = `pulse`      class = zcl_z2ui5cc_animate_css=>cs_attention-pulse )
      ( name = `rubberBand` class = zcl_z2ui5cc_animate_css=>cs_attention-rubber_band )
      ( name = `shakeX`     class = zcl_z2ui5cc_animate_css=>cs_attention-shake_x )
      ( name = `swing`      class = zcl_z2ui5cc_animate_css=>cs_attention-swing )
      ( name = `tada`       class = zcl_z2ui5cc_animate_css=>cs_attention-tada )
      ( name = `wobble`     class = zcl_z2ui5cc_animate_css=>cs_attention-wobble )
      ( name = `jello`      class = zcl_z2ui5cc_animate_css=>cs_attention-jello )
      ( name = `heartBeat`  class = zcl_z2ui5cc_animate_css=>cs_attention-heart_beat )
      ( name = `bounceIn`   class = zcl_z2ui5cc_animate_css=>cs_entrance-bounce_in )
      ( name = `fadeInDown` class = zcl_z2ui5cc_animate_css=>cs_entrance-fade_in_down )
      ( name = `fadeInLeft` class = zcl_z2ui5cc_animate_css=>cs_entrance-fade_in_left )
      ( name = `zoomIn`     class = zcl_z2ui5cc_animate_css=>cs_entrance-zoom_in )
      ( name = `flipInX`    class = zcl_z2ui5cc_animate_css=>cs_entrance-flip_in_x )
      ( name = `rollIn`     class = zcl_z2ui5cc_animate_css=>cs_entrance-roll_in ) ).

  ENDMETHOD.

ENDCLASS.
