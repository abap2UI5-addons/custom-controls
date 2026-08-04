"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Barcode</p>
"!
"! The ABAP half of the z2ui5cc.cc.Barcode custom control: the view builder
"! that emits its XML element, plus a list of symbologies to try it with.
"!
"! Rendering happens in the browser with bwip-js, which speaks every symbology
"! BWIPP knows - EAN, UPC, ISBN, Code 128, QR, DataMatrix, GS1 and about a
"! hundred more. No image is built in ABAP and none is transferred.
"!
"! Ported from abap2UI5-addons/js-libraries (z2ui5_cl_cc_bwipjs).
CLASS zcl_z2ui5cc_barcode DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! One symbology, with an example value and the options it wants.
    TYPES:
      BEGIN OF ty_s_type,
        bcid    TYPE string,
        text    TYPE string,
        example TYPE string,
        options TYPE string,
        "! bar height in mm - filled for the linear symbologies, empty for the
        "! matrix ones, where a height would stretch the symbol out of square
        height  TYPE string,
      END OF ty_s_type.
    TYPES ty_t_type TYPE STANDARD TABLE OF ty_s_type WITH EMPTY KEY.

    "! A handful of symbologies with a value that encodes cleanly - enough to
    "! fill a dropdown and see the control work. bwip-js accepts many more;
    "! any BWIPP id can be passed to render( ) directly.
    CLASS-METHODS get_types
      RETURNING
        VALUE(result) TYPE ty_t_type.

    "! Emit <z2ui5cc:Barcode/> into an existing view.
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
        view            TYPE REF TO z2ui5_cl_ai_xml
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
        VALUE(result)   TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_barcode IMPLEMENTATION.

  METHOD get_types.

    result = VALUE #(
      ( bcid = `qrcode`     text = `QR Code`
        example = `https://abap2UI5.org`            options = `eclevel=M` )
      ( bcid = `datamatrix` text = `DataMatrix`
        example = `abap2UI5`                        options = `` )
      ( bcid = `code128`    text = `Code 128`
        example = `ABAP2UI5-0815`                   options = `includetext`
        height = `10` )
      ( bcid = `ean13`      text = `EAN-13`
        example = `9520123456788`                   options = `includetext guardwhitespace`
        height = `10` )
      ( bcid = `ean8`       text = `EAN-8`
        example = `96385074`                        options = `includetext guardwhitespace`
        height = `10` )
      ( bcid = `upca`       text = `UPC-A`
        example = `012345000058`                    options = `includetext`
        height = `10` )
      ( bcid = `isbn`       text = `ISBN`
        example = `978-1-56581-231-4 90000`         options = `includetext guardwhitespace`
        height = `10` )
      ( bcid = `pdf417`     text = `PDF417`
        example = `abap2UI5 custom controls`        options = `` ) ).

  ENDMETHOD.

  METHOD render.

    result = zcl_z2ui5cc=>leaf(
        view = view
        name = `Barcode`
        a    = VALUE #( ( |bcid={ bcid }| )
                        ( |text={ text }| )
                        ( |altText={ alttext }| )
                        ( |scale={ scale }| )
                        ( |height={ height }| )
                        ( |includeText={ includetext }| )
                        ( |textAlign={ textalign }| )
                        ( |rotate={ rotate }| )
                        ( |backgroundColor={ backgroundcolor }| )
                        ( |options={ options }| )
                        ( |renderAs={ renderas }| )
                        ( |libUrl={ liburl }| )
                        ( |error={ error }| ) ) ).

  ENDMETHOD.

ENDCLASS.
