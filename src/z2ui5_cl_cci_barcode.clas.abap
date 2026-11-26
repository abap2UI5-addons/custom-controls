"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Barcode</p>
"!
"! The ABAP half of the z2ui5_cci.cc.Barcode custom control: the view builder
"! that emits its XML element, plus a list of symbologies to try it with.
"!
"! Rendering happens in the browser with bwip-js, which speaks every symbology
"! BWIPP knows - EAN, UPC, ISBN, Code 128, QR, DataMatrix, GS1 and about a
"! hundred more. No image is built in ABAP and none is transferred.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_bwipjs).
CLASS z2ui5_cl_cci_barcode DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      "! One symbology, with an example value and the options it wants.
      BEGIN OF ty_s_type,
        bcid    TYPE string,
        text    TYPE string,
        example TYPE string,
        options TYPE string,
        "! bar height in mm - filled for the linear symbologies, empty for the
        "! matrix ones, where a height would stretch the symbol out of square
        height  TYPE string,
      END OF ty_s_type.
    TYPES ty_t_type TYPE STANDARD TABLE OF ty_s_type WITH DEFAULT KEY.

    "! A handful of symbologies with a value that encodes cleanly - enough to
    "! fill a dropdown and see the control work. bwip-js accepts many more;
    "! any BWIPP id can be passed to render( ) directly.
    CLASS-METHODS get_types
      RETURNING
        VALUE(result) TYPE ty_t_type.

    "! Emit &lt;z2ui5_cci:Barcode/&gt; into an existing view.
    "!
    "! @parameter view            | the builder positioned at the parent element
    "! @parameter bcid            | symbology, e.g. `qrcode`, `ean13`
    "! @parameter text            | the value to encode
    "! @parameter alttext         | text printed instead of the encoded value
    "! @parameter scale           | pixel scaling factor
    "! @parameter height          | bar height in millimetres
    "! @parameter includetext     | `false` to omit the human readable line
    "! @parameter textalign       | `left`, `center` or `right`
    "! @parameter rotate          | `N`, `R`, `I` or `L` (0/90/180/270 degrees)
    "! @parameter backgroundcolor | hex colour behind the bars, e.g. `FFFFFF`
    "! @parameter options         | raw BWIPP option string, e.g. `eclevel=M`
    "! @parameter renderas        | `canvas` or `svg`
    "! @parameter liburl          | overrides where bwip-js is loaded from
    "! @parameter error           | client->_event( ... ) fired when the
    "!                              symbology rejected the input
    "! @parameter result          | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view            TYPE REF TO z2ui5_cl_ui5_view_builder
        bcid            TYPE string
        text            TYPE string
        alttext         TYPE string OPTIONAL
        scale           TYPE string OPTIONAL
        height          TYPE string OPTIONAL
        includetext     TYPE string OPTIONAL
        textalign       TYPE string OPTIONAL
        rotate          TYPE string OPTIONAL
        backgroundcolor TYPE string OPTIONAL
        options         TYPE string OPTIONAL
        renderas        TYPE string OPTIONAL
        liburl          TYPE string OPTIONAL
        error           TYPE string OPTIONAL
      RETURNING
        VALUE(result)   TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_barcode IMPLEMENTATION.

  METHOD get_types.

    DATA temp1 TYPE z2ui5_cl_cci_barcode=>ty_t_type.
    DATA temp2 LIKE LINE OF temp1.
    CLEAR temp1.

    CLEAR temp2.
    temp2-bcid = `qrcode`.
    temp2-text = `QR Code`.
    temp2-example = `https://abap2UI5.org`.
    temp2-options = `eclevel=M`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `datamatrix`.
    temp2-text = `DataMatrix`.
    temp2-example = `abap2UI5`.
    temp2-options = ``.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `code128`.
    temp2-text = `Code 128`.
    temp2-example = `ABAP2UI5-0815`.
    temp2-options = `includetext`.
    temp2-height = `10`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `ean13`.
    temp2-text = `EAN-13`.
    temp2-example = `9520123456788`.
    temp2-options = `includetext guardwhitespace`.
    temp2-height = `10`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `ean8`.
    temp2-text = `EAN-8`.
    temp2-example = `96385074`.
    temp2-options = `includetext guardwhitespace`.
    temp2-height = `10`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `upca`.
    temp2-text = `UPC-A`.
    temp2-example = `012345000058`.
    temp2-options = `includetext`.
    temp2-height = `10`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `isbn`.
    temp2-text = `ISBN`.
    temp2-example = `978-1-56581-231-4 90000`.
    temp2-options = `includetext guardwhitespace`.
    temp2-height = `10`.
    INSERT temp2 INTO TABLE temp1.
    CLEAR temp2.
    temp2-bcid = `pdf417`.
    temp2-text = `PDF417`.
    temp2-example = `abap2UI5 custom controls`.
    temp2-options = ``.
    INSERT temp2 INTO TABLE temp1.
    result = temp1.

  ENDMETHOD.

  METHOD render.

    DATA temp3 TYPE z2ui5_cl_cci=>ty_t_attr.
    DATA temp1 LIKE LINE OF temp3.
    DATA temp2 LIKE LINE OF temp3.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp5 LIKE LINE OF temp3.
    DATA temp6 LIKE LINE OF temp3.
    DATA temp7 LIKE LINE OF temp3.
    DATA temp8 LIKE LINE OF temp3.
    DATA temp9 LIKE LINE OF temp3.
    DATA temp10 LIKE LINE OF temp3.
    DATA temp11 LIKE LINE OF temp3.
    DATA temp12 LIKE LINE OF temp3.
    DATA temp13 LIKE LINE OF temp3.
    DATA temp14 LIKE LINE OF temp3.
    CLEAR temp3.

    temp1 = |bcid={ bcid }|.
    INSERT temp1 INTO TABLE temp3.

    temp2 = |text={ text }|.
    INSERT temp2 INTO TABLE temp3.

    temp4 = |altText={ alttext }|.
    INSERT temp4 INTO TABLE temp3.

    temp5 = |scale={ scale }|.
    INSERT temp5 INTO TABLE temp3.

    temp6 = |height={ height }|.
    INSERT temp6 INTO TABLE temp3.

    temp7 = |includeText={ includetext }|.
    INSERT temp7 INTO TABLE temp3.

    temp8 = |textAlign={ textalign }|.
    INSERT temp8 INTO TABLE temp3.

    temp9 = |rotate={ rotate }|.
    INSERT temp9 INTO TABLE temp3.

    temp10 = |backgroundColor={ backgroundcolor }|.
    INSERT temp10 INTO TABLE temp3.

    temp11 = |options={ options }|.
    INSERT temp11 INTO TABLE temp3.

    temp12 = |renderAs={ renderas }|.
    INSERT temp12 INTO TABLE temp3.

    temp13 = |libUrl={ liburl }|.
    INSERT temp13 INTO TABLE temp3.

    temp14 = |error={ error }|.
    INSERT temp14 INTO TABLE temp3.
    result = z2ui5_cl_cci=>tag(
        view = view
        name = `Barcode`
        a    = temp3 ).

  ENDMETHOD.

ENDCLASS.
