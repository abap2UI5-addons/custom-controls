"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - animate.css</p>
"!
"! The ABAP half of the z2ui5cc.cc.AnimateCss custom control: the view builder
"! that emits its XML element, plus the animation names as constants.
"!
"! animate.css is pure CSS. Put this element once into a view and every control
"! after it can be animated through its <em>class</em> attribute:
"!
"!   )->leaf( `Title` )->a( n = `text`  v = `hello`
"!                    )->a( n = `class` v = |{ cs_base } { cs_attention-tada }| )
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_animatecss), where the
"! stylesheet itself - 4000 lines - was a chain of ABAP string literals.
CLASS zcl_z2ui5cc_animate_css DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! every animated element needs this class next to the animation itself
    CONSTANTS cs_base TYPE string VALUE `animate__animated`.

    "! modifiers - combine them with an animation
    CONSTANTS:
      BEGIN OF cs_modifier,
        infinite  TYPE string VALUE `animate__infinite`,
        repeat_2  TYPE string VALUE `animate__repeat-2`,
        repeat_3  TYPE string VALUE `animate__repeat-3`,
        delay_1s  TYPE string VALUE `animate__delay-1s`,
        delay_2s  TYPE string VALUE `animate__delay-2s`,
        faster    TYPE string VALUE `animate__faster`,
        fast      TYPE string VALUE `animate__fast`,
        slow      TYPE string VALUE `animate__slow`,
        slower    TYPE string VALUE `animate__slower`,
      END OF cs_modifier.

    "! attention seekers - animations that run in place
    CONSTANTS:
      BEGIN OF cs_attention,
        bounce      TYPE string VALUE `animate__bounce`,
        flash       TYPE string VALUE `animate__flash`,
        pulse       TYPE string VALUE `animate__pulse`,
        rubber_band TYPE string VALUE `animate__rubberBand`,
        shake_x     TYPE string VALUE `animate__shakeX`,
        shake_y     TYPE string VALUE `animate__shakeY`,
        head_shake  TYPE string VALUE `animate__headShake`,
        swing       TYPE string VALUE `animate__swing`,
        tada        TYPE string VALUE `animate__tada`,
        wobble      TYPE string VALUE `animate__wobble`,
        jello       TYPE string VALUE `animate__jello`,
        heart_beat  TYPE string VALUE `animate__heartBeat`,
      END OF cs_attention.

    "! entrances - animations that bring an element in
    CONSTANTS:
      BEGIN OF cs_entrance,
        bounce_in       TYPE string VALUE `animate__bounceIn`,
        bounce_in_down  TYPE string VALUE `animate__bounceInDown`,
        bounce_in_left  TYPE string VALUE `animate__bounceInLeft`,
        bounce_in_right TYPE string VALUE `animate__bounceInRight`,
        bounce_in_up    TYPE string VALUE `animate__bounceInUp`,
        fade_in         TYPE string VALUE `animate__fadeIn`,
        fade_in_down    TYPE string VALUE `animate__fadeInDown`,
        fade_in_left    TYPE string VALUE `animate__fadeInLeft`,
        fade_in_right   TYPE string VALUE `animate__fadeInRight`,
        fade_in_up      TYPE string VALUE `animate__fadeInUp`,
        zoom_in         TYPE string VALUE `animate__zoomIn`,
        flip_in_x       TYPE string VALUE `animate__flipInX`,
        light_speed_in  TYPE string VALUE `animate__lightSpeedInRight`,
        roll_in         TYPE string VALUE `animate__rollIn`,
      END OF cs_entrance.

    "! exits - animations that take an element out
    CONSTANTS:
      BEGIN OF cs_exit,
        bounce_out       TYPE string VALUE `animate__bounceOut`,
        bounce_out_down  TYPE string VALUE `animate__bounceOutDown`,
        bounce_out_left  TYPE string VALUE `animate__bounceOutLeft`,
        bounce_out_right TYPE string VALUE `animate__bounceOutRight`,
        bounce_out_up    TYPE string VALUE `animate__bounceOutUp`,
        fade_out         TYPE string VALUE `animate__fadeOut`,
        zoom_out         TYPE string VALUE `animate__zoomOut`,
        flip_out_x       TYPE string VALUE `animate__flipOutX`,
        roll_out         TYPE string VALUE `animate__rollOut`,
      END OF cs_exit.

    "! Emit <z2ui5cc:AnimateCss/> into an existing view.
    "!
    "! @parameter view     | the builder positioned at the parent element
    "! @parameter duration | how long one animation runs, e.g. `1s`, `500ms`
    "! @parameter delay    | how long the delay modifiers wait, e.g. `1s`
    "! @parameter repeat   | how often the repeat modifiers repeat, e.g. `2`
    "! @parameter cssurl   | overrides where animate.css is loaded from
    "! @parameter result   | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        duration      TYPE string OPTIONAL
        delay         TYPE string OPTIONAL
        repeat        TYPE string OPTIONAL
        cssurl        TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_animate_css IMPLEMENTATION.

  METHOD render.

    result = zcl_z2ui5cc=>leaf(
        view = view
        name = `AnimateCss`
        a    = VALUE #( ( |duration={ duration }| )
                        ( |delay={ delay }| )
                        ( |repeat={ repeat }| )
                        ( |cssUrl={ cssurl }| ) ) ).

  ENDMETHOD.

ENDCLASS.
