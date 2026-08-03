"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo spreadsheet</p>
"!
"! Start with: <em>?app_start=zcl_z2ui5cc_demo_spreadsheet</em>
"!
"! A table with an export button in its toolbar. Pressing it builds the .xlsx
"! in the browser from the table's binding - the rows do not travel to the
"! backend again - and the <em>exported</em> event reports back here, so the
"! log below shows that the frontend action and the ABAP app stay in sync.
"!
"! Needs SAPUI5; on OpenUI5 the button is disabled and says why.
CLASS zcl_z2ui5cc_demo_spreadsheet DEFINITION
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

    DATA t_row    TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA t_column TYPE zcl_z2ui5cc_spreadsheet=>ty_t_column.
    DATA t_log    TYPE STANDARD TABLE OF ty_s_log WITH EMPTY KEY.
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


CLASS zcl_z2ui5cc_demo_spreadsheet IMPLEMENTATION.

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

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).

    DATA(page) = view->open( n  = `View`
                             ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = |xmlns:{ zcl_z2ui5cc=>c_ns }|
              v = zcl_z2ui5cc=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - spreadsheet export`
            )->a( n = `showNavButton`
                  v = `true`
            )->a( n = `navButtonPress`
                  v = client->_event( `BACK` ) ).

    DATA(table) = page->open( `Table`
                      )->a( n = `id`
                            v = `exportTable`
                      )->a( n = `items`
                            v = client->_bind( t_row )
                      )->a( n = `class`
                            v = `sapUiSmallMargin` ).

    " the export button lives in the table's own toolbar
    DATA(toolbar) = table->open( `headerToolbar`
                        )->open( `OverflowToolbar`
                            )->leaf( `Title`
                                )->a( n = `text`
                                      v = `Stock`
                            )->leaf( `ToolbarSpacer` ).

    zcl_z2ui5cc_spreadsheet=>render(
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
                        custom_filter = NEW zcl_z2ui5cc_json_filter( )
                        custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
                                            iv_first_json_upper = abap_false ) ) ).

    DATA(columns) = table->open( `columns` ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Row` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Product` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Created` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Author` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Location` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Quantity` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Unit` )->shut( ).
    columns->open( `Column` )->leaf( `Text` )->a( n = `text` v = `Price` )->shut( ).

    table->open( `items`
        )->open( `ColumnListItem`
            )->open( `cells`
                )->leaf( `Text` )->a( n = `text` v = `{ROWID}`
                )->leaf( `Text` )->a( n = `text` v = `{PRODUCT}`
                )->leaf( `Text` )->a( n = `text` v = `{CREATED}`
                )->leaf( `Text` )->a( n = `text` v = `{AUTHOR}`
                )->leaf( `Text` )->a( n = `text` v = `{LOCATION}`
                )->leaf( `Text` )->a( n = `text` v = `{QUANTITY}`
                )->leaf( `Text` )->a( n = `text` v = `{UNIT}`
                )->leaf( `Text` )->a( n = `text` v = `{PRICE}` ).

    page->open( `List`
        )->a( n = `headerText`
              v = `Export log`
        )->a( n = `items`
              v = client->_bind( t_log )
        )->a( n = `class`
              v = `sapUiSmallMargin`
        )->open( `items`
            )->leaf( `StandardListItem`
                )->a( n = `title`
                      v = `{TEXT}` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `EXPORTED`.
        " status already carries what the CONTROL wrote into the model
        INSERT VALUE #( text = |export { lines( t_log ) + 1 }: { status }| )
               INTO TABLE t_log.
        client->view_model_update( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    t_row = VALUE #(
      ( rowid = `1` product = `table`    created = `01.01.2023` author = `Olaf`
        location = `AREA_001` quantity = 400  unit = `PC` price = '1000.50' currency = `EUR` )
      ( rowid = `2` product = `chair`    created = `01.01.2022` author = `Karlo`
        location = `AREA_001` quantity = 123  unit = `PC` price = '2000.55' currency = `USD` )
      ( rowid = `3` product = `sofa`     created = `01.05.2021` author = `Elin`
        location = `AREA_002` quantity = 700  unit = `PC` price = '3000.11' currency = `CNY` )
      ( rowid = `4` product = `computer` created = `27.01.2023` author = `Theo`
        location = `AREA_002` quantity = 200  unit = `EA` price = '4000.88' currency = `USD` )
      ( rowid = `5` product = `printer`  created = `01.01.2023` author = `Renate`
        location = `AREA_003` quantity = 90   unit = `PC` price = '5000.47' currency = `EUR` )
      ( rowid = `6` product = `desk`     created = `01.01.2023` author = `Angela`
        location = `AREA_003` quantity = 1110 unit = `PC` price = '6000.33' currency = `GBP` ) ).

    " the workbook, in export order - independent of what the table shows.
    " `property` is the field name as it appears in the model: upper case.
    t_column = VALUE #(
      ( label = `Index`    property = `ROWID`    type = `String` )
      ( label = `Product`  property = `PRODUCT`  type = `String` )
      ( label = `Date`     property = `CREATED`  type = `String` )
      ( label = `Name`     property = `AUTHOR`   type = `String` )
      ( label = `Location` property = `LOCATION` type = `String` )
      ( label = `Quantity` property = `QUANTITY` type = `Number` delimiter = abap_true )
      ( label = `Unit`     property = `UNIT`     type = `String` )
      ( label = `Price`    property = `PRICE`    type = `Currency`
        unit_property = `CURRENCY` width = 14 scale = 2 ) ).

  ENDMETHOD.

ENDCLASS.
