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
    "! abap_true, it serializes as X, and never abap_false, which turns into an
    "! empty string: the attribute is dropped and the default stays
    "! (editable = abap_false leaves the field editable). Pass an ABAP flag
    "! through z2ui5_cl_cci=>bool( ).
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
    "! @parameter keepfocus             | `true`: the focus returns into the field. Bound to a flag
    "!                                    per field it is a focus sequence: the field whose flag
    "!                                    turns on takes the focus, also from another field
    "! @parameter selectonfocus         | `true`: the content is selected on focus
    "! @parameter beeponerror           | `true`: a short beep when valuestate turns to Error
    "! @parameter beeponsuccess         | `true`: a short, high tone when valuestate turns to Success
    "! @parameter vibrateonerror        | `true`: a vibration when valuestate turns to Error
    "! @parameter keyboard              | soft keyboard on (`true`, default) or off - bind two-way
    "! @parameter inputmode             | HTML inputmode while the keyboard is on (numeric, text, ...)
    "! @parameter showkeyboardtoggle    | `true`: a keyboard icon in the field switches `keyboard`
    "! @parameter keyboardtoggletooltip | tooltip of that icon, default Keyboard
    "! @parameter uppercase             | `true`: what is typed, scanned or pasted becomes capital
    "!                                    letters in the field; not for a password
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
        beeponsuccess         TYPE string OPTIONAL
        vibrateonerror        TYPE string OPTIONAL
        keyboard              TYPE string OPTIONAL
        inputmode             TYPE string OPTIONAL
        showkeyboardtoggle    TYPE string OPTIONAL
        keyboardtoggletooltip TYPE string OPTIONAL
        uppercase             TYPE string OPTIONAL
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

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `ScanInput`
        a    = VALUE #( ( |id={ id }| )
                        ( |value={ value }| )
                        ( |valueState={ valuestate }| )
                        ( |valueStateText={ valuestatetext }| )
                        ( |showValueStateMessage={ showvaluestatemessage }| )
                        ( |placeholder={ placeholder }| )
                        ( |enabled={ enabled }| )
                        ( |editable={ editable }| )
                        ( |visible={ visible }| )
                        ( |width={ width }| )
                        ( |maxLength={ maxlength }| )
                        ( |type={ type }| )
                        ( |keepFocus={ keepfocus }| )
                        ( |selectOnFocus={ selectonfocus }| )
                        ( |beepOnError={ beeponerror }| )
                        ( |beepOnSuccess={ beeponsuccess }| )
                        ( |vibrateOnError={ vibrateonerror }| )
                        ( |keyboard={ keyboard }| )
                        ( |inputMode={ inputmode }| )
                        ( |showKeyboardToggle={ showkeyboardtoggle }| )
                        ( |keyboardToggleTooltip={ keyboardtoggletooltip }| )
                        ( |upperCase={ uppercase }| )
                        ( |class={ class }| )
                        ( |submit={ submit }| )
                        ( |change={ change }| )
                        ( |keyboardChange={ keyboardchange }| ) ) ).

  ENDMETHOD.

ENDCLASS.
