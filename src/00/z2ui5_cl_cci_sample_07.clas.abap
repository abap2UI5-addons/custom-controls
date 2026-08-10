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

    DATA t_collection TYPE STANDARD TABLE OF ty_s_key WITH EMPTY KEY.
    DATA t_animation  TYPE STANDARD TABLE OF ty_s_key WITH EMPTY KEY.
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
        )->a( n = `xmlns:core`
              v = `sap.ui.core`
        )->a( n = |xmlns:{ z2ui5_cl_cci=>c_ns }|
              v = z2ui5_cl_cci=>c_ns_uri
        )->a( n = `displayBlock`
              v = `true`
        )->a( n = `height`
              v = `100%`

        )->open( `Page`
            )->a( n = `title`
                  v = `abap2UI5 - Font Awesome`
            ).

    " one element, and both ways of using Font Awesome are available
    z2ui5_cl_cci_font_awesome=>render( page ).

    DATA(box) = page->open( `VBox`
                    )->a( n = `class`
                          v = `sapUiMediumMargin` ).

    box->leaf( `Label`
           )->a( n = `text`
                 v = `collection`
       )->open( `ComboBox`
           )->a( n = `selectedKey`
                 v = client->_bind( collection )
           )->a( n = `items`
                 v = client->_bind( t_collection )
           )->a( n = `width`
                 v = `20rem`
           )->a( n = `change`
                 v = client->_event( `COLLECTION` )
           )->open( `items`
               )->leaf( n  = `Item`
                        ns = `core`
                   )->a( n = `key`
                         v = `{KEY}`
                   )->a( n = `text`
                         v = `{TEXT}` ).

    box->leaf( `Label`
           )->a( n = `text`
                 v = `icon name`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop`
       )->leaf( `Input`
           )->a( n = `value`
                 v = client->_bind( icon )
           )->a( n = `width`
                 v = `20rem`
           )->a( n = `change`
                 v = client->_event( `REFRESH` )

       )->leaf( `Label`
           )->a( n = `text`
                 v = `animation class`
           )->a( n = `class`
                 v = `sapUiSmallMarginTop` ).

    box->open( `ComboBox`
        )->a( n = `selectedKey`
              v = client->_bind( animation )
        )->a( n = `items`
              v = client->_bind( t_animation )
        )->a( n = `width`
              v = `20rem`
        )->a( n = `change`
              v = client->_event( `REFRESH` )
        )->open( `items`
            )->leaf( n  = `Item`
                     ns = `core`
                )->a( n = `key`
                      v = `{KEY}`
                )->a( n = `text`
                      v = `{TEXT}` ).

    DATA(result) = box->open( `Panel`
                       )->a( n = `headerText`
                             v = `Result`
                       )->a( n = `class`
                             v = `sapUiSmallMarginTop`
                       )->open( `content`
                           )->open( `HBox`
                               )->a( n = `alignItems`
                                     v = `Center`
                               )->a( n = `class`
                                     v = `sapUiSmallMargin` ).

    " as a UI5 icon, through the IconPool the control filled
    result->leaf( n  = `Icon`
                  ns = `core`
              )->a( n = `src`
                    v = client->_bind( icon_uri )
              )->a( n = `size`
                    v = `4rem`
              )->a( n = `color`
                    v = `#0a6ed1`
              )->a( n = `class`
                    v = client->_bind( css_class )

          )->leaf( `Button`
              )->a( n = `text`
                    v = `a button with the same icon`
              )->a( n = `icon`
                    v = client->_bind( icon_uri )
              )->a( n = `class`
                    v = `sapUiMediumMarginBegin` ).

    result->leaf( `Text`
              )->a( n = `text`
                    v = client->_bind( icon_uri ) ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD on_event.

    CASE client->get( )-event.

      WHEN `COLLECTION`.
        " switching the collection brings an icon that exists in it
        TRY.
            icon = t_collection[ key = collection ]-icon.
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.
        model_refresh( ).
        client->view_model_update( ).

      WHEN `REFRESH`.
        model_refresh( ).
        client->view_model_update( ).

    ENDCASE.

  ENDMETHOD.

  METHOD model_init.

    " Collection AND a matching icon: the two are not interchangeable. `github`
    " exists in fa-brands only, `heart` in fa-solid/fa-regular only - pairing a
    " collection with an icon it does not carry renders nothing at all, which
    " looks like a broken control rather than a wrong combination.
    t_collection = VALUE #(
      ( key  = z2ui5_cl_cci_font_awesome=>cs_collection-solid
        text = `fa-solid`   icon = `heart` )
      ( key  = z2ui5_cl_cci_font_awesome=>cs_collection-regular
        text = `fa-regular` icon = `face-smile` )
      ( key  = z2ui5_cl_cci_font_awesome=>cs_collection-brands
        text = `fa-brands`  icon = `github` ) ).

    t_animation = VALUE #(
      ( key = ``              text = `none` )
      ( key = `fa-beat`       text = `fa-beat` )
      ( key = `fa-bounce`     text = `fa-bounce` )
      ( key = `fa-fade`       text = `fa-fade` )
      ( key = `fa-flip`       text = `fa-flip` )
      ( key = `fa-shake`      text = `fa-shake` )
      ( key = `fa-spin`       text = `fa-spin` ) ).

    collection = z2ui5_cl_cci_font_awesome=>cs_collection-brands.
    icon       = t_collection[ key = collection ]-icon.
    animation  = `fa-bounce`.
    model_refresh( ).

  ENDMETHOD.

  METHOD model_refresh.

    icon_uri  = |sap-icon://{ collection }/{ icon }|.
    css_class = animation.

  ENDMETHOD.

ENDCLASS.
