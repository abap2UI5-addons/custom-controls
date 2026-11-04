"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - RichTextEditor</p>
"!
"! The ABAP half of the z2ui5_cci.cc.RichTextEditor custom control: the view
"! builder that emits its XML element.
"!
"! A WYSIWYG editor for HTML, built on SunEditor 3 (MIT). UI5 has one of its
"! own, sap.ui.richtexteditor.RichTextEditor, but only in SAPUI5 - and abap2UI5
"! bootstraps OpenUI5 unless told otherwise. This one runs on both. Bind the
"! HTML two-way:
"!
"!   z2ui5_cl_cci_rich_text_editor=>render( view  = page
"!                                          value = client->_bind( mv_html ) ).
"!
"! The model follows the typing without a roundtrip; <em>change</em> fires when
"! the editor loses focus with a changed text.
"!
"! <strong>Sanitizing.</strong> The HTML runs through DOMPurify on its way into
"! the editor and on its way back, unless <em>sanitize</em> is `false`. Leave it
"! on: the value is shown in some other page one day, and what comes in may
"! have been typed by somebody else.
CLASS z2ui5_cl_cci_rich_text_editor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS:
      "! Toolbars for the `toolbar` parameter - button groups separated by `|`,
      "! buttons by `,`, named as SunEditor names them. Empty is the full default
      "! toolbar: formats, fonts, colours, alignment, lists, table, link, image,
      "! full screen and the HTML source view.
      BEGIN OF cs_toolbar,
        "! text, lists and links - for notes and comments
        basic TYPE string VALUE `undo,redo|bold,italic,underline|list_bulleted,list_numbered|link|removeFormat`,
        "! everything but tables and images, which keep the HTML small
        text  TYPE string VALUE `undo,redo|blockStyle|bold,underline,italic,strike|fontColor,backgroundColor,removeFormat|align,list_numbered,list_bulleted,outdent,indent|link,hr`,
      END OF cs_toolbar.

    "! Emit &lt;z2ui5_cci:RichTextEditor/&gt; into an existing view.
    "!
    "! @parameter view        | the builder positioned at the parent element
    "! @parameter value       | the HTML, bound two-way: client->_bind( ... )
    "! @parameter editable    | `false` shows the text read-only - never abap_true,
    "!                          it serializes as X
    "! @parameter width       | CSS width, default 100%
    "! @parameter height      | CSS height of the editing area below the toolbar;
    "!                          empty grows with the text
    "! @parameter placeholder | text shown while the editor is empty
    "! @parameter toolbar     | button groups, see cs_toolbar; empty is the default
    "! @parameter language    | SunEditor language code (de, fr, pt_br, ...);
    "!                          empty follows the UI5 language
    "! @parameter sanitize    | `false` trusts the HTML unchecked - see above
    "! @parameter liburl      | overrides where SunEditor is loaded from
    "! @parameter cssurl      | overrides where its stylesheet is loaded from
    "! @parameter purifyurl   | overrides where DOMPurify is loaded from
    "! @parameter langurl     | overrides where the language file is loaded from
    "! @parameter change      | client->_event( ... ) fired when the editor loses
    "!                          focus with a changed text
    "! @parameter result      | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        value         TYPE string
        editable      TYPE string OPTIONAL
        width         TYPE string OPTIONAL
        height        TYPE string OPTIONAL
        placeholder   TYPE string OPTIONAL
        toolbar       TYPE string OPTIONAL
        language      TYPE string OPTIONAL
        sanitize      TYPE string OPTIONAL
        liburl        TYPE string OPTIONAL
        cssurl        TYPE string OPTIONAL
        purifyurl     TYPE string OPTIONAL
        langurl       TYPE string OPTIONAL
        change        TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_rich_text_editor IMPLEMENTATION.

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
    CLEAR temp1.

    temp2 = |value={ value }|.
    INSERT temp2 INTO TABLE temp1.

    temp3 = |editable={ editable }|.
    INSERT temp3 INTO TABLE temp1.

    temp4 = |width={ width }|.
    INSERT temp4 INTO TABLE temp1.

    temp5 = |height={ height }|.
    INSERT temp5 INTO TABLE temp1.

    temp6 = |placeholder={ placeholder }|.
    INSERT temp6 INTO TABLE temp1.

    temp7 = |toolbar={ toolbar }|.
    INSERT temp7 INTO TABLE temp1.

    temp8 = |language={ language }|.
    INSERT temp8 INTO TABLE temp1.

    temp9 = |sanitize={ sanitize }|.
    INSERT temp9 INTO TABLE temp1.

    temp10 = |libUrl={ liburl }|.
    INSERT temp10 INTO TABLE temp1.

    temp11 = |cssUrl={ cssurl }|.
    INSERT temp11 INTO TABLE temp1.

    temp12 = |purifyUrl={ purifyurl }|.
    INSERT temp12 INTO TABLE temp1.

    temp13 = |langUrl={ langurl }|.
    INSERT temp13 INTO TABLE temp1.

    temp14 = |change={ change }|.
    INSERT temp14 INTO TABLE temp1.
    result = z2ui5_cl_cci=>tag(
        view = view
        name = `RichTextEditor`
        a    = temp1 ).

  ENDMETHOD.

ENDCLASS.
