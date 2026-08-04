"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo animate.css</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_ccont_sample_08</em>
"!
"! A table of animations, each row showing a title that carries the class in
"! the column next to it. One <em>AnimateCss</em> element in the view is what
"! makes those class names mean anything.
"!
"! <em>Replay</em> rebuilds the view, so every animation runs again - the
"! browser only plays a CSS animation when the class arrives, not on every
"! model update. The duration and repeat fields retune all of them at once,
"! because animate.css reads them from CSS variables.
CLASS z2ui5_cl_ccont_sample_08 DEFINITION
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

    DATA duration TYPE string.
    DATA repeat   TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.
    " not bound - the rows are emitted into the XML, see view_display( )
    DATA t_row  TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccont_sample_08 IMPLEMENTATION.

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
        )->a( n = |xmlns:{ z2ui5_cl_ccont=>c_ns }|
              v = z2ui5_cl_ccont=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - animate.css`
            ).

    " loads the stylesheet and sets the CSS variables the animations read
    z2ui5_cl_ccont_animate_css=>render( view     = page
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
                      )->a( n = `class`
                            v = `sapUiSmallMargin`
                      )->a( n = `mode`
                            v = `None` ).

    table->open( `columns`
        )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Animated`
        )->shut(
        )->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Class`
        )->shut( ).

    " The rows are built here, in ABAP, instead of binding the table to
    " t_row - because `class` in a UI5 XML view is NOT a bindable property.
    " It is a static style-class attribute the view parser hands to
    " addStyleClass, so a binding expression in it is never substituted and
    " every row would end up carrying that expression as its literal class
    " name. The class has to reach the XML as a literal, which means emitting
    " one row per animation - the way the addon's sample did it.
    DATA(items) = table->open( `items` ).
    LOOP AT t_row INTO DATA(ls_row).
      items->open( `ColumnListItem`
          )->open( `cells`
              )->leaf( `Title`
                  )->a( n = `text`
                        v = ls_row-name
                  )->a( n = `class`
                        v = |{ z2ui5_cl_ccont_animate_css=>cs_base } { ls_row-class }|
              )->leaf( `Text`
                  )->a( n = `text`
                        v = ls_row-class ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `REPLAY`.
        " a full view_display( ), not a model update: the browser plays a CSS
        " animation when the class arrives on a fresh element
        view_display( ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    duration = `1s`.
    repeat   = `1`.

    t_row = VALUE #(
      ( name = `bounce`     class = z2ui5_cl_ccont_animate_css=>cs_attention-bounce )
      ( name = `flash`      class = z2ui5_cl_ccont_animate_css=>cs_attention-flash )
      ( name = `pulse`      class = z2ui5_cl_ccont_animate_css=>cs_attention-pulse )
      ( name = `rubberBand` class = z2ui5_cl_ccont_animate_css=>cs_attention-rubber_band )
      ( name = `shakeX`     class = z2ui5_cl_ccont_animate_css=>cs_attention-shake_x )
      ( name = `swing`      class = z2ui5_cl_ccont_animate_css=>cs_attention-swing )
      ( name = `tada`       class = z2ui5_cl_ccont_animate_css=>cs_attention-tada )
      ( name = `wobble`     class = z2ui5_cl_ccont_animate_css=>cs_attention-wobble )
      ( name = `jello`      class = z2ui5_cl_ccont_animate_css=>cs_attention-jello )
      ( name = `heartBeat`  class = z2ui5_cl_ccont_animate_css=>cs_attention-heart_beat )
      ( name = `bounceIn`   class = z2ui5_cl_ccont_animate_css=>cs_entrance-bounce_in )
      ( name = `fadeInDown` class = z2ui5_cl_ccont_animate_css=>cs_entrance-fade_in_down )
      ( name = `fadeInLeft` class = z2ui5_cl_ccont_animate_css=>cs_entrance-fade_in_left )
      ( name = `zoomIn`     class = z2ui5_cl_ccont_animate_css=>cs_entrance-zoom_in )
      ( name = `flipInX`    class = z2ui5_cl_ccont_animate_css=>cs_entrance-flip_in_x )
      ( name = `rollIn`     class = z2ui5_cl_ccont_animate_css=>cs_entrance-roll_in ) ).

  ENDMETHOD.

ENDCLASS.
