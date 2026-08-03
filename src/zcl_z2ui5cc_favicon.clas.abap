"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Favicon</p>
"!
"! The ABAP half of the z2ui5cc.cc.Favicon custom control: the view builder
"! that emits its XML element.
"!
"! Sets the browser tab icon of the running app. Bind <em>href</em> two-way and
"! the icon follows whatever the backend puts into the variable.
"!
"! Ported from abap2UI5-addons/custom-controls (z2ui5_cl_cc_favicon).
CLASS zcl_z2ui5cc_favicon DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit <z2ui5cc:Favicon/> into an existing view.
    "!
    "! @parameter view   | the builder positioned at the parent element
    "! @parameter href   | URL or data: URI of the icon, bind it to change it
    "! @parameter type   | MIME type; empty lets the browser sniff it
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        href          TYPE string OPTIONAL
        type          TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_favicon IMPLEMENTATION.

  METHOD render.

    result = zcl_z2ui5cc=>leaf(
        view = view
        name = `Favicon`
        a    = VALUE #( ( |href={ href }| )
                        ( |type={ type }| ) ) ).

  ENDMETHOD.

ENDCLASS.
