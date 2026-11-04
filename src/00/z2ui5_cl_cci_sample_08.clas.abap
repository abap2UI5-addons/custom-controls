"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo animate.css</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_08</em>
"!
"! A table of animations, each row showing a title that carries the class in
"! the column next to it. One <em>AnimateCss</em> element in the view is what
"! makes those class names mean anything.
"!
"! <em>Replay</em> rebuilds the view, so every animation runs again - the
"! browser only plays a CSS animation when the class arrives, not on every
"! model update. The duration and repeat fields retune all of them at once,
"! because animate.css reads them from CSS variables.
CLASS z2ui5_cl_cci_sample_08 DEFINITION
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
    DATA t_row  TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_08 IMPLEMENTATION.

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
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA items TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA ls_row LIKE LINE OF t_row.
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
                  v = `abap2UI5 - animate.css`
            ).

    " loads the stylesheet and sets the CSS variables the animations read
    z2ui5_cl_cci_animate_css=>render( view     = page
                                      duration = duration
                                      repeat   = repeat ).

    page->ele( `headerContent`
        )->tag( `Label`
            )->a( n = `text`
                  v = `duration`
        )->tag( `Input`
            )->a( n = `value`
                  v = client->_bind( duration )
            )->a( n = `width`
                  v = `6rem`
        )->tag( `Label`
            )->a( n = `text`
                  v = `repeat`
        )->tag( `Input`
            )->a( n = `value`
                  v = client->_bind( repeat )
            )->a( n = `width`
                  v = `4rem`
        )->tag( `Button`
            )->a( n = `text`
                  v = `Replay`
            )->a( n = `type`
                  v = `Emphasized`
            )->a( n = `press`
                  v = client->_event( `REPLAY` ) ).


    table = page->ele( `Table`
                      )->a( n = `class`
                            v = `sapUiSmallMargin`
                      )->a( n = `mode`
                            v = `None` ).

    table->ele( `columns`
        )->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Animated`
        )->end(
        )->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Class`
        )->end( ).

    " The rows are built here, in ABAP, instead of binding the table to
    " t_row - because `class` in a UI5 XML view is NOT a bindable property.
    " It is a static style-class attribute the view parser hands to
    " addStyleClass, so a binding expression in it is never substituted and
    " every row would end up carrying that expression as its literal class
    " name. The class has to reach the XML as a literal, which means emitting
    " one row per animation - the way the addon's sample did it.

    items = table->ele( `items` ).

    LOOP AT t_row INTO ls_row.
      items->ele( `ColumnListItem`
          )->ele( `cells`
              )->tag( `Title`
                  )->a( n = `text`
                        t = ls_row-name
                  )->a( n = `class`
                        t = |{ z2ui5_cl_cci_animate_css=>cs_base } { ls_row-class }|
              )->tag( `Text`
                  )->a( n = `text`
                        t = ls_row-class ).
    ENDLOOP.

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    IF client->get( )-event = `REPLAY`.
      " a full view_display( ), not a model update: the browser plays a CSS
      " animation when the class arrives on a fresh element
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD model_init.
    DATA temp1 LIKE t_row.
    DATA temp2 LIKE LINE OF temp1.

    duration = `1s`.
    repeat   = `1`.


    CLEAR temp1.

    temp2-name = `bounce`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-bounce.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `flash`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-flash.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `pulse`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-pulse.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `rubberBand`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-rubber_band.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `shakeX`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-shake_x.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `swing`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-swing.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `tada`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-tada.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `wobble`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-wobble.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `jello`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-jello.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `heartBeat`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_attention-heart_beat.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `bounceIn`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_entrance-bounce_in.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `fadeInDown`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_entrance-fade_in_down.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `fadeInLeft`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_entrance-fade_in_left.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `zoomIn`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_entrance-zoom_in.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `flipInX`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_entrance-flip_in_x.
    INSERT temp2 INTO TABLE temp1.
    temp2-name = `rollIn`.
    temp2-class = z2ui5_cl_cci_animate_css=>cs_entrance-roll_in.
    INSERT temp2 INTO TABLE temp1.
    t_row = temp1.

  ENDMETHOD.

ENDCLASS.
