"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Counter</p>
"!
"! The ABAP half of the z2ui5cc.cc.Counter custom control: the view builder
"! that emits its XML element.
"!
"! The JavaScript is NOT here - it ships in this repository's own BSP
"! (Z2UI5CC, generated from app/webapp by 'npm run app2bsp'), and the abap2UI5
"! frontend resolves it through the reserved resourceRoot in its manifest.
"! Nothing of this control is known to abap2UI5; the framework only ever sees
"! the finished XML string.
CLASS zcl_z2ui5cc_counter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! XML namespace prefix used for this control library's elements
    CONSTANTS c_ns TYPE string VALUE `z2ui5cc`.
    "! UI5 module namespace the prefix resolves to - the part before `.cc`
    "! matches the resourceRoot key the abap2UI5 frontend reserves in its
    "! manifest.json, which is what makes the BSP findable
    CONSTANTS c_ns_uri TYPE string VALUE `z2ui5cc.cc`.

    "! Emit <z2ui5cc:Counter/> into an existing view.
    "!
    "! Mirrors z2ui5_cl_ai_xml=>leaf: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view    | the builder positioned at the parent element
    "! @parameter text    | label shown left of the counter value
    "! @parameter count   | bind two-way to receive the clicked value back
    "! @parameter press   | client->_event( ... ) fired after every click
    "! @parameter enabled | pass z2ui5_cl_ai_xml=>as_bool( ) for a variable
    "! @parameter result  | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        text          TYPE string OPTIONAL
        count         TYPE string OPTIONAL
        press         TYPE string OPTIONAL
        enabled       TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_counter IMPLEMENTATION.

  METHOD render.

    result = view->leaf( n  = `Counter`
                         ns = c_ns ).

    " only emit the attributes the caller actually set - an empty attribute
    " would override the control's own defaultValue with an empty string
    IF text IS NOT INITIAL.
      result = result->a( n = `text`
                          v = text ).
    ENDIF.

    IF count IS NOT INITIAL.
      result = result->a( n = `count`
                          v = count ).
    ENDIF.

    IF press IS NOT INITIAL.
      result = result->a( n = `press`
                          v = press ).
    ENDIF.

    IF enabled IS NOT INITIAL.
      result = result->a( n = `enabled`
                          v = enabled ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
