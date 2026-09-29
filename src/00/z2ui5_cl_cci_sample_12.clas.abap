"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - RichTextEditor demo</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_12</em>
"!
"! A letter in a WYSIWYG editor, with the HTML it produces shown underneath.
"! Both are bound to the SAME ABAP attribute, so the source follows the typing
"! without a roundtrip - what you see below the editor is what ABAP receives.
"!
"! The buttons cover what an app does with it: load a text from ABAP, empty
"! it, switch the toolbar, make it read-only, and load hostile HTML to show
"! what the sanitizer is for. Leaving the editor after a change raises CHANGED.
CLASS z2ui5_cl_cci_sample_12 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    DATA html     TYPE string.
    DATA editable TYPE abap_bool.
    DATA toolbar  TYPE string.
    DATA info     TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

    "! A business letter - headings, a table, a list, a link.
    CLASS-METHODS get_letter
      RETURNING
        VALUE(result) TYPE string.
    "! HTML carrying a script, an event handler and a javascript: link.
    CLASS-METHODS get_hostile
      RETURNING
        VALUE(result) TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_12 IMPLEMENTATION.

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
              v = `abap2UI5 - Rich Text Editor` ).

    page->ele( `Toolbar`
        )->a( n = `class`
              v = `sapUiSmallMarginBegin sapUiSmallMarginEnd`

        )->tag( `Button`
            )->a( n = `text`
                  v = `Letter`
            )->a( n = `press`
                  v = client->_event( `LETTER` )
        )->tag( `Button`
            )->a( n = `text`
                  v = `Hostile HTML`
            )->a( n = `press`
                  v = client->_event( `HOSTILE` )
        )->tag( `Button`
            )->a( n = `text`
                  v = `Empty`
            )->a( n = `press`
                  v = client->_event( `EMPTY` )

        )->tag( `ToolbarSpacer`

        )->tag( `Button`
            )->a( n = `text`
                  v = `Full toolbar`
            )->a( n = `press`
                  v = client->_event( `FULL` )
        )->tag( `Button`
            )->a( n = `text`
                  v = `Basic toolbar`
            )->a( n = `press`
                  v = client->_event( `BASIC` )
        " Bound to an abap_bool, which arrives in the model as a real JSON
        " boolean - the control's `editable` property is boolean-typed.
        )->tag( `CheckBox`
            )->a( n = `text`
                  v = `Editable`
            )->a( n = `selected`
                  v = client->_bind( editable )
    )->end( ).

    " Directly under the toolbar, because this is what the buttons and the
    " change event speak through.
    page->tag( `MessageStrip`
        )->a( n = `text`
              v = client->_bind( info )
        )->a( n = `showIcon`
              v = `true`
        )->a( n = `class`
              v = `sapUiSmallMarginBegin sapUiSmallMarginEnd sapUiSmallMarginTop` ).

    DATA(box) = page->ele( `VBox`
        )->a( n = `class`
              v = `sapUiSmallMargin` ).

    " `toolbar` is bound too: switching it rebuilds the editor around the text
    " it holds, without a new view.
    z2ui5_cl_cci_rich_text_editor=>render( view        = box
                                           value       = client->_bind( html )
                                           editable    = client->_bind( editable )
                                           toolbar     = client->_bind( toolbar )
                                           height      = `18rem`
                                           placeholder = `Write something...`
                                           change      = client->_event( `CHANGED` ) ).

    box->tag( `Label`
        )->a( n = `text`
              v = `HTML in ABAP`
        )->a( n = `class`
              v = `sapUiSmallMarginTop` ).

    " The same attribute again, read-only: the source follows every change the
    " editor makes to the model, which is exactly what the next roundtrip
    " carries to ABAP.
    z2ui5_cl_cci_code_editor=>render( view     = box
                                      value    = client->_bind( html )
                                      type     = z2ui5_cl_cci_code_editor=>cs_type-html
                                      editable = `false`
                                      height   = `12rem` ).

    box->end( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `LETTER`.
        html = get_letter( ).
        info = `A letter from ABAP - edit it, and watch the HTML below follow.`.

      WHEN `HOSTILE`.
        " The editor shows this sanitized: no script, no handler, no
        " javascript: link. `html` itself keeps what ABAP sent until somebody
        " edits the text - the model gets back what it sent, not a rewrite.
        html = get_hostile( ).
        info = `The script, the handler and the javascript: link are gone in the editor.`.

      WHEN `EMPTY`.
        html = ``.
        info = `Emptied from ABAP - the editor shows the placeholder.`.

      WHEN `FULL`.
        toolbar = ``.
        info = `The default toolbar.`.

      WHEN `BASIC`.
        toolbar = z2ui5_cl_cci_rich_text_editor=>cs_toolbar-basic.
        info = `z2ui5_cl_cci_rich_text_editor=>cs_toolbar-basic.`.

      WHEN `CHANGED`.
        " `html` already carries the new text here - bound data is written
        " back into the attribute before the event handler runs.
        info = |Changed - { strlen( html ) } characters of HTML arrived in ABAP.|.

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    html     = get_letter( ).
    editable = abap_true.
    info     = `Type in the editor - the HTML below follows without a roundtrip.`.

  ENDMETHOD.

  METHOD get_letter.

    result = `<h2>Delivery 80001234</h2>` &&
             `<p>Dear Ms. Doe,</p>` &&
             `<p>thank you for your order. It left plant <strong>1000</strong> today:</p>` &&
             `<table><tbody>` &&
             `<tr><th>Item</th><th>Material</th><th>Quantity</th></tr>` &&
             `<tr><td>10</td><td>R-1001</td><td>12 PC</td></tr>` &&
             `<tr><td>20</td><td>R-2000</td><td>100 KG</td></tr>` &&
             `</tbody></table>` &&
             `<ul><li>goods checked on arrival</li><li>one carton damaged, see photo</li></ul>` &&
             `<p>Kind regards,<br>your <a href="https://abap2ui5.github.io/docs/">abap2UI5</a> team</p>`.

  ENDMETHOD.

  METHOD get_hostile.

    result = `<p>This paragraph came with an <em>onmouseover</em> handler,` &&
             ` the link below with a <em>javascript:</em> URL, and a script followed.</p>` &&
             `<p onmouseover="alert('handler')">Hover me - nothing happens.</p>` &&
             `<p><a href="javascript:alert('link')">Click me - nothing happens.</a></p>` &&
             `<script>alert('script')</script>`.

  ENDMETHOD.

ENDCLASS.
