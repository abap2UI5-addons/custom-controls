"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - image map editor</p>
"!
"! The ABAP half of the z2ui5cc.cc.ImageMapEditor custom control: the view
"! builder that emits its XML element.
"!
"! The companion of zcl_z2ui5cc_imagemapster - that one renders a map, this one
"! produces the coordinates for it. Show a picture, let the user draw
"! rectangles, circles and polygons over it, raise <em>trigger</em>, and the
"! regions arrive in <em>areas</em> as a
"! zcl_z2ui5cc_imagemapster=>ty_t_area table, ready to be handed straight to
"! the ImageMapster control.
"!
"! The editor itself is a standalone page in this repository's BSP, shown in an
"! iframe - its stylesheet resets every element on the page, so it cannot share
"! a document with a UI5 view. <em>editorurl</em> points at that page by
"! default and is a plain property, so the editor may equally be served from
"! another BSP, a web server or a CDN.
"!
"! Ported from abap2UI5-addons/js-libraries, where the editor was three ABAP
"! methods holding ~3000 lines of XML-escaped HTML, CSS and JavaScript, and
"! where what the user drew never reached ABAP at all - it went into the
"! browser's localStorage, or into a text box to copy out by hand.
CLASS zcl_z2ui5cc_imagemap_editor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit <z2ui5cc:ImageMapEditor/> into an existing view.
    "!
    "! @parameter view      | the builder positioned at the parent element
    "! @parameter src       | the picture to draw on, URL or data: URI
    "! @parameter filename  | name the editor shows for the picture
    "! @parameter areas     | bind two-way to receive a ty_t_area table
    "! @parameter trigger   | bind an integer; raising it collects the regions
    "! @parameter editorurl | overrides where the editor page is served from
    "! @parameter width     | CSS width of the iframe
    "! @parameter height    | CSS height of the iframe
    "! @parameter ready     | client->_event( ... ) fired once the editor is up
    "! @parameter collected | client->_event( ... ) fired after every collect
    "! @parameter result    | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        src           TYPE string
        areas         TYPE string
        trigger       TYPE string
        filename      TYPE string OPTIONAL
        editorurl     TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        ready         TYPE string OPTIONAL
        collected     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_imagemap_editor IMPLEMENTATION.

  METHOD render.

    result = zcl_z2ui5cc=>leaf(
        view = view
        name = `ImageMapEditor`
        a    = VALUE #( ( |src={ src }| )
                        ( |fileName={ filename }| )
                        ( |areas={ areas }| )
                        ( |trigger={ trigger }| )
                        ( |editorUrl={ editorurl }| )
                        ( |width={ width }| )
                        ( |height={ height }| )
                        ( |ready={ ready }| )
                        ( |collected={ collected }| ) ) ).

  ENDMETHOD.

ENDCLASS.
