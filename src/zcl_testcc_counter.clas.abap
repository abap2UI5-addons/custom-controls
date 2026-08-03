"! <p class="shorttext synchronized" lang="en">test-cc - Counter custom control</p>
"!
"! The ABAP half of the testcc.cc.Counter custom control: the view builder
"! that emits its XML element, plus the accessor for the JavaScript that
"! defines it in the browser.
"!
"! One class per custom control keeps a control self-contained - its markup,
"! its JavaScript and its documentation travel together and can be deleted in
"! one go. Nothing here is known to abap2UI5; the framework only ever sees the
"! finished XML string.
CLASS zcl_testcc_counter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! XML namespace prefix used for this control library's elements
    CONSTANTS c_ns TYPE string VALUE `testcc`.
    "! UI5 module namespace the prefix resolves to
    CONSTANTS c_ns_uri TYPE string VALUE `testcc.cc`.

    "! The JavaScript defining testcc.cc.Counter - collected by
    "! ZCL_TESTCC_BOOTSTRAP and delivered to the browser at bootstrap.
    CLASS-METHODS get_js
      RETURNING
        VALUE(result) TYPE string.

    "! Emit <testcc:Counter/> into an existing view.
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


CLASS zcl_testcc_counter IMPLEMENTATION.

  METHOD get_js.

    result = zcl_testcc_counter_js=>get( ).

  ENDMETHOD.

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
