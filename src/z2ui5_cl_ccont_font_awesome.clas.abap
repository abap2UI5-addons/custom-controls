"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Font Awesome</p>
"!
"! The ABAP half of the z2ui5cc.cc.FontAwesome custom control: the view builder
"! that emits its XML element.
"!
"! Put it once into a view and Font Awesome is available two ways:
"!
"!   as UI5 icons  <em>sap-icon://fa-solid/heart</em> in any icon property
"!   as CSS classes <em>class="fa-brands fa-github"</em> on any control, and
"!                  the Font Awesome animations like <em>fa-bounce</em>
"!
"! The UI5 IconPool needs a font directory that also holds the metadata JSON
"! mapping icon names to code points; see the control for the default.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_font_awesome).
CLASS z2ui5_cl_ccont_font_awesome DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      "! The icon collections the control can register. Use them as the
      "! collection part of an icon URI: <em>sap-icon://fa-solid/heart</em>.
      BEGIN OF cs_collection,
        regular       TYPE string VALUE `fa-regular`,
        solid         TYPE string VALUE `fa-solid`,
        light         TYPE string VALUE `fa-light`,
        thin          TYPE string VALUE `fa-thin`,
        duotone       TYPE string VALUE `fa-duotone`,
        brands        TYPE string VALUE `fa-brands`,
        sharp_solid   TYPE string VALUE `fa-sharp-solid`,
        sharp_regular TYPE string VALUE `fa-sharp-regular`,
        sharp_light   TYPE string VALUE `fa-sharp-light`,
      END OF cs_collection.

    "! Emit &lt;z2ui5cc:FontAwesome/&gt; into an existing view.
    "!
    "! @parameter view        | the builder positioned at the parent element
    "! @parameter fonturi     | directory holding the webfonts and their
    "!                          metadata JSON; overrides the default bundle
    "! @parameter collections | comma separated cs_collection values; empty
    "!                          registers all of them
    "! @parameter cssurl      | Font Awesome stylesheet for the class names;
    "!                          pass a space to skip it
    "! @parameter result      | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        fonturi       TYPE string OPTIONAL
        collections   TYPE string OPTIONAL
        cssurl        TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccont_font_awesome IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_ccont=>leaf(
        view = view
        name = `FontAwesome`
        a    = VALUE #( ( |fontUri={ fonturi }| )
                        ( |collections={ collections }| )
                        ( |cssUrl={ cssurl }| ) ) ).

  ENDMETHOD.

ENDCLASS.
