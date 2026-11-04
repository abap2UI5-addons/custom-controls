"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - demo Font Awesome</p>
"!
"! Start with: <em>?app_start=z2ui5_cl_cci_sample_07</em>
"!
"! One <em>FontAwesome</em> element in the view is the whole setup. After it,
"! two things work that do not otherwise:
"!
"!   sap-icon://fa-brands/github  a Font Awesome icon wherever UI5 takes one
"!   class="fa-solid fa-heart"    Font Awesome's own class names, including
"!                                its animations
"!
"! Both are shown side by side below, with the icon collection and the
"! animation picked from the two dropdowns.
CLASS z2ui5_cl_cci_sample_07 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    " ONLY bound data here - PUBLIC attributes are serialized every roundtrip
    TYPES:
      BEGIN OF ty_s_key,
        key  TYPE string,
        text TYPE string,
        "! an icon that exists in this collection
        icon TYPE string,
      END OF ty_s_key.

    DATA t_collection TYPE STANDARD TABLE OF ty_s_key WITH DEFAULT KEY.
    DATA t_animation  TYPE STANDARD TABLE OF ty_s_key WITH DEFAULT KEY.
    DATA collection   TYPE string.
    DATA animation    TYPE string.
    DATA icon         TYPE string.
    DATA icon_uri     TYPE string.
    DATA css_class    TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS model_init.
    METHODS model_refresh.

  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_sample_07 IMPLEMENTATION.

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
    DATA box TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA result TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory( ).


    page = view->ele( n  = `View`
                            ns = `mvc`
        )->a( n = `xmlns`
              v = `sap.m`
        )->a( n = `xmlns:mvc`
              v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core`
              v = `sap.ui.core`
        )->a( n = |xmlns:{ z2ui5_cl_cci=>c_ns }|
              v = z2ui5_cl_cci=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->ele( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Font Awesome`
            ).

    " one element, and both ways of using Font Awesome are available
    z2ui5_cl_cci_font_awesome=>render( page ).


    box = page->ele( `VBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `collection`
       )->ele( `ComboBox`
           )->a( n = `selectedKey`
                 v = client->_bind( collection )
           )->a( n = `items`
                 v = client->_bind( t_collection )
           )->a( n = `width`
                 v = `20rem`
           )->a( n = `change`
                 v = client->_event( `COLLECTION` )
           )->ele( `items`
               )->tag( n  = `Item`
                       ns = `core`
                   )->a( n = `key`
                         v = `{KEY}`
                   )->a( n = `text`
                         v = `{TEXT}` ).

    box->tag( `Label`
           )->a( n = `text`
                 v = `icon name`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->tag( `Input`
           )->a( n = `value`
                 v = client->_bind( icon )
           )->a( n = `width`
                 v = `20rem`
           )->a( n = `change`
                 v = client->_event( `REFRESH` )

       )->tag( `Label`
           )->a( n = `text`
                 v = `animation class`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    box->ele( `ComboBox`
        )->a( n = `selectedKey`
              v = client->_bind( animation )
        )->a( n = `items`
              v = client->_bind( t_animation )
        )->a( n = `width`
              v = `20rem`
        )->a( n = `change`
              v = client->_event( `REFRESH` )
        )->ele( `items`
            )->tag( n  = `Item`
                    ns = `core`
                )->a( n = `key`
                      v = `{KEY}`
                )->a( n = `text`
                      v = `{TEXT}` ).


    result = box->ele( `Panel`
                       )->a( n = `headerText`
                             v = `Result`
                       )->a( n = `class`
                             v = `sapUiSmallMarginTop`
                       )->ele( `content`
                           )->ele( `HBox`
                               )->a( n = `alignItems`
                                     v = `Center`
                               )->a( n = `class`
                                     v = `sapUiSmallMargin` ).

    " as a UI5 icon, through the IconPool the control filled
    result->tag( n  = `Icon`
                 ns = `core`
              )->a( n = `src`
                    v = client->_bind( icon_uri )
              )->a( n = `size`
                    v = `4rem`
              )->a( n = `color`
                    v = `#0a6ed1`
              )->a( n = `class`
                    v = client->_bind( css_class )

          )->tag( `Button`
              )->a( n = `text`
                    v = `a button with the same icon`
              )->a( n = `icon`
                    v = client->_bind( icon_uri )
              )->a( n = `class`
                    v = `sapUiMediumMarginBegin` ).

    result->tag( `Text`
              )->a( n = `text`
                    v = client->_bind( icon_uri ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.
            FIELD-SYMBOLS <temp1> LIKE LINE OF t_collection.
            DATA temp2 LIKE sy-tabix.

    CASE client->get( )-event.

      WHEN `COLLECTION`.
        " switching the collection brings an icon that exists in it
        TRY.


            temp2 = sy-tabix.
            READ TABLE t_collection WITH KEY key = collection ASSIGNING <temp1>.
            sy-tabix = temp2.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            icon = <temp1>-icon.
          CATCH cx_sy_itab_line_not_found ##NO_HANDLER.
        ENDTRY.
        model_refresh( ).

      WHEN `REFRESH`.
        model_refresh( ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    " Collection AND a matching icon: the two are not interchangeable. `github`
    " exists in fa-brands only, `heart` in fa-solid/fa-regular only - pairing a
    " collection with an icon it does not carry renders nothing at all, which
    " looks like a broken control rather than a wrong combination.
    DATA temp3 LIKE t_collection.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp5 LIKE t_animation.
    DATA temp6 LIKE LINE OF temp5.
    FIELD-SYMBOLS <temp7> LIKE LINE OF t_collection.
    DATA temp8 LIKE sy-tabix.
    CLEAR temp3.

    temp4-key = z2ui5_cl_cci_font_awesome=>cs_collection-solid.
    temp4-text = `fa-solid`.
    temp4-icon = `heart`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = z2ui5_cl_cci_font_awesome=>cs_collection-regular.
    temp4-text = `fa-regular`.
    temp4-icon = `face-smile`.
    INSERT temp4 INTO TABLE temp3.
    temp4-key = z2ui5_cl_cci_font_awesome=>cs_collection-brands.
    temp4-text = `fa-brands`.
    temp4-icon = `github`.
    INSERT temp4 INTO TABLE temp3.
    t_collection = temp3.


    CLEAR temp5.

    temp6-key = ``.
    temp6-text = `none`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `fa-beat`.
    temp6-text = `fa-beat`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `fa-bounce`.
    temp6-text = `fa-bounce`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `fa-fade`.
    temp6-text = `fa-fade`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `fa-flip`.
    temp6-text = `fa-flip`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `fa-shake`.
    temp6-text = `fa-shake`.
    INSERT temp6 INTO TABLE temp5.
    temp6-key = `fa-spin`.
    temp6-text = `fa-spin`.
    INSERT temp6 INTO TABLE temp5.
    t_animation = temp5.

    collection = z2ui5_cl_cci_font_awesome=>cs_collection-brands.


    temp8 = sy-tabix.
    READ TABLE t_collection WITH KEY key = collection ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    icon       = <temp7>-icon.
    animation  = `fa-bounce`.
    model_refresh( ).

  ENDMETHOD.

  METHOD model_refresh.

    icon_uri  = |sap-icon://{ collection }/{ icon }|.
    css_class = animation.

  ENDMETHOD.

ENDCLASS.
