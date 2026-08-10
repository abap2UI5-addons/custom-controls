"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - CodeEditor</p>
"!
"! The ABAP half of the z2ui5ccc.cc.CodeEditor custom control: the view builder
"! that emits its XML element.
"!
"! This control adds no editor of its own - UI5 already ships one. What it adds
"! is a way to reach it from an abap2UI5 view: <em>sap.ui.codeeditor</em> is
"! not among the manifest dependencies, and on 1.71 the XML is still processed
"! synchronously, so a CodeEditor written straight into a view is fetched by
"! synchronous XHR and executed with eval - which a Content-Security-Policy
"! without 'unsafe-eval' blocks. The control loads the modules asynchronously
"! and creates the editor itself, so the view never names the UI5 class.
"!
"!   z2ui5_cl_cci_code_editor=>render( view  = page
"!                                     value = client->_bind( source )
"!                                     type  = `markdown` ).
"!
"! The ACE mode for a type is loaded from the UI5 distribution, not from a CDN,
"! so syntax highlighting also works in a system without internet.
CLASS z2ui5_cl_cci_code_editor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! A few of the types sap.ui.codeeditor supports. It knows about eighty;
    "! any of its names can be passed to render( ) directly.
    CONSTANTS:
      BEGIN OF cs_type,
        markdown   TYPE string VALUE `markdown`,
        abap       TYPE string VALUE `abap`,
        javascript TYPE string VALUE `javascript`,
        json       TYPE string VALUE `json`,
        xml        TYPE string VALUE `xml`,
        html       TYPE string VALUE `html`,
        css        TYPE string VALUE `css`,
        sql        TYPE string VALUE `sql`,
        yaml       TYPE string VALUE `yaml`,
        plain_text TYPE string VALUE `plain_text`,
      END OF cs_type.

    "! Emit &lt;z2ui5ccc:CodeEditor/&gt; into an existing view.
    "!
    "! @parameter view        | the builder positioned at the parent element
    "! @parameter value       | the text, usually client->_bind( ... )
    "! @parameter type        | syntax highlighting, see cs_type
    "! @parameter width       | CSS width, e.g. `100%`
    "! @parameter height      | CSS height. ACE needs a resolvable one, so an
    "!                          explicit value beats `100%` unless the parent
    "!                          has a height of its own
    "! @parameter editable    | `false` for a read-only viewer
    "! @parameter linenumbers | `false` to hide the line number gutter
    "! @parameter colortheme  | ACE theme, e.g. `dark`; empty follows the
    "!                          UI5 theme
    "! @parameter livechange  | client->_event( ... ) fired while typing. Only
    "!                          needed when ABAP has to react per keystroke -
    "!                          a two-way bound `value` already keeps the
    "!                          model up to date without any roundtrip
    "! @parameter result      | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        value         TYPE string
        type          TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        editable      TYPE string OPTIONAL
        linenumbers   TYPE string OPTIONAL
        colortheme    TYPE string OPTIONAL
        livechange    TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_code_editor IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>leaf(
        view = view
        name = `CodeEditor`
        a    = VALUE #( ( |value={ value }| )
                        ( |type={ type }| )
                        ( |width={ width }| )
                        ( |height={ height }| )
                        ( |editable={ editable }| )
                        ( |lineNumbers={ linenumbers }| )
                        ( |colorTheme={ colortheme }| )
                        ( |liveChange={ livechange }| ) ) ).

  ENDMETHOD.

ENDCLASS.
