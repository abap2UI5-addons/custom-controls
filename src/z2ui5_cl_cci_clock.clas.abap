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
    "! @parameter enabled  | `true` / `false` - never abap_true (X) or abap_false (dropped: the default stays) - pass z2ui5_cl_cci=>bool( flag )
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

    result = view.

    " ele, not tag: the layout data below goes INTO the element, so the
    " builder has to hold on to it
    DATA(clock) = z2ui5_cl_cci=>ele(
        view = view
        name = `Clock`
        a    = VALUE #( ( |format={ format }| )
                        ( |locale={ locale }| )
                        ( |icon={ icon }| )
                        ( |type={ type }| )
                        ( |enabled={ enabled }| )
                        ( |width={ width }| )
                        ( |tooltip={ tooltip }| )
                        ( |class={ class }| ) ) ).

    IF priority IS INITIAL.
      RETURN.
    ENDIF.

    " the aggregation tag takes the namespace of its own control -
    " <z2ui5_cci:layoutData>, never <layoutData>. The layout data is a sap.m
    " control, and the view's default namespace need not be sap.m (a view
    " written with an m: prefix), so the element declares it itself
    clock->ele( n  = `layoutData`
                ns = z2ui5_cl_cci=>c_ns
        )->tag( `OverflowToolbarLayoutData`
            )->a( n = `xmlns`
                  v = `sap.m`
            )->a( n = `priority`
                  v = priority ).

  ENDMETHOD.

ENDCLASS.
