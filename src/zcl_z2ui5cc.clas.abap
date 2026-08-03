"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - library</p>
"!
"! Shared identity of this control library: the XML namespace its elements are
"! emitted under, and the helper that declares it on a view root.
"!
"! The prefix resolves to the UI5 module namespace <em>z2ui5cc.cc</em>. Its
"! first segment is the resourceRoot the abap2UI5 frontend reserves in its
"! manifest.json, which is what makes this repository's BSP findable:
"!
"!   "sap.ui5": \{ "resourceRoots": \{ "z2ui5cc": "../z2ui5cc/" \} \}
"!
"! so <em>z2ui5cc/cc/Counter</em> is served from
"! <em>/sap/bc/ui5_ui5/sap/z2ui5cc/cc/Counter.js</em>.
CLASS zcl_z2ui5cc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! XML namespace prefix used for this library's elements
    CONSTANTS c_ns TYPE string VALUE `z2ui5cc`.
    "! UI5 module namespace the prefix resolves to
    CONSTANTS c_ns_uri TYPE string VALUE `z2ui5cc.cc`.

    "! Declare the library's XML namespace on a view or fragment root.
    "!
    "! Call it once, on the root element, before adding any control of this
    "! library:
    "!
    "!   DATA(view) = z2ui5_cl_ai_xml=>factory( ).
    "!   DATA(page) = view->open( n = `View` ns = `mvc`
    "!       )->a( n = `xmlns`     v = `sap.m`
    "!       )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).
    "!   zcl_z2ui5cc=>xmlns( page ).
    "!
    "! @parameter view   | the builder positioned at the root element
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS xmlns
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc IMPLEMENTATION.

  METHOD xmlns.

    result = view->a( n = |xmlns:{ c_ns }|
                      v = c_ns_uri ).

  ENDMETHOD.

ENDCLASS.
