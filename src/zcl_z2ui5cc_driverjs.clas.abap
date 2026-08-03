"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - driver.js</p>
"!
"! The ABAP half of the z2ui5cc.cc.DriverJs custom control: the view builder
"! that emits its XML element, plus the type tree of a driver.js configuration.
"!
"! Describe the tour as data - one step per control, each with the text of its
"! popover - bind it to <em>config</em>, and raise <em>trigger</em> to start
"! it. <em>element</em> is the id the app gave the control in the view; it is
"! resolved in the frontend, so a step may point into a nested view or a dialog
"! without this class knowing where the control ended up.
"!
"! Bind config and highlight with the camelCase mapper and this library's JSON
"! filter - see zcl_z2ui5cc_chartjs for the same pattern and why both are
"! needed.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_driver_js). The
"! original pasted the whole library and its stylesheet into the view as ABAP
"! string literals; both are loaded as a library now. Its `elementview` field
"! is gone, and so are the JavaScript callback strings - the tour reports back
"! through events instead.
CLASS zcl_z2ui5cc_driverjs DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! which buttons a popover shows, as a JSON array literal
    CONSTANTS:
      BEGIN OF cs_buttons,
        all            TYPE string VALUE `['next','previous','close']`,
        next           TYPE string VALUE `['next']`,
        previous       TYPE string VALUE `['previous']`,
        close          TYPE string VALUE `['close']`,
        next_previous  TYPE string VALUE `['next','previous']`,
        next_close     TYPE string VALUE `['next','close']`,
        previous_close TYPE string VALUE `['previous','close']`,
      END OF cs_buttons.

    "! which side of the element the popover sits on
    CONSTANTS:
      BEGIN OF cs_side,
        top    TYPE string VALUE `top`,
        right  TYPE string VALUE `right`,
        bottom TYPE string VALUE `bottom`,
        left   TYPE string VALUE `left`,
        over   TYPE string VALUE `over`,
      END OF cs_side.

    "! how the popover lines up along that side
    CONSTANTS:
      BEGIN OF cs_align,
        start  TYPE string VALUE `start`,
        center TYPE string VALUE `center`,
        end    TYPE string VALUE `end`,
      END OF cs_align.

    "! how the control is started
    CONSTANTS:
      BEGIN OF cs_mode,
        "! walk through every step
        tour      TYPE string VALUE `tour`,
        "! spotlight one element, no navigation
        highlight TYPE string VALUE `highlight`,
      END OF cs_mode.

    "! The bubble shown next to a step's element. `title` and `description`
    "! are rendered as HTML, so simple markup works - and unescaped user input
    "! does not belong in them.
    TYPES:
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

    "! One stop of the tour. `element` is the control id as the app wrote it
    "! in the view; a value starting with `#`, `.` or `[` is passed to
    "! driver.js as a CSS selector instead.
    TYPES:
      BEGIN OF ty_s_step,
        element TYPE string,
        popover TYPE ty_s_popover,
      END OF ty_s_step.
    TYPES ty_t_step TYPE STANDARD TABLE OF ty_s_step WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_config,
        steps                      TYPE ty_t_step,
        animate                    TYPE abap_bool,
        overlay_color              TYPE string,
        overlay_opacity            TYPE string,
        smooth_scroll              TYPE abap_bool,
        allow_close                TYPE abap_bool,
        allow_keyboard_control     TYPE abap_bool,
        disable_active_interaction TYPE abap_bool,
        stage_padding              TYPE i,
        stage_radius               TYPE i,
        popover_class              TYPE string,
        popover_offset             TYPE i,
        show_buttons               TYPE string,
        disable_buttons            TYPE string,
        show_progress              TYPE abap_bool,
        progress_text              TYPE string,
        next_btn_text              TYPE string,
        prev_btn_text              TYPE string,
        done_btn_text              TYPE string,
      END OF ty_s_config.

    "! Emit <z2ui5cc:DriverJs/> into an existing view.
    "!
    "! @parameter view        | the builder positioned at the parent element
    "! @parameter config      | bind of a ty_s_config structure
    "! @parameter trigger     | bind an integer; raising it starts the tour
    "! @parameter highlight   | bind of a ty_s_step structure, for cs_mode-highlight
    "! @parameter mode        | cs_mode-tour (default) or cs_mode-highlight
    "! @parameter customcss   | extra CSS, e.g. to theme the popover
    "! @parameter liburl      | overrides where driver.js is loaded from
    "! @parameter cssurl      | overrides where its stylesheet is loaded from
    "! @parameter highlighted | client->_event( ... ) fired per step
    "! @parameter done        | client->_event( ... ) fired when the tour ends
    "! @parameter result      | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        config        TYPE string OPTIONAL
        trigger       TYPE string OPTIONAL
        highlight     TYPE string OPTIONAL
        mode          TYPE string OPTIONAL
        customcss     TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        cssurl        TYPE string OPTIONAL
        highlighted   TYPE string OPTIONAL
        done          TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_driverjs IMPLEMENTATION.

  METHOD render.

    result = zcl_z2ui5cc=>leaf(
        view = view
        name = `DriverJs`
        a    = VALUE #( ( |config={ config }| )
                        ( |trigger={ trigger }| )
                        ( |highlight={ highlight }| )
                        ( |mode={ mode }| )
                        ( |customCss={ customcss }| )
                        ( |libUrl={ liburl }| )
                        ( |cssUrl={ cssurl }| )
                        ( |highlighted={ highlighted }| )
                        ( |done={ done }| ) ) ).

  ENDMETHOD.

ENDCLASS.
