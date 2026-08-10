"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - ImageMapster</p>
"!
"! The ABAP half of the z2ui5cc.cc.ImageMapster custom control: the view
"! builder that emits its XML element, plus the types for the regions and the
"! render options.
"!
"! A plain HTML image map gives a clickable region and nothing else. This one
"! highlights the region under the mouse, keeps a selection, writes it back
"! into the model and raises a normal abap2UI5 event with the key of the region
"! that was clicked - so a floor plan, a machine drawing or a map becomes an
"! input control.
"!
"! Bind config with the camelCase mapper and this library's JSON filter - see
"! z2ui5_cl_cci_chartjs for the same pattern and why both are needed.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_imagemapster). The
"! image-map editor that repository shipped next to it is not part of the port:
"! it is an authoring tool for coordinates, not a control.
CLASS z2ui5_cl_cci_imagemapster DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      "! One clickable region. <em>coords</em> is the HTML image map coordinate
      "! list for the shape - `x1,y1,x2,y2,...` for a polygon, `x,y,r` for a
      "! circle, `x1,y1,x2,y2` for a rectangle.
      "!
      "! The render fields override the map-wide options for this one region;
      "! leave them initial and the option from <em>config</em> applies.
      BEGIN OF ty_s_area,
        key          TYPE string,
        "! `poly`, `circle` or `rect`
        shape        TYPE string,
        coords       TYPE string,
        alt          TYPE string,
        href         TYPE string,
        fillcolor    TYPE string,
        fillopacity  TYPE string,
        strokecolor  TYPE string,
        "! start out selected
        selected     TYPE abap_bool,
        "! always drawn, cannot be turned off by the user
        staticstate  TYPE abap_bool,
        isselectable TYPE abap_bool,
      END OF ty_s_area.
    TYPES ty_t_area TYPE STANDARD TABLE OF ty_s_area WITH EMPTY KEY.

    TYPES:
      "! How a region is drawn in one state.
      BEGIN OF ty_s_render,
        fill           TYPE abap_bool,
        fill_color     TYPE string,
        fill_opacity   TYPE string,
        stroke         TYPE abap_bool,
        stroke_color   TYPE string,
        stroke_opacity TYPE string,
        stroke_width   TYPE i,
        fade           TYPE abap_bool,
        fade_duration  TYPE i,
      END OF ty_s_render.

    TYPES:
      "! Map-wide options. Colours are hex WITHOUT a leading `#`, the way
      "! ImageMapster wants them: `ff0000`, not `#ff0000`.
      BEGIN OF ty_s_config,
        fill             TYPE abap_bool,
        fill_color       TYPE string,
        fill_opacity     TYPE string,
        stroke           TYPE abap_bool,
        stroke_color     TYPE string,
        stroke_opacity   TYPE string,
        stroke_width     TYPE i,
        highlight        TYPE abap_bool,
        fade             TYPE abap_bool,
        fade_duration    TYPE i,
        single_select    TYPE abap_bool,
        is_selectable    TYPE abap_bool,
        is_deselectable  TYPE abap_bool,
        static_state     TYPE abap_bool,
        mouseout_delay   TYPE i,
        scale_map        TYPE abap_bool,
        wrap_class       TYPE string,
        alt_image        TYPE string,
        render_highlight TYPE ty_s_render,
        render_select    TYPE ty_s_render,
      END OF ty_s_config.

    "! Emit &lt;z2ui5cc:ImageMapster/&gt; into an existing view.
    "!
    "! @parameter view         | the builder positioned at the parent element
    "! @parameter src          | the image, as a URL or a data: URI
    "! @parameter areas        | bind of a ty_t_area table
    "! @parameter config       | bind of a ty_s_config structure
    "! @parameter selectedkeys | bind two-way; comma separated area keys
    "! @parameter width        | CSS width of the image
    "! @parameter height       | CSS height; empty keeps the aspect ratio
    "! @parameter autoresize   | `false` to leave the map at its natural size
    "! @parameter liburl       | overrides where ImageMapster is loaded from
    "! @parameter areapress    | client->_event( ... ) fired on a click into
    "!                           a region
    "! @parameter result       | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        src           TYPE string
        areas         TYPE string OPTIONAL
        config        TYPE string OPTIONAL
        selectedkeys  TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        autoresize    TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        areapress     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_imagemapster IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>leaf(
        view = view
        name = `ImageMapster`
        a    = VALUE #( ( |src={ src }| )
                        ( |areas={ areas }| )
                        ( |config={ config }| )
                        ( |selectedKeys={ selectedkeys }| )
                        ( |width={ width }| )
                        ( |height={ height }| )
                        ( |autoResize={ autoresize }| )
                        ( |libUrl={ liburl }| )
                        ( |areaPress={ areapress }| ) ) ).

  ENDMETHOD.

ENDCLASS.
