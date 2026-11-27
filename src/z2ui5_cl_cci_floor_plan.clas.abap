"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - FloorPlan</p>
"!
"! The ABAP half of the z2ui5_cci.cc.FloorPlan custom control: the view
"! builder that emits its XML element, plus the types of an item and an area.
"!
"! A plan of boxes seen from above, that the user zooms and pans. Every row of
"! the bound table is one box at a fixed place - position and size in plan
"! units, a state, a share that is filled, up to three lines of text. A click
"! raises a normal abap2UI5 event with the key of the box.
"!
"! Use it for anything with a few hundred places and a level: the lanes of a
"! block storage, the bins of a hall, tanks, parking spaces, machines.
"!
"! The control draws plain SVG and loads no library. Two things it decides in
"! the browser, because only the browser knows them:
"!
"! <ul><li>the level of detail - how much of an item's text is shown depends
"! on how many pixels the item has at the current zoom. Send all three lines;
"! zoomed out none of them is drawn, closer the title, closer still the
"! rest</li>
"! <li>the viewport - zoom and position stay where the user left them when the
"! table changes. Only <em>fitkeys</em> moves them from ABAP</li></ul>
"!
"! The plan units are yours: metres, millimetres, grid cells. <em>x</em> grows
"! to the right and <em>y</em> downwards, like on a screen.
CLASS z2ui5_cl_cci_floor_plan DEFINITION
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

    CONSTANTS:
      "! Values of ty_s_item-dir: the side an item fills up towards
      BEGIN OF cs_dir,
        "! along the longer side - from the bottom or from the left
        auto  TYPE string VALUE ``,
        up    TYPE string VALUE `up`,
        down  TYPE string VALUE `down`,
        left  TYPE string VALUE `left`,
        right TYPE string VALUE `right`,
      END OF cs_dir.

    CONSTANTS:
      "! Values of the parameter selectionmode
      BEGIN OF cs_selection_mode,
        "! a click raises itempress and selects nothing
        none   TYPE string VALUE `None`,
        single TYPE string VALUE `Single`,
        multi  TYPE string VALUE `Multi`,
      END OF cs_selection_mode.

    "! A length or a position in plan units, or a share from 0 to 1
    TYPES ty_number TYPE p LENGTH 9 DECIMALS 3.

    TYPES:
      "! One box of the plan.
      BEGIN OF ty_s_item,
        "! unique in the table; what itempress, selectedkeys, highlightkeys
        "! and fitkeys name the item by
        key     TYPE string,
        "! left edge
        x       TYPE ty_number,
        "! top edge
        y       TYPE ty_number,
        width   TYPE ty_number,
        height  TYPE ty_number,
        "! the filled share, 0 to 1 - drawn as a bar in the colour of the
        "! state
        fill    TYPE ty_number,
        "! a value of cs_dir
        dir     TYPE string,
        "! a value of cs_state
        state   TYPE string,
        "! any CSS colour; overrides the colour of the state
        color   TYPE string,
        "! drawn hatched: locked, out of use
        blocked TYPE abap_bool,
        "! first line, bold - shown first when the user zooms in
        title   TYPE string,
        "! second line
        text    TYPE string,
        "! third line
        info    TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

    TYPES:
      "! An outline behind the items - a hall, a zone - with its name in the
      "! top left corner. Not clickable.
      BEGIN OF ty_s_area,
        key    TYPE string,
        x      TYPE ty_number,
        y      TYPE ty_number,
        width  TYPE ty_number,
        height TYPE ty_number,
        title  TYPE string,
      END OF ty_s_area.
    TYPES ty_t_area TYPE STANDARD TABLE OF ty_s_area WITH EMPTY KEY.

    "! Emit &lt;z2ui5_cci:FloorPlan/&gt; into an existing view.
    "!
    "! @parameter view          | the builder positioned at the parent element
    "! @parameter items         | bind of a ty_t_item table
    "! @parameter areas         | bind of a ty_t_area table
    "! @parameter selectedkeys  | bind two-way; comma separated item keys
    "! @parameter highlightkeys | comma separated item keys to point out -
    "!                            every other item is dimmed; empty dims none
    "! @parameter fitkeys       | comma separated item keys the viewport
    "!                            flies to whenever the value changes; empty
    "!                            shows the whole plan
    "! @parameter selectionmode | a value of cs_selection_mode, default Single
    "! @parameter showcontrols  | the zoom buttons in the corner, default true
    "! @parameter width         | CSS width, default 100%
    "! @parameter height        | CSS height, default 500px. The plan has no
    "!                            height of its own - give it one
    "! @parameter itempress     | client->_event( ... ) fired on a click on
    "!                            an item; parameters key, selected, keys
    "! @parameter result        | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        items         TYPE string
        areas         TYPE string OPTIONAL
        selectedkeys  TYPE string OPTIONAL
        highlightkeys TYPE string OPTIONAL
        fitkeys       TYPE string OPTIONAL
        selectionmode TYPE string OPTIONAL
        showcontrols  TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        itempress     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_floor_plan IMPLEMENTATION.

  METHOD render.

    " an attribute the caller left empty is dropped by tag( ) - it would
    " override the control's own default with an empty string
    result = z2ui5_cl_cci=>tag( view = view
                                name = `FloorPlan`
                                a    = VALUE #( ( |items={ items }| )
                                                ( |areas={ areas }| )
                                                ( |selectedKeys={ selectedkeys }| )
                                                ( |highlightKeys={ highlightkeys }| )
                                                ( |fitKeys={ fitkeys }| )
                                                ( |selectionMode={ selectionmode }| )
                                                ( |showControls={ showcontrols }| )
                                                ( |width={ width }| )
                                                ( |height={ height }| )
                                                ( |itemPress={ itempress }| ) ) ).

  ENDMETHOD.

ENDCLASS.
