"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo spreadsheet</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_02</em>
"!
"! A table with an export button in its toolbar. Pressing it builds the .xlsx
"! in the browser from the table's binding - the rows do not travel to the
"! backend again - and the <em>exported</em> event reports back here, so the
"! log below shows that the frontend action and the ABAP app stay in sync.
"!
"! Needs SAPUI5; on OpenUI5 the button is disabled and says why.
CLASS z2ui5_cl_cci_sample_02 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_row,
        rowid    TYPE string,
        product  TYPE string,
        created  TYPE string,
        author   TYPE string,
        location TYPE string,
        quantity TYPE i,
        unit     TYPE string,
        price    TYPE p LENGTH 10 DECIMALS 2,
        currency TYPE string,
      END OF ty_s_row.

    TYPES:
      BEGIN OF ty_s_log,
        text TYPE string,
      END OF ty_s_log.

    DATA t_row    TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
    DATA t_column TYPE z2ui5_cl_cci_spreadsheet=>ty_t_column.
    DATA t_log    TYPE STANDARD TABLE OF ty_s_log WITH DEFAULT KEY.
    "! written by the control before it fires `exported` - an event parameter
    "! stays in the frontend, a bound property reaches ABAP
    DATA status   TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_02 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ) IS NOT INITIAL.
      model_init( ).
      view_display( ).
    ELSEIF client->check_on_event( ) IS NOT INITIAL.
      on_event( ).
    ELSEIF client->check_on_navigated( ) IS NOT INITIAL.
      view_display( ).
    ENDIF.

  ENDMETHOD.

  METHOD view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA table TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA columns TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).


    page = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = |xmlns:{ z2ui5_cl_cci=>c_ns }|
              v = z2ui5_cl_cci=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Spreadsheet Export`
            ).


    table = page->ele( `Table`
                      )->a( n = `id`
                            v = `exportTable`
                      )->a( n = `items`
                            v = client->_bind( t_row )
                      " see z2ui5_cl_cci_sample_00: width=auto belongs with a margin
                      " class, or the table is 100% + margins and overflows
                      )->a( n = `width`
                            v = `auto`
                      )->a( n = `class`
                            v = `sapUiResponsiveMargin` ).

    " the export button lives in the table's own toolbar

    toolbar = table->ele( `headerToolbar`
                        )->ele( `OverflowToolbar`
                            )->tag( `Title`
                                )->a( n = `text`
                                      v = `Stock`
                            )->tag( `ToolbarSpacer` ).

    z2ui5_cl_cci_spreadsheet=>render(
        view      = toolbar
        tableid   = `exportTable`
        text      = `Export`
        type      = `Emphasized`
        filename  = `stock.xlsx`
        sheetname = `Stock`
        status    = client->_bind( status )
        exported  = client->_event( `EXPORTED` )
        columns   = client->_bind(
                        val           = t_column
                        omit_initial  = abap_true
                        custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                            iv_first_json_upper = abap_false ) ) ).

    " Eight columns without widths make sap.m.Table as wide as their content
    " wants, which pushes the toolbar's Export button off the right edge. Fixed
    " widths keep the table inside the page; the ones that are only detail get
    " demandPopin so a narrow screen folds them under the row.

    columns = table->ele( `columns` ).
    columns->ele( `Column`
        )->a( n = `width` v = `5rem`
        )->tag( `Text` )->a( n = `text` v = `Row` )->end( ).
    columns->ele( `Column`
        )->a( n = `width` v = `9rem`
        )->tag( `Text` )->a( n = `text` v = `Product` )->end( ).
    columns->ele( `Column`
        )->a( n = `width` v = `8rem`
        )->a( n = `minScreenWidth` v = `Tablet`
        )->a( n = `demandPopin` v = `true`
        )->tag( `Text` )->a( n = `text` v = `Created` )->end( ).
    columns->ele( `Column`
        )->a( n = `width` v = `8rem`
        )->a( n = `minScreenWidth` v = `Tablet`
        )->a( n = `demandPopin` v = `true`
        )->tag( `Text` )->a( n = `text` v = `Author` )->end( ).
    columns->ele( `Column`
        )->a( n = `minScreenWidth` v = `Desktop`
        )->a( n = `demandPopin` v = `true`
        )->tag( `Text` )->a( n = `text` v = `Location` )->end( ).
    columns->ele( `Column`
        )->a( n = `width` v = `7rem`
        )->a( n = `hAlign` v = `End`
        )->tag( `Text` )->a( n = `text` v = `Quantity` )->end( ).
    columns->ele( `Column`
        )->a( n = `width` v = `5rem`
        )->a( n = `minScreenWidth` v = `Tablet`
        )->a( n = `demandPopin` v = `true`
        )->tag( `Text` )->a( n = `text` v = `Unit` )->end( ).
    columns->ele( `Column`
        )->a( n = `width` v = `8rem`
        )->a( n = `hAlign` v = `End`
        )->tag( `Text` )->a( n = `text` v = `Price` )->end( ).

    table->ele( `items`
        )->ele( `ColumnListItem`
            )->ele( `cells`
                )->tag( `Text` )->a( n = `text` v = `{ROWID}`
                )->tag( `Text` )->a( n = `text` v = `{PRODUCT}`
                )->tag( `Text` )->a( n = `text` v = `{CREATED}`
                )->tag( `Text` )->a( n = `text` v = `{AUTHOR}`
                )->tag( `Text` )->a( n = `text` v = `{LOCATION}`
                )->tag( `Text` )->a( n = `text` v = `{QUANTITY}`
                )->tag( `Text` )->a( n = `text` v = `{UNIT}`
                )->tag( `Text` )->a( n = `text` v = `{PRICE}` ).

    page->ele( `List`
        )->a( n = `headerText`
              v = `Export log`
        )->a( n = `items`
              v = client->_bind( t_log )
        )->a( n = `class`
              v = `sapUiSmallMargin`
        )->ele( `items`
            )->tag( `StandardListItem`
                )->a( n = `title`
                      v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.
      DATA temp1 TYPE z2ui5_cl_cci_sample_02=>ty_s_log.

    IF client->get( )-event = `EXPORTED`.
      " status already carries what the CONTROL wrote into the model

      CLEAR temp1.
      temp1-text = |export { lines( t_log ) + 1 }: { status }|.
      INSERT temp1
             INTO TABLE t_log.
    ENDIF.

  ENDMETHOD.

  METHOD model_init.

    DATA temp2 LIKE t_row.
    DATA temp3 LIKE LINE OF temp2.
    DATA temp4 TYPE z2ui5_cl_cci_spreadsheet=>ty_t_column.
    DATA temp5 LIKE LINE OF temp4.
    CLEAR temp2.

    temp3-rowid = `1`.
    temp3-product = `table`.
    temp3-created = `01.01.2023`.
    temp3-author = `Olaf`.
    temp3-location = `AREA_001`.
    temp3-quantity = 400.
    temp3-unit = `PC`.
    temp3-price = '1000.50'.
    temp3-currency = `EUR`.
    INSERT temp3 INTO TABLE temp2.
    temp3-rowid = `2`.
    temp3-product = `chair`.
    temp3-created = `01.01.2022`.
    temp3-author = `Karlo`.
    temp3-location = `AREA_001`.
    temp3-quantity = 123.
    temp3-unit = `PC`.
    temp3-price = '2000.55'.
    temp3-currency = `USD`.
    INSERT temp3 INTO TABLE temp2.
    temp3-rowid = `3`.
    temp3-product = `sofa`.
    temp3-created = `01.05.2021`.
    temp3-author = `Elin`.
    temp3-location = `AREA_002`.
    temp3-quantity = 700.
    temp3-unit = `PC`.
    temp3-price = '3000.11'.
    temp3-currency = `CNY`.
    INSERT temp3 INTO TABLE temp2.
    temp3-rowid = `4`.
    temp3-product = `computer`.
    temp3-created = `27.01.2023`.
    temp3-author = `Theo`.
    temp3-location = `AREA_002`.
    temp3-quantity = 200.
    temp3-unit = `EA`.
    temp3-price = '4000.88'.
    temp3-currency = `USD`.
    INSERT temp3 INTO TABLE temp2.
    temp3-rowid = `5`.
    temp3-product = `printer`.
    temp3-created = `01.01.2023`.
    temp3-author = `Renate`.
    temp3-location = `AREA_003`.
    temp3-quantity = 90.
    temp3-unit = `PC`.
    temp3-price = '5000.47'.
    temp3-currency = `EUR`.
    INSERT temp3 INTO TABLE temp2.
    temp3-rowid = `6`.
    temp3-product = `desk`.
    temp3-created = `01.01.2023`.
    temp3-author = `Angela`.
    temp3-location = `AREA_003`.
    temp3-quantity = 1110.
    temp3-unit = `PC`.
    temp3-price = '6000.33'.
    temp3-currency = `GBP`.
    INSERT temp3 INTO TABLE temp2.
    t_row = temp2.

    " the workbook, in export order - independent of what the table shows.
    " `property` is the field name as it appears in the model: upper case.

    CLEAR temp4.

    CLEAR temp5.
    temp5-label = `Index`.
    temp5-property = `ROWID`.
    temp5-type = `String`.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Product`.
    temp5-property = `PRODUCT`.
    temp5-type = `String`.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Date`.
    temp5-property = `CREATED`.
    temp5-type = `String`.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Name`.
    temp5-property = `AUTHOR`.
    temp5-type = `String`.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Location`.
    temp5-property = `LOCATION`.
    temp5-type = `String`.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Quantity`.
    temp5-property = `QUANTITY`.
    temp5-type = `Number`.
    temp5-delimiter = abap_true.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Unit`.
    temp5-property = `UNIT`.
    temp5-type = `String`.
    INSERT temp5 INTO TABLE temp4.
    CLEAR temp5.
    temp5-label = `Price`.
    temp5-property = `PRICE`.
    temp5-type = `Currency`.
    temp5-unit_property = `CURRENCY`.
    temp5-width = 14.
    temp5-scale = 2.
    INSERT temp5 INTO TABLE temp4.
    t_column = temp4.

  ENDMETHOD.

ENDCLASS.
