"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - ScanInput</p>
"!
"! The ABAP half of the z2ui5_cci.cc.ScanInput custom control: the view
"! builder that emits its XML element.
"!
"! A sap.m.Input for barcode scanning. In the browser, without a roundtrip:
"! it keeps the focus (after every response and after a popup closed - never
"! while another text field or a popup has it, never into a hidden or
"! disabled field), selects its content on focus so the next scan replaces
"! it, beeps and vibrates when `valuestate` turns to Error, and switches the
"! soft keyboard on and off (`keyboard`, bound two-way, optionally with its
"! own toggle icon). Everything else is sap.m.Input: value, value state,
"! placeholder, the event `submit` on Enter - which a scanner sends as its
"! suffix.
"!
"! The JavaScript ships in this repository's own BSP (Z2UI5_CCI); see
"! z2ui5_cl_cci for how the abap2UI5 frontend finds it.
CLASS z2ui5_cl_cci_scan_input DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit &lt;z2ui5_cci:ScanInput/&gt; into an existing view.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! Boolean parameters take `true` / `false` or a binding - never
    "! abap_true, it serializes as X.
    "!
    "! @parameter view                  | the builder positioned at the parent element
    "! @parameter id                    | control id, e.g. for SET_FOCUS
    "! @parameter value                 | the field's value, bind two-way
    "! @parameter valuestate            | None, Success, Warning, Error, Information - Error beeps
    "! @parameter valuestatetext        | text of the value state message
    "! @parameter showvaluestatemessage | `false`: no message popup under the field
    "! @parameter placeholder           | placeholder text
    "! @parameter enabled               | `false` disables the field
    "! @parameter editable              | `false` makes it read-only
    "! @parameter visible               | `false` hides it
    "! @parameter width                 | CSS width
    "! @parameter maxlength             | maximum number of characters
    "! @parameter type                  | sap.m.InputType - Text, Number, ...
    "! @parameter keepfocus             | `true`: the focus returns into the field
    "! @parameter selectonfocus         | `true`: the content is selected on focus
    "! @parameter beeponerror           | `true`: a short beep when valuestate turns to Error
    "! @parameter vibrateonerror        | `true`: a vibration when valuestate turns to Error
    "! @parameter keyboard              | soft keyboard on (`true`, default) or off - bind two-way
    "! @parameter inputmode             | HTML inputmode while the keyboard is on (numeric, text, ...)
    "! @parameter showkeyboardtoggle    | `true`: a keyboard icon in the field switches `keyboard`
    "! @parameter keyboardtoggletooltip | tooltip of that icon, default Keyboard
    "! @parameter class                 | CSS classes
    "! @parameter submit                | client->_event( ... ) on Enter - a scanner's suffix
    "! @parameter change                | client->_event( ... ) when the value was changed
    "! @parameter keyboardchange        | client->_event( ... ) when the user switched the keyboard
    "! @parameter result                | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view                  TYPE REF TO z2ui5_cl_ui5_view_builder
        id                    TYPE string OPTIONAL
        value                 TYPE string OPTIONAL
        valuestate            TYPE string OPTIONAL
        valuestatetext        TYPE string OPTIONAL
        showvaluestatemessage TYPE string OPTIONAL
        placeholder           TYPE string OPTIONAL
        enabled               TYPE string OPTIONAL
        editable              TYPE string OPTIONAL
        visible               TYPE string OPTIONAL
        width                 TYPE string OPTIONAL
        maxlength             TYPE string OPTIONAL
        type                  TYPE string OPTIONAL
        keepfocus             TYPE string OPTIONAL
        selectonfocus         TYPE string OPTIONAL
        beeponerror           TYPE string OPTIONAL
        vibrateonerror        TYPE string OPTIONAL
        keyboard              TYPE string OPTIONAL
        inputmode             TYPE string OPTIONAL
        showkeyboardtoggle    TYPE string OPTIONAL
        keyboardtoggletooltip TYPE string OPTIONAL
        class                 TYPE string OPTIONAL
        submit                TYPE string OPTIONAL
        change                TYPE string OPTIONAL
        keyboardchange        TYPE string OPTIONAL
      RETURNING
        VALUE(result)         TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_scan_input IMPLEMENTATION.

  METHOD render.

    DATA temp1 TYPE z2ui5_cl_cci=>ty_t_attr.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 LIKE LINE OF temp1.
    DATA temp4 LIKE LINE OF temp1.
    DATA temp5 LIKE LINE OF temp1.
    DATA temp6 LIKE LINE OF temp1.
    DATA temp7 LIKE LINE OF temp1.
    DATA temp8 LIKE LINE OF temp1.
    DATA temp9 LIKE LINE OF temp1.
    DATA temp10 LIKE LINE OF temp1.
    DATA temp11 LIKE LINE OF temp1.
    DATA temp12 LIKE LINE OF temp1.
    DATA temp13 LIKE LINE OF temp1.
    DATA temp14 LIKE LINE OF temp1.
    DATA temp15 LIKE LINE OF temp1.
    DATA temp16 LIKE LINE OF temp1.
    DATA temp17 LIKE LINE OF temp1.
    DATA temp18 LIKE LINE OF temp1.
    DATA temp19 LIKE LINE OF temp1.
    DATA temp20 LIKE LINE OF temp1.
    DATA temp21 LIKE LINE OF temp1.
    DATA temp22 LIKE LINE OF temp1.
    DATA temp23 LIKE LINE OF temp1.
    DATA temp24 LIKE LINE OF temp1.
    DATA temp25 LIKE LINE OF temp1.
    CLEAR temp1.

    temp2 = |id={ id }|.
    INSERT temp2 INTO TABLE temp1.

    temp3 = |value={ value }|.
    INSERT temp3 INTO TABLE temp1.

    temp4 = |valueState={ valuestate }|.
    INSERT temp4 INTO TABLE temp1.

    temp5 = |valueStateText={ valuestatetext }|.
    INSERT temp5 INTO TABLE temp1.

    temp6 = |showValueStateMessage={ showvaluestatemessage }|.
    INSERT temp6 INTO TABLE temp1.

    temp7 = |placeholder={ placeholder }|.
    INSERT temp7 INTO TABLE temp1.

    temp8 = |enabled={ enabled }|.
    INSERT temp8 INTO TABLE temp1.

    temp9 = |editable={ editable }|.
    INSERT temp9 INTO TABLE temp1.

    temp10 = |visible={ visible }|.
    INSERT temp10 INTO TABLE temp1.

    temp11 = |width={ width }|.
    INSERT temp11 INTO TABLE temp1.

    temp12 = |maxLength={ maxlength }|.
    INSERT temp12 INTO TABLE temp1.

    temp13 = |type={ type }|.
    INSERT temp13 INTO TABLE temp1.

    temp14 = |keepFocus={ keepfocus }|.
    INSERT temp14 INTO TABLE temp1.

    temp15 = |selectOnFocus={ selectonfocus }|.
    INSERT temp15 INTO TABLE temp1.

    temp16 = |beepOnError={ beeponerror }|.
    INSERT temp16 INTO TABLE temp1.

    temp17 = |vibrateOnError={ vibrateonerror }|.
    INSERT temp17 INTO TABLE temp1.

    temp18 = |keyboard={ keyboard }|.
    INSERT temp18 INTO TABLE temp1.

    temp19 = |inputMode={ inputmode }|.
    INSERT temp19 INTO TABLE temp1.

    temp20 = |showKeyboardToggle={ showkeyboardtoggle }|.
    INSERT temp20 INTO TABLE temp1.

    temp21 = |keyboardToggleTooltip={ keyboardtoggletooltip }|.
    INSERT temp21 INTO TABLE temp1.

    temp22 = |class={ class }|.
    INSERT temp22 INTO TABLE temp1.

    temp23 = |submit={ submit }|.
    INSERT temp23 INTO TABLE temp1.

    temp24 = |change={ change }|.
    INSERT temp24 INTO TABLE temp1.

    temp25 = |keyboardChange={ keyboardchange }|.
    INSERT temp25 INTO TABLE temp1.
    result = z2ui5_cl_cci=>tag(
        view = view
        name = `ScanInput`
        a    = temp1 ).

  ENDMETHOD.

ENDCLASS.
