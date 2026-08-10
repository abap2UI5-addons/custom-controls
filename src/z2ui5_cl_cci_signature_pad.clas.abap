"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - SignaturePad</p>
"!
"! The ABAP half of the z2ui5_cci.cc.SignaturePad custom control: the view
"! builder that emits its XML element.
"!
"! The JavaScript ships in this repository's own BSP (Z2UI5_CCI, generated from
"! app/webapp by 'npm run app2bsp'); the abap2UI5 frontend resolves it through
"! the reserved resourceRoot in its manifest. Nothing of this control is known
"! to abap2UI5.
"!
"! The signature arrives as a base64 PNG data URL in the bound `value` - the
"! same shape the framework's CameraPicture uses for photos. Clearing is
"! backend-driven: set the bound variable to empty and the pad is blank after
"! the next roundtrip.
CLASS z2ui5_cl_cci_signature_pad DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit &lt;z2ui5_cci:SignaturePad/&gt; into an existing view.
    "!
    "! Mirrors z2ui5_cl_ai_xml=>leaf: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view      | the builder positioned at the parent element
    "! @parameter value     | bind two-way to receive the base64 PNG
    "! @parameter width     | CSS size; a bare number is treated as px
    "! @parameter height    | CSS size; a bare number is treated as px
    "! @parameter linewidth | stroke width in CSS pixels
    "! @parameter linecolor | stroke colour, any CSS colour
    "! @parameter editable  | pass z2ui5_cl_ai_xml=>as_bool( ) for a variable
    "! @parameter change    | client->_event( ... ) fired when a stroke ends
    "! @parameter result    | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        value         TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        linewidth     TYPE string OPTIONAL
        linecolor     TYPE string OPTIONAL
        editable      TYPE string OPTIONAL
        change        TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_signature_pad IMPLEMENTATION.

  METHOD render.

    result = view->leaf( n  = `SignaturePad`
                         ns = z2ui5_cl_cci=>c_ns ).

    " only emit the attributes the caller actually set - an empty attribute
    " would override the control's own defaultValue with an empty string
    IF value IS NOT INITIAL.
      result = result->a( n = `value`
                          v = value ).
    ENDIF.

    IF width IS NOT INITIAL.
      result = result->a( n = `width`
                          v = width ).
    ENDIF.

    IF height IS NOT INITIAL.
      result = result->a( n = `height`
                          v = height ).
    ENDIF.

    IF linewidth IS NOT INITIAL.
      result = result->a( n = `lineWidth`
                          v = linewidth ).
    ENDIF.

    IF linecolor IS NOT INITIAL.
      result = result->a( n = `lineColor`
                          v = linecolor ).
    ENDIF.

    IF editable IS NOT INITIAL.
      result = result->a( n = `editable`
                          v = editable ).
    ENDIF.

    IF change IS NOT INITIAL.
      result = result->a( n = `change`
                          v = change ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
