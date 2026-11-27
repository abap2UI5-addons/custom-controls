"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - NetworkStatus</p>
"!
"! The ABAP half of the z2ui5_cci.cc.NetworkStatus custom control: the view
"! builder that emits its XML element.
"!
"! The control shows whether the browser is online and the server answers -
"! a green, orange or red icon, optionally with a text, signal bars and the
"! measured latency. It works in the browser alone: it listens to the
"! browser's online/offline events and pings `pingurl` (default: the ICF
"! service /sap/public/ping, which has to be active in SICF). Nothing of it
"! reaches ABAP unless you bind `status`, `latency` or `quality`, or set
"! `change`.
"!
"! The JavaScript ships in this repository's own BSP (Z2UI5_CCI); see
"! z2ui5_cl_cci for how the abap2UI5 frontend finds it.
CLASS z2ui5_cl_cci_net_status DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit &lt;z2ui5_cci:NetworkStatus/&gt; into an existing view.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! Boolean parameters take `true` / `false` - never abap_true, it
    "! serializes as X, and never abap_false, which turns into an empty string:
    "! the attribute is dropped and the default stays. Pass an ABAP flag
    "! through z2ui5_cl_cci=>bool( ).
    "!
    "! @parameter view            | the builder positioned at the parent element
    "! @parameter status          | bind to receive online / unreachable / offline
    "! @parameter latency         | bind to receive the ping round trip in ms, -1 while unknown
    "! @parameter quality         | bind to receive the signal bars, 0 - 4
    "! @parameter ping            | `false`: no ping, only the browser's online flag
    "! @parameter pingurl         | URL to ping, default /sap/public/ping
    "! @parameter pinginterval    | ms between two pings, default 5000
    "! @parameter pingtimeout     | ms without answer that count as unreachable, default 3000
    "! @parameter iconsize        | CSS size of the icon
    "! @parameter showtext        | `true`: the status as text next to the icon
    "! @parameter showquality     | `true`: four signal bars
    "! @parameter showdetails     | `true`: latency and network type as text
    "! @parameter textonline      | text for online, default Online
    "! @parameter textunreachable | text for unreachable, default Server not reachable
    "! @parameter textoffline     | text for offline, default Offline
    "! @parameter class           | CSS classes, e.g. sapUiSmallMarginBegin
    "! @parameter change          | client->_event( ... ) fired when the status changes
    "! @parameter result          | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view            TYPE REF TO z2ui5_cl_ui5_view_builder
        status          TYPE string OPTIONAL
        latency         TYPE string OPTIONAL
        quality         TYPE string OPTIONAL
        ping            TYPE string OPTIONAL
        pingurl         TYPE string OPTIONAL
        pinginterval    TYPE string OPTIONAL
        pingtimeout     TYPE string OPTIONAL
        iconsize        TYPE string OPTIONAL
        showtext        TYPE string OPTIONAL
        showquality     TYPE string OPTIONAL
        showdetails     TYPE string OPTIONAL
        textonline      TYPE string OPTIONAL
        textunreachable TYPE string OPTIONAL
        textoffline     TYPE string OPTIONAL
        class           TYPE string OPTIONAL
        change          TYPE string OPTIONAL
      RETURNING
        VALUE(result)   TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_net_status IMPLEMENTATION.

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
    CLEAR temp1.

    temp2 = |status={ status }|.
    INSERT temp2 INTO TABLE temp1.

    temp3 = |latency={ latency }|.
    INSERT temp3 INTO TABLE temp1.

    temp4 = |quality={ quality }|.
    INSERT temp4 INTO TABLE temp1.

    temp5 = |ping={ ping }|.
    INSERT temp5 INTO TABLE temp1.

    temp6 = |pingUrl={ pingurl }|.
    INSERT temp6 INTO TABLE temp1.

    temp7 = |pingInterval={ pinginterval }|.
    INSERT temp7 INTO TABLE temp1.

    temp8 = |pingTimeout={ pingtimeout }|.
    INSERT temp8 INTO TABLE temp1.

    temp9 = |iconSize={ iconsize }|.
    INSERT temp9 INTO TABLE temp1.

    temp10 = |showText={ showtext }|.
    INSERT temp10 INTO TABLE temp1.

    temp11 = |showQuality={ showquality }|.
    INSERT temp11 INTO TABLE temp1.

    temp12 = |showDetails={ showdetails }|.
    INSERT temp12 INTO TABLE temp1.

    temp13 = |textOnline={ textonline }|.
    INSERT temp13 INTO TABLE temp1.

    temp14 = |textUnreachable={ textunreachable }|.
    INSERT temp14 INTO TABLE temp1.

    temp15 = |textOffline={ textoffline }|.
    INSERT temp15 INTO TABLE temp1.

    temp16 = |class={ class }|.
    INSERT temp16 INTO TABLE temp1.

    temp17 = |change={ change }|.
    INSERT temp17 INTO TABLE temp1.
    result = z2ui5_cl_cci=>tag(
        view = view
        name = `NetworkStatus`
        a    = temp1 ).

  ENDMETHOD.

ENDCLASS.
