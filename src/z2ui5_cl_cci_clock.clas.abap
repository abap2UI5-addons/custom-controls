"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Clock</p>
"!
"! The ABAP half of the z2ui5_cci.cc.Clock custom control: the view builder
"! that emits its XML element.
"!
"! The control shows the browser's current date and time and ticks every
"! second, without a roundtrip to ABAP. It is an sap.m.Button underneath, so
"! it can sit in an OverflowToolbar and move into its overflow menu like any
"! other button - pass `priority` for that.
"!
"! The JavaScript ships in this repository's own BSP (Z2UI5_CCI); see
"! z2ui5_cl_cci for how the abap2UI5 frontend finds it.
CLASS z2ui5_cl_cci_clock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit &lt;z2ui5_cci:Clock/&gt; into an existing view.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view     | the builder positioned at the parent element
    "! @parameter format   | datetime (default), date, time or shorttime
    "! @parameter locale   | BCP 47 tag such as de-DE; default: the UI5 language
    "! @parameter icon     | e.g. sap-icon://history
    "! @parameter type     | button type, default Transparent
    "! @parameter enabled  | `true` / `false` - never abap_true, it serializes as X
    "! @parameter width    | CSS width
    "! @parameter tooltip  | tooltip text
    "! @parameter class    | CSS classes
    "! @parameter priority | OverflowToolbarLayoutData priority, e.g. AlwaysOverflow -
    "!                        only inside an OverflowToolbar
    "! @parameter result   | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        format        TYPE string OPTIONAL
        locale        TYPE string OPTIONAL
        icon          TYPE string OPTIONAL
        type          TYPE string OPTIONAL
        enabled       TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        tooltip       TYPE string OPTIONAL
        class         TYPE string OPTIONAL
        priority      TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_clock IMPLEMENTATION.

  METHOD render.

    TYPES:
      BEGIN OF ty_s_attr,
        n TYPE string,
        v TYPE string,
      END OF ty_s_attr.
    DATA lt_attr TYPE STANDARD TABLE OF ty_s_attr WITH DEFAULT KEY.
    DATA clock TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA temp1 LIKE lt_attr.
    DATA temp2 LIKE LINE OF temp1.
    DATA ls_attr LIKE LINE OF lt_attr.

    result = view.

    " ele( ), not z2ui5_cl_cci=>tag( ): the layout data below goes INTO the
    " element, so the builder has to hold on to it

    clock = view->ele( n  = `Clock`
                             ns = z2ui5_cl_cci=>c_ns ).


    CLEAR temp1.

    temp2-n = `format`.
    temp2-v = format.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `locale`.
    temp2-v = locale.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `icon`.
    temp2-v = icon.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `type`.
    temp2-v = type.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `enabled`.
    temp2-v = enabled.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `width`.
    temp2-v = width.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `tooltip`.
    temp2-v = tooltip.
    INSERT temp2 INTO TABLE temp1.
    temp2-n = `class`.
    temp2-v = class.
    INSERT temp2 INTO TABLE temp1.
    lt_attr = temp1.

    " an empty attribute would override the control's own default - drop it.
    " a( ) lands on the clock as long as it has no child yet.

    LOOP AT lt_attr INTO ls_attr WHERE v IS NOT INITIAL.
      clock->a( n = ls_attr-n
                v = ls_attr-v ).
    ENDLOOP.

    IF priority IS INITIAL.
      RETURN.
    ENDIF.

    " the aggregation tag takes the namespace of its own control -
    " <z2ui5_cci:layoutData>, never <layoutData>
    clock->ele( n  = `layoutData`
                ns = z2ui5_cl_cci=>c_ns
        )->tag( `OverflowToolbarLayoutData`
            )->a( n = `priority`
                  v = priority ).

  ENDMETHOD.

ENDCLASS.
