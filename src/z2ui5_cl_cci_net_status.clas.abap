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
    "! serializes as X.
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

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `NetworkStatus`
        a    = VALUE #( ( |status={ status }| )
                        ( |latency={ latency }| )
                        ( |quality={ quality }| )
                        ( |ping={ ping }| )
                        ( |pingUrl={ pingurl }| )
                        ( |pingInterval={ pinginterval }| )
                        ( |pingTimeout={ pingtimeout }| )
                        ( |iconSize={ iconsize }| )
                        ( |showText={ showtext }| )
                        ( |showQuality={ showquality }| )
                        ( |showDetails={ showdetails }| )
                        ( |textOnline={ textonline }| )
                        ( |textUnreachable={ textunreachable }| )
                        ( |textOffline={ textoffline }| )
                        ( |class={ class }| )
                        ( |change={ change }| ) ) ).

  ENDMETHOD.

ENDCLASS.
