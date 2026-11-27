"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - GridStack</p>
"!
"! The ABAP half of the z2ui5_cci.cc.GridStack custom control: the view
"! builder that emits its XML element, plus the type of a box.
"!
"! Boxes on a grid, with gridstack.js. Every row of the bound table is one
"! box - column, row, width and height in grid cells, a text, a state. With
"! <em>editable</em> off the grid is a picture that reports the box that was
"! clicked. With it on, the user drags and resizes the boxes: they snap to the
"! grid, do not overlap and stay inside it, and the control writes the new
"! positions back into the bound table before it raises <em>change</em> - the
"! handler reads its own table and finds the layout the user made.
"!
"! Use it for anything that is laid out in cells: the compartments of a shelf
"! or a drawer, seats, the slots of a rack, a board the user arranges.
CLASS z2ui5_cl_cci_gridstack DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      "! Values of ty_s_item-state: the semantic colours of the UI5 theme
      BEGIN OF cs_state,
        none        TYPE string VALUE ``,
        success     TYPE string VALUE `Success`,
        warning     TYPE string VALUE `Warning`,
        error       TYPE string VALUE `Error`,
        information TYPE string VALUE `Information`,
      END OF cs_state.

    TYPES:
      "! One box. <em>x</em> and <em>y</em> count from 0 at the top left,
      "! <em>w</em> and <em>h</em> are at least 1.
      BEGIN OF ty_s_item,
        "! unique in the table - a row without an id or with one that is
        "! taken is not shown
        id       TYPE string,
        x        TYPE i,
        y        TYPE i,
        w        TYPE i,
        h        TYPE i,
        "! first line, bold
        text     TYPE string,
        "! second line, small
        info     TYPE string,
        "! a value of cs_state
        state    TYPE string,
        "! any CSS colour; overrides the background of the state
        color    TYPE string,
        "! drawn with a frame in the selection colour of the theme
        selected TYPE abap_bool,
        "! cannot be moved or resized, also when the grid is editable
        locked   TYPE abap_bool,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

    "! Emit &lt;z2ui5_cci:GridStack/&gt; into an existing view.
    "!
    "! Mirrors z2ui5_cl_ui5_view_builder=>tag: the element is added as a child and the
    "! cursor stays on the current node, so the caller can keep chaining.
    "!
    "! @parameter view       | the builder positioned at the parent element
    "! @parameter items      | bind of a ty_t_item table; the control writes moved boxes back
    "! @parameter columns    | number of grid columns, default 12
    "! @parameter rows       | number of grid rows; empty: as many as the boxes need
    "! @parameter cellheight | height of one grid cell in px, default 60
    "! @parameter margin     | gap around a box in px, default 4
    "! @parameter editable   | `true` lets the user drag and resize; bind it to switch at
    "!                         run time. Never abap_true (X) or abap_false (dropped:
    "!                         the default stays) - pass z2ui5_cl_cci=>bool( flag )
    "! @parameter float      | `false` lets the boxes move up to close a gap
    "! @parameter width      | CSS width of the grid, default 100%
    "! @parameter liburl     | where to load gridstack.js from; default: see LibUrls
    "! @parameter cssurl     | where to load its stylesheet from; default: see LibUrls
    "! @parameter change     | client->_event( ... ) fired after the user moved or resized
    "!                         boxes; $parameters&gt;/ids holds their ids, comma separated
    "! @parameter itempress  | client->_event( ... ) fired on a click on a box;
    "!                         $parameters&gt;/id holds its id
    "! @parameter result     | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        items         TYPE string
        columns       TYPE string OPTIONAL
        rows          TYPE string OPTIONAL
        cellheight    TYPE string OPTIONAL
        margin        TYPE string OPTIONAL
        editable      TYPE string OPTIONAL
        float         TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        cssurl        TYPE string OPTIONAL
        change        TYPE string OPTIONAL
        itempress     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_gridstack IMPLEMENTATION.

  METHOD render.

    " an attribute the caller left empty is dropped by tag( ) - it would
    " override the control's own default with an empty string
    result = z2ui5_cl_cci=>tag( view = view
                                name = `GridStack`
                                a    = VALUE #( ( |items={ items }| )
                                                ( |columns={ columns }| )
                                                ( |rows={ rows }| )
                                                ( |cellHeight={ cellheight }| )
                                                ( |margin={ margin }| )
                                                ( |editable={ editable }| )
                                                ( |float={ float }| )
                                                ( |width={ width }| )
                                                ( |libUrl={ liburl }| )
                                                ( |cssUrl={ cssurl }| )
                                                ( |change={ change }| )
                                                ( |itemPress={ itempress }| ) ) ).

  ENDMETHOD.

ENDCLASS.
