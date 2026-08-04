"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Markdown</p>
"!
"! The ABAP half of the z2ui5cc.cc.Markdown custom control: the view builder
"! that emits its XML element.
"!
"! UI5 ships no Markdown control. sap.m.FormattedText is the usual stand-in,
"! but it takes HTML and whitelists only a few tags, so anything with a
"! heading, a table and a code block has to be assembled as HTML in ABAP.
"! Bind a Markdown string instead:
"!
"!   z2ui5_cl_ccont_markdown=>render( view  = page
"!                                    value = client->_bind( md_text ) ).
"!
"! <strong>Sanitizing.</strong> The rendered HTML is run through DOMPurify
"! unless <em>sanitize</em> is set to `false`. Leave it on for anything a user
"! typed or a language model produced - Markdown may contain raw HTML, and
"! unsanitized that HTML runs with the user's session. Turning it off is only
"! defensible for text your own developers wrote and your own system stores.
CLASS z2ui5_cl_ccont_markdown DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! Emit <z2ui5cc:Markdown/> into an existing view.
    "!
    "! @parameter view      | the builder positioned at the parent element
    "! @parameter value     | the Markdown source, usually client->_bind( ... )
    "! @parameter sanitize  | `false` renders the HTML unchecked - see above
    "! @parameter breaks    | `false` to stop a single newline becoming a <br>
    "! @parameter gfm       | `false` to drop tables, strikethrough, autolinks
    "! @parameter width     | CSS width, e.g. `100%`, `40rem`
    "! @parameter height    | CSS height; the text scrolls inside it
    "! @parameter liburl    | overrides where marked is loaded from
    "! @parameter purifyurl | overrides where DOMPurify is loaded from
    "! @parameter linkpress | client->_event( ... ) fired for a link whose
    "!                        href starts with `#`, instead of following it.
    "!                        The href is an event parameter, so ask for it:
    "!                        client->_event( val   = `LINK`
    "!                                        t_arg = VALUE #( ( `${$parameters>/href}` ) ) )
    "! @parameter result    | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ai_xml
        value         TYPE string
        sanitize      TYPE string OPTIONAL
        breaks        TYPE string OPTIONAL
        gfm           TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        purifyurl     TYPE string OPTIONAL
        linkpress     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccont_markdown IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_ccont=>leaf(
        view = view
        name = `Markdown`
        a    = VALUE #( ( |value={ value }| )
                        ( |sanitize={ sanitize }| )
                        ( |breaks={ breaks }| )
                        ( |gfm={ gfm }| )
                        ( |width={ width }| )
                        ( |height={ height }| )
                        ( |libUrl={ liburl }| )
                        ( |purifyUrl={ purifyurl }| )
                        ( |linkPress={ linkpress }| ) ) ).

  ENDMETHOD.

ENDCLASS.
