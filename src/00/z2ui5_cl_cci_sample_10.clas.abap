"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Markdown demo</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_10</em>
"!
"! Editor on the left, rendered document on the right - two controls of this
"! library side by side. Both are bound to the SAME ABAP attribute, so the
"! preview follows every keystroke without a roundtrip: the Markdown control
"! re-renders from the model the CodeEditor writes into. That is the whole
"! integration - no live-change event, no backend call.
"!
"! The examples cover what Markdown is normally reached for here: a document
"! with headings and a table, a code block, in-app links, and the raw-HTML case
"! that shows what the sanitizer is for.
CLASS z2ui5_cl_cci_sample_10 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA source   TYPE string.
    DATA sanitize TYPE abap_bool.
    DATA info     TYPE string.

    " Public because ABAP requires it - CLASS_CONSTRUCTOR is always public,
    " wherever it is declared. It is not part of the app's surface, and being
    " a method it is not serialized between roundtrips either.
    CLASS-METHODS class_constructor.

  PROTECTED SECTION.
    " A backtick cannot be written inside a backtick-delimited literal without
    " doubling it, and a Markdown code fence is three of them - unreadable
    " that way. Single-quoted literals have no such rule, so the fence and the
    " inline tick live here and are interpolated where they are needed.
    CONSTANTS c_tick  TYPE string VALUE '`'.
    CONSTANTS c_fence TYPE string VALUE '```'.

    " The newline is owned here rather than read from the framework: the
    " control library deliberately does not build on abap2UI5 internals, and
    " one class-constructor is cheaper than that coupling.
    CLASS-DATA mv_nl TYPE c LENGTH 1.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

    "! The document example - headings, table, list, quote.
    CLASS-METHODS get_doc
      RETURNING
        VALUE(result) TYPE string.
    "! Code blocks and in-app links, the two things a help text needs most.
    CLASS-METHODS get_code
      RETURNING
        VALUE(result) TYPE string.
    "! Markdown carrying raw HTML - harmless with `sanitize`, not without it.
    CLASS-METHODS get_html
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_10 IMPLEMENTATION.

  METHOD class_constructor.

    mv_nl = cl_abap_char_utilities=>newline.

  ENDMETHOD.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(root) = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%` ).

    " the whole integration on the view side - one namespace declaration
    z2ui5_cl_cci=>xmlns( root ).

    DATA(page) = root->ele( `Page`
        )->a( n = `title`
              v = `abap2UI5 - Markdown` ).

    page->ele( `Toolbar`
        )->a( n = `class`
              v = `sapUiSmallMarginBegin sapUiSmallMarginEnd`

        )->tag( `Button`
            )->a( n = `text`
                  v = `Document`
            )->a( n = `press`
                  v = client->_event( `DOC` )
        )->tag( `Button`
            )->a( n = `text`
                  v = `Code & links`
            )->a( n = `press`
                  v = client->_event( `CODE` )
        )->tag( `Button`
            )->a( n = `text`
                  v = `Raw HTML`
            )->a( n = `press`
                  v = client->_event( `HTML` )

        )->tag( `ToolbarSpacer`

        " Bound to an abap_bool, which arrives in the model as a real JSON
        " boolean - the control's `sanitize` property is boolean-typed and
        " UI5 rejects anything else.
        )->tag( `CheckBox`
            )->a( n = `text`
                  v = `Sanitize`
            )->a( n = `selected`
                  v = client->_bind( sanitize )
    )->end( ).

    " Directly under the toolbar, because this is what the buttons speak
    " through - below a 40rem editor nobody sees the hint change.
    page->tag( `MessageStrip`
        )->a( n = `text`
              v = client->_bind( info )
        )->a( n = `showIcon`
              v = `true`
        )->a( n = `class`
              v = `sapUiSmallMarginBegin sapUiSmallMarginEnd sapUiSmallMarginTop` ).

    " Editor and preview side by side, and stacked on a phone.
    DATA(grid) = page->ele( `FlexBox`
        )->a( n = `wrap`
              v = `Wrap`
        )->a( n = `class`
              v = `sapUiSmallMargin`
        )->a( n = `alignItems`
              v = `Stretch` ).

    DATA(left) = grid->ele( `VBox`
        )->a( n = `class`
              v = `sapUiTinyMarginEnd`
        )->a( n = `width`
              v = `44rem`

        )->tag( `Label`
            )->a( n = `text`
                  v = `Markdown source` ).

    " The editor is UI5's own sap.ui.codeeditor - monospace, line numbers and
    " markdown highlighting, loaded from the UI5 distribution rather than a
    " CDN. `value` is bound to the SAME attribute the preview renders, which
    " is what makes the preview follow the typing without an event.
    z2ui5_cl_cci_code_editor=>render( view   = left
                                      value  = client->_bind( source )
                                      type   = z2ui5_cl_cci_code_editor=>cs_type-markdown
                                      height = `40rem` ).

    left->end( ).

    DATA(right) = grid->ele( `VBox`
        )->a( n = `width`
              v = `48rem`

        )->tag( `Label`
            )->a( n = `text`
                  v = `Rendered` ).

    right = right->ele( `Panel`
        )->a( n = `height`
              v = `100%`
        )->ele( `content` ).

    z2ui5_cl_cci_markdown=>render(
        view      = right
        value     = client->_bind( source )
        sanitize  = client->_bind( sanitize )
        height    = `40rem`
        linkpress = client->_event( val   = `LINK`
                                    t_arg = VALUE #( ( `${$parameters>/href}` ) ) ) ).

    right->end( )->end( )->end( ).

    grid->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `DOC`.
        source = get_doc( ).
        info   = `Headings, a table, a list and a quote.`.

      WHEN `CODE`.
        source = get_code( ).
        info   = `The two links below are in-app links - click one.`.

      WHEN `HTML`.
        source = get_html( ).
        info   = `Toggle Sanitize and watch the raw HTML appear and vanish.`.

      WHEN `LINK`.
        " A `#...` link does not navigate - the control hands the href over
        " instead, which is how a help text links into the app it documents.
        info = |Link pressed: { client->get_event_arg( 1 ) }|.

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    sanitize = abap_true.
    source   = get_doc( ).
    info     = `Type on the left - the preview follows without a roundtrip.`.

  ENDMETHOD.

  METHOD get_doc.

    result = concat_lines_of(
        table = VALUE string_table(
          ( `# Delivery note 80001234` )
          ( `` )
          ( `Shipped **2026-08-04** from plant *1000*.` )
          ( `` )
          ( `## Positions` )
          ( `` )
          ( `| Item | Material | Qty | Unit |` )
          ( `|-----:|----------|----:|------|` )
          ( `|   10 | R-1001   |  12 | PC   |` )
          ( `|   20 | R-1002   |   4 | PC   |` )
          ( `|   30 | R-2000   | 100 | KG   |` )
          ( `` )
          ( `## Notes` )
          ( `` )
          ( `- goods checked on arrival` )
          ( `- one carton damaged, see photo` )
          ( `- signature captured digitally` )
          ( `` )
          ( `> Damaged carton was accepted with a remark.` )
          ( `` )
          ( `---` )
          ( `` )
          ( `Created by ABAP, rendered by marked.` ) )
        sep   = mv_nl ).

  ENDMETHOD.

  METHOD get_code.

    result = concat_lines_of(
        table = VALUE string_table(
          ( `## How to render Markdown` )
          ( `` )
          ( `Bind the string, that is all:` )
          ( `` )
          ( |{ c_fence }abap| )
          ( `z2ui5_cl_cci_markdown=>render(` )
          ( `    view  = page` )
          ( `    value = client->_bind( md_text ) ).` )
          ( c_fence )
          ( `` )
          ( |Inline { c_tick }code{ c_tick } works too.| )
          ( `` )
          ( `### In-app links` )
          ( `` )
          ( `A link starting with a hash does not navigate - it raises` )
          ( `an event instead:` )
          ( `` )
          ( `- [open order 4711](#order/4711)` )
          ( `- [open customer 100023](#customer/100023)` )
          ( `` )
          ( `An ordinary link still leaves the app:` )
          ( `[abap2UI5](https://abap2ui5.github.io/docs/).` ) )
        sep   = mv_nl ).

  ENDMETHOD.

  METHOD get_html.

    " The script tag below never executes - assigning it through innerHTML
    " does not run it. It is here to show that the sanitizer REMOVES it, while
    " the styled span survives either way but only reaches the page unfiltered
    " when sanitizing is off.
    result = concat_lines_of(
        table = VALUE string_table(
          ( `## Markdown may contain raw HTML` )
          ( `` )
          ( `Markdown passes HTML through, so whatever wrote this text` )
          ( `decides what lands in the page:` )
          ( `` )
          ( `<span style="color:#c00;font-weight:bold">styled by raw HTML</span>` )
          ( `` )
          ( `<script>console.log("stripped by DOMPurify")</script>` )
          ( `` )
          ( `With **Sanitize** on, DOMPurify removes the script and keeps the` )
          ( `harmless markup. With it off, the HTML is trusted as it stands -` )
          ( `only ever do that for text your own developers wrote.` ) )
        sep   = mv_nl ).

  ENDMETHOD.

ENDCLASS.
