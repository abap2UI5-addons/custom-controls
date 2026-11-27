"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Gauge</p>
"!
"! The ABAP half of the z2ui5_cci.cc.Gauge custom control: the view builder
"! that emits its XML element, plus the type for the coloured zones.
"!
"! A round gauge with a scale, coloured zones and a needle that travels to
"! the bound value - drawn on a canvas by canvas-gauges. Bind <em>value</em>
"! and the needle follows every change of the model, also one another control
"! on the page makes, without the gauge being drawn again.
"!
"! The scale is given as minimum, maximum and the distance between two
"! labelled ticks. The library spreads the labels evenly, so an interval that
"! does not divide the range is rounded to the nearest number of steps.
CLASS z2ui5_cl_cci_gauge DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_number TYPE p LENGTH 15 DECIMALS 3.

    TYPES:
      "! One coloured zone of the scale, from <em>low</em> to <em>high</em>.
      "! <em>color</em> is any CSS colour: `#bb0000`, `orange`, `rgb(0,128,0)`.
      "! A zone is cut to the scale; one without a colour is not drawn.
      BEGIN OF ty_s_highlight,
        low   TYPE ty_number,
        high  TYPE ty_number,
        color TYPE string,
      END OF ty_s_highlight.
    TYPES ty_t_highlight TYPE STANDARD TABLE OF ty_s_highlight WITH EMPTY KEY.

    "! Emit &lt;z2ui5_cci:Gauge/&gt; into an existing view.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view         | the builder positioned at the parent element
    "! @parameter value        | the value the needle points at; bind it
    "! @parameter minvalue     | start of the scale, default 0
    "! @parameter maxvalue     | end of the scale, default 100
    "! @parameter title        | text in the upper half of the dial
    "! @parameter units        | text in the lower half, e.g. % or km/h
    "! @parameter width        | width of the canvas in px, default 250
    "! @parameter height       | height of the canvas in px, default 250
    "! @parameter startangle   | where the scale starts, in degrees from the bottom, default 45
    "! @parameter ticksangle   | how far round the scale runs, in degrees, default 270
    "! @parameter tickinterval | distance between two labelled ticks; empty: ten steps
    "! @parameter minorticks   | small ticks between two labelled ones, default 2
    "! @parameter highlights   | bind of a ty_t_highlight table
    "! @parameter valuebox     | `false` hides the box with the number; never abap_true, it serializes as X
    "! @parameter decimals     | decimal places of the number in the box, default 0
    "! @parameter animation    | `false` lets the needle jump instead of travel
    "! @parameter options      | bind of a structure with options of the library; they win
    "!                           over the parameters above. Bind with omit_initial - the
    "!                           control turns the field names into camelCase
    "!                           (color_plate -&gt; colorPlate), no mapper needed. To switch off
    "!                           an option whose default is true, use a string field set to
    "!                           `false`: omit_initial drops an abap_false
    "! @parameter liburl       | where to load canvas-gauges from; default: see LibUrls
    "! @parameter result       | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        value         TYPE string OPTIONAL
        minvalue      TYPE string OPTIONAL
        maxvalue      TYPE string OPTIONAL
        title         TYPE string OPTIONAL
        units         TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        startangle    TYPE string OPTIONAL
        ticksangle    TYPE string OPTIONAL
        tickinterval  TYPE string OPTIONAL
        minorticks    TYPE string OPTIONAL
        highlights    TYPE string OPTIONAL
        valuebox      TYPE string OPTIONAL
        decimals      TYPE string OPTIONAL
        animation     TYPE string OPTIONAL
        options       TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_gauge IMPLEMENTATION.

  METHOD render.

    " an attribute the caller left empty is dropped by tag( ) - it would
    " override the control's own default with an empty string
    result = z2ui5_cl_cci=>tag( view = view
                                name = `Gauge`
                                a    = VALUE #( ( |value={ value }| )
                                                ( |minValue={ minvalue }| )
                                                ( |maxValue={ maxvalue }| )
                                                ( |title={ title }| )
                                                ( |units={ units }| )
                                                ( |width={ width }| )
                                                ( |height={ height }| )
                                                ( |startAngle={ startangle }| )
                                                ( |ticksAngle={ ticksangle }| )
                                                ( |tickInterval={ tickinterval }| )
                                                ( |minorTicks={ minorticks }| )
                                                ( |highlights={ highlights }| )
                                                ( |valueBox={ valuebox }| )
                                                ( |decimals={ decimals }| )
                                                ( |animation={ animation }| )
                                                ( |options={ options }| )
                                                ( |libUrl={ liburl }| ) ) ).

  ENDMETHOD.

ENDCLASS.
