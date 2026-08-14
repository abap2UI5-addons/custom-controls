"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - library</p>
"!
"! Shared identity of this control library: the XML namespace its elements are
"! emitted under, and the helper that declares it on a view root.
"!
"! The prefix resolves to the UI5 module namespace <em>z2ui5_cci.cc</em>. Its
"! first segment is the resourceRoot the abap2UI5 frontend reserves in its
"! manifest.json, which is what makes this repository's BSP findable:
"!
"!   "sap.ui5": \{ "resourceRoots": \{ "z2ui5_cci": "../z2ui5_cci/" \} \}
"!
"! so <em>z2ui5_cci/cc/SignaturePad</em> is served from
"! <em>/sap/bc/ui5_ui5/sap/z2ui5_cci/cc/SignaturePad.js</em>.
CLASS z2ui5_cl_cci DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! XML namespace prefix used for this library's elements
    CONSTANTS c_ns TYPE string VALUE `z2ui5_cci`.
    "! UI5 module namespace the prefix resolves to
    CONSTANTS c_ns_uri TYPE string VALUE `z2ui5_cci.cc`.

    "! attribute list - one `key=value` string per attribute, e.g.
    "! a = VALUE #( ( `text=Hello` ) ( `width=100%` ) ). Split on the first `=`.
    TYPES ty_t_attr TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Declare the library's XML namespace on a view or fragment root.
    "!
    "! Call it once, on the root element, before adding any control of this
    "! library:
    "!
    "!   DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    "!   DATA(page) = view->ele( n = `View` ns = `mvc`
    "!       )->a( n = `xmlns`     v = `sap.m`
    "!       )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc` ).
    "!   z2ui5_cl_cci=>xmlns( page ).
    "!
    "! @parameter view   | the builder positioned at the root element
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS xmlns
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Emit one element of this library, skipping the attributes the caller
    "! left empty.
    "!
    "! Every control here is a leaf, and every one of them has more optional
    "! attributes than a typical call sets. Passing an EMPTY attribute is not
    "! the same as passing none: it would override the control's own
    "! defaultValue with an empty string. So the builders collect their
    "! parameters as `key=value` strings and let this method drop the ones
    "! whose value is initial.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view   | the builder positioned at the parent element
    "! @parameter name   | element name, without the namespace prefix
    "! @parameter a      | attributes as `key=value`; empty values are dropped
    "! @parameter result | the unchanged view builder, for chaining
    CLASS-METHODS tag
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        name          TYPE string
        a             TYPE ty_t_attr OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci IMPLEMENTATION.

  METHOD xmlns.

    result = view->a( n = |xmlns:{ c_ns }|
                      v = c_ns_uri ).

  ENDMETHOD.

  METHOD tag.

    result = view->tag( n  = name
                        ns = c_ns ).

    LOOP AT a INTO DATA(lv_attr).

      DATA(lv_off) = find( val = lv_attr
                           sub = `=` ).
      " no `=` at all is a malformed attribute, `key=` an unset one - both
      " would end up as an empty attribute value in the rendered XML
      IF lv_off < 1 OR strlen( lv_attr ) <= lv_off + 1.
        CONTINUE.
      ENDIF.

      " a( ) lands on the element the chain points at - the tag just added
      result->a( n = substring( val = lv_attr
                                len = lv_off )
                 v = substring( val = lv_attr
                                off = lv_off + 1 ) ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
