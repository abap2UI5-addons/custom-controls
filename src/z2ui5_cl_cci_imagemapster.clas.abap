"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - ImageMapster</p>
"!
"! The ABAP half of the z2ui5_cci.cc.ImageMapster custom control: the view
"! builder that emits its XML element, plus the types for the regions and the
"! render options.
"!
"! A plain HTML image map gives a clickable region and nothing else. This one
"! highlights the region under the mouse, keeps a selection, writes it back
"! into the model and raises a normal abap2UI5 event with the key of the region
"! that was clicked - so a floor plan, a machine drawing or a map becomes an
"! input control.
"!
"! Bind areas and config with omit_initial:
"!
"!   config = client->_bind( val          = ms_config
"!                           omit_initial = abap_true )
"!
"! The control turns the ABAP field names of config into camelCase itself
"! (fill_color -&gt; fillColor), so no mapper is needed - the camelCase mapper of
"! older apps still works for config (not for areas, whose fields are read
"! upper case). An option whose default is true (fill, fade, highlight,
"! is_selectable, is_deselectable, and an area's isselectable) is a ty_flag,
"! set to cs_flag-false to switch it off; an abap_bool field can only switch an
"! option ON, because omit_initial drops abap_false.
"!
"! The regions are drawn as an SVG overlay whose viewBox is the image's
"! natural pixel space - the same space the HTML image map <em>coords</em> are
"! written in. The browser scales it with the image, so there is nothing to
"! resize and no library to load. It used to be the jquery.imagemapster plugin
"! on a canvas, which was the only reason anything here needed jQuery.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_imagemapster). The
"! image-map editor that repository shipped next to it is not part of the port:
"! it is an authoring tool for coordinates, not a control.
CLASS z2ui5_cl_cci_imagemapster DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! An option whose default is TRUE: `false`, `true` (abap_true works as
    "! well) or empty for the default. Not abap_bool, because omit_initial
    "! drops an abap_false - the initial value - and the control would fall
    "! back to true. Use cs_flag.
    TYPES ty_flag TYPE string.

    CONSTANTS:
      BEGIN OF cs_flag,
        true  TYPE ty_flag VALUE `true`,
        false TYPE ty_flag VALUE `false`,
      END OF cs_flag.

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
        "! not used - an area is a button that raises areaPress, not a link
        href         TYPE string,
        fillcolor    TYPE string,
        fillopacity  TYPE string,
        strokecolor  TYPE string,
        "! start out selected - taken over once, while selectedKeys is empty
        selected     TYPE abap_bool,
        "! always drawn, cannot be turned off by the user
        staticstate  TYPE abap_bool,
        "! cs_flag-false: this area cannot be selected
        isselectable TYPE ty_flag,
      END OF ty_s_area.
    TYPES ty_t_area TYPE STANDARD TABLE OF ty_s_area WITH EMPTY KEY.

    TYPES:
      "! How a region is drawn in one state.
      BEGIN OF ty_s_render,
        fill           TYPE ty_flag,
        fill_color     TYPE string,
        fill_opacity   TYPE string,
        stroke         TYPE ty_flag,
        stroke_color   TYPE string,
        stroke_opacity TYPE string,
        stroke_width   TYPE i,
        fade           TYPE ty_flag,
        fade_duration  TYPE i,
      END OF ty_s_render.

    TYPES:
      "! Map-wide options. Colours are hex WITHOUT a leading `#`, the way
      "! ImageMapster wants them: `ff0000`, not `#ff0000`.
      BEGIN OF ty_s_config,
        fill             TYPE ty_flag,
        fill_color       TYPE string,
        fill_opacity     TYPE string,
        stroke           TYPE abap_bool,
        stroke_color     TYPE string,
        stroke_opacity   TYPE string,
        stroke_width     TYPE i,
        highlight        TYPE ty_flag,
        fade             TYPE ty_flag,
        fade_duration    TYPE i,
        single_select    TYPE abap_bool,
        is_selectable    TYPE ty_flag,
        is_deselectable  TYPE ty_flag,
        static_state     TYPE abap_bool,
        mouseout_delay   TYPE i,
        "! IGNORED - the SVG overlay always scales with the image
        scale_map        TYPE abap_bool,
        wrap_class       TYPE string,
        alt_image        TYPE string,
        render_highlight TYPE ty_s_render,
        render_select    TYPE ty_s_render,
      END OF ty_s_config.

    "! Emit &lt;z2ui5_cci:ImageMapster/&gt; into an existing view.
    "!
    "! @parameter view         | the builder positioned at the parent element
    "! @parameter src          | the image, as a URL or a data: URI
    "! @parameter areas        | bind of a ty_t_area table
    "! @parameter config       | bind of a ty_s_config structure
    "! @parameter selectedkeys | bind two-way; comma separated area keys
    "! @parameter width        | CSS width of the image
    "! @parameter height       | CSS height; empty keeps the aspect ratio
    "! @parameter autoresize   | IGNORED since the control was rebuilt on an
    "!                           SVG overlay - the overlay is scaled by the
    "!                           browser, so there is no resize to switch off.
    "!                           Kept so existing callers still compile
    "! @parameter liburl       | IGNORED since the control was rebuilt on an
    "!                           SVG overlay - it loads no library at all now.
    "!                           Kept so existing callers still compile
    "! @parameter areapress    | client->_event( ... ) fired on a click into
    "!                           a region
    "! @parameter result       | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        src           TYPE string
        areas         TYPE string OPTIONAL
        config        TYPE string OPTIONAL
        selectedkeys  TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        " Not emitted any more: the SVG overlay scales itself and loads
        " nothing, so the control has no such properties. They stay in the
        " signature because removing an optional parameter breaks the compile
        " of every caller that passes it - a no-op beats a syntax error.
        autoresize    TYPE string OPTIONAL ##NEEDED
        liburl        TYPE string OPTIONAL ##NEEDED
        areapress     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_imagemapster IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `ImageMapster`
        a    = VALUE #( ( |src={ src }| )
                        ( |areas={ areas }| )
                        ( |config={ config }| )
                        ( |selectedKeys={ selectedkeys }| )
                        ( |width={ width }| )
                        ( |height={ height }| )
                        ( |areaPress={ areapress }| ) ) ).


  ENDMETHOD.

ENDCLASS.
