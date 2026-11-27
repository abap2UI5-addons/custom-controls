"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - driver.js</p>
"!
"! The ABAP half of the z2ui5_cci.cc.DriverJs custom control: the view builder
"! that emits its XML element, plus the type tree of a driver.js configuration.
"!
"! Describe the tour as data - one step per control, each with the text of its
"! popover - bind it to <em>config</em>, and raise <em>trigger</em> to start
"! it. <em>element</em> is the id the app gave the control in the view; it is
"! resolved in the frontend, so a step may point into a nested view or a dialog
"! without this class knowing where the control ended up.
"!
"! <em>trigger</em> starts the tour when it changes to a value above 0. A view
"! rebuilt by view_display (a navigation back, say) does not start the last
"! tour again: the value a new control instance is built with counts only when
"! it is not the value the previous instance at the same binding last had. To
"! start a tour in the same roundtrip that first displays the view, raise
"! trigger to a value it has not had yet in this browser tab.
"!
"! The popover texts are plain text: title, description, progress and button
"! texts are escaped before driver.js writes them into the page. Set
"! <em>allowhtml</em> to `true` for simple markup - it is then sanitized with
"! DOMPurify, never inserted as it stands.
"!
"! Bind config and highlight with omit_initial:
"!
"!   config = client->_bind( val          = ms_tour
"!                           omit_initial = abap_true )
"!
"! Without omit_initial every field the app left alone would arrive as 0 or
"! `` and override the driver.js default. The control turns the ABAP field
"! names into the camelCase names driver.js reads (allow_close -&gt;
"! allowClose), so no mapper is needed - the camelCase mapper of older apps
"! still works. An option whose driver.js default is true is a ty_flag, set
"! to cs_flag-false to switch it off; an abap_bool field can only switch an
"! option ON, because omit_initial drops abap_false. The numbers where 0 means
"! something (stage_padding, stage_radius, popover_offset) are text for the
"! same reason: empty keeps the default, `0` is sent.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_driver_js). The
"! original pasted the whole library and its stylesheet into the view as ABAP
"! string literals; both are loaded as a library now. Its `elementview` field
"! is gone, and so are the JavaScript callback strings - the tour reports back
"! through events instead.
CLASS z2ui5_cl_cci_driverjs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! A driver.js option whose default is TRUE: `false`, `true` (abap_true
    "! works as well) or empty for the driver.js default. Not abap_bool,
    "! because omit_initial drops an abap_false - the initial value - and
    "! driver.js would fall back to true. Use cs_flag.
    TYPES ty_flag TYPE string.

    CONSTANTS:
      BEGIN OF cs_flag,
        true  TYPE ty_flag VALUE `true`,
        false TYPE ty_flag VALUE `false`,
      END OF cs_flag.

    CONSTANTS:
      "! Which buttons a popover shows, as a comma separated list.
      "!
      "! driver.js wants a JavaScript array here; the control splits the list.
      "! The addon this was ported from put a JSON array LITERAL into an ABAP
      "! string (<em>['next','close']</em>), which reaches the frontend as a
      "! string and never as an array - so the option silently did nothing.
      BEGIN OF cs_buttons,
        all            TYPE string VALUE `next,previous,close`,
        next           TYPE string VALUE `next`,
        previous       TYPE string VALUE `previous`,
        close          TYPE string VALUE `close`,
        next_previous  TYPE string VALUE `next,previous`,
        next_close     TYPE string VALUE `next,close`,
        previous_close TYPE string VALUE `previous,close`,
      END OF cs_buttons.

    CONSTANTS:
      "! which side of the element the popover sits on
      BEGIN OF cs_side,
        top    TYPE string VALUE `top`,
        right  TYPE string VALUE `right`,
        bottom TYPE string VALUE `bottom`,
        left   TYPE string VALUE `left`,
        over   TYPE string VALUE `over`,
      END OF cs_side.

    CONSTANTS:
      "! how the popover lines up along that side
      BEGIN OF cs_align,
        start  TYPE string VALUE `start`,
        center TYPE string VALUE `center`,
        end    TYPE string VALUE `end`,
      END OF cs_align.

    CONSTANTS:
      "! how the control is started
      BEGIN OF cs_mode,
        "! walk through every step
        tour      TYPE string VALUE `tour`,
        "! spotlight one element, no navigation
        highlight TYPE string VALUE `highlight`,
      END OF cs_mode.

    TYPES:
      "! The bubble shown next to a step's element. `title`, `description`
      "! and the button and progress texts are shown as plain text; with
      "! render( allowhtml = `true` ) they are HTML, sanitized by DOMPurify.
      BEGIN OF ty_s_popover,
        title           TYPE string,
        description     TYPE string,
        side            TYPE string,
        align           TYPE string,
        show_buttons    TYPE string,
        disable_buttons TYPE string,
        next_btn_text   TYPE string,
        prev_btn_text   TYPE string,
        done_btn_text   TYPE string,
        show_progress   TYPE abap_bool,
        progress_text   TYPE string,
        popover_class   TYPE string,
      END OF ty_s_popover.

    TYPES:
      "! One stop of the tour. `element` is the control id as the app wrote it
      "! in the view; a value starting with `#`, `.` or `[` is passed to
      "! driver.js as a CSS selector instead.
      BEGIN OF ty_s_step,
        element TYPE string,
        popover TYPE ty_s_popover,
      END OF ty_s_step.
    TYPES ty_t_step TYPE STANDARD TABLE OF ty_s_step WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_config,
        steps                      TYPE ty_t_step,
        animate                    TYPE ty_flag,
        overlay_color              TYPE string,
        overlay_opacity            TYPE string,
        smooth_scroll              TYPE abap_bool,
        allow_close                TYPE ty_flag,
        allow_keyboard_control     TYPE ty_flag,
        disable_active_interaction TYPE abap_bool,
        "! a number as text: empty keeps the default (10), `0` is no padding
        stage_padding              TYPE string,
        "! a number as text: empty keeps the default (5), `0` square corners
        stage_radius               TYPE string,
        popover_class              TYPE string,
        "! a number as text: empty keeps the default (10), `0` no gap
        popover_offset             TYPE string,
        show_buttons               TYPE string,
        disable_buttons            TYPE string,
        show_progress              TYPE abap_bool,
        progress_text              TYPE string,
        next_btn_text              TYPE string,
        prev_btn_text              TYPE string,
        done_btn_text              TYPE string,
      END OF ty_s_config.

    "! Emit &lt;z2ui5_cci:DriverJs/&gt; into an existing view.
    "!
    "! Boolean parameters take `true` / `false` - pass an ABAP flag through
    "! z2ui5_cl_cci=>bool( ): abap_true arrives as X, and abap_false turns into
    "! an empty string, which drops the attribute, so the default stays.
    "!
    "! @parameter view        | the builder positioned at the parent element
    "! @parameter config      | bind of a ty_s_config structure
    "! @parameter trigger     | bind an integer; raising it starts the tour
    "! @parameter highlight   | bind of a ty_s_step structure, for cs_mode-highlight
    "! @parameter mode        | cs_mode-tour (default) or cs_mode-highlight
    "! @parameter customcss   | extra CSS, e.g. to theme the popover
    "! @parameter liburl      | overrides where driver.js is loaded from
    "! @parameter cssurl      | overrides where its stylesheet is loaded from
    "! @parameter allowhtml   | `true`: the popover texts are HTML, sanitized
    "!                          with DOMPurify; default: plain text, escaped
    "! @parameter purifyurl   | overrides where DOMPurify is loaded from
    "! @parameter highlighted | client->_event( ... ) fired per step
    "! @parameter done        | client->_event( ... ) fired when the tour ends
    "! @parameter result      | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        config        TYPE string OPTIONAL
        trigger       TYPE string OPTIONAL
        highlight     TYPE string OPTIONAL
        mode          TYPE string OPTIONAL
        customcss     TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        cssurl        TYPE string OPTIONAL
        allowhtml     TYPE string OPTIONAL
        purifyurl     TYPE string OPTIONAL
        highlighted   TYPE string OPTIONAL
        done          TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_driverjs IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `DriverJs`
        a    = VALUE #( ( |config={ config }| )
                        ( |trigger={ trigger }| )
                        ( |highlight={ highlight }| )
                        ( |mode={ mode }| )
                        ( |customCss={ customcss }| )
                        ( |libUrl={ liburl }| )
                        ( |cssUrl={ cssurl }| )
                        ( |allowHtml={ allowhtml }| )
                        ( |purifyUrl={ purifyurl }| )
                        ( |highlighted={ highlighted }| )
                        ( |done={ done }| ) ) ).

  ENDMETHOD.

ENDCLASS.
