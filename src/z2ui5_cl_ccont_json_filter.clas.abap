"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - JSON filter</p>
"!
"! Drops the initial values of an ABAP structure on the way into a bound
"! configuration object.
"!
"! Several controls in this library take a whole configuration structure as one
"! property - a Chart.js config, an ImageMapster option set, the workbook
"! columns of the spreadsheet export. ABAP has no "unset" for a structure
"! component: every field the app did not touch still serializes, as `""`, `0`
"! or `false`. Handing that to a JavaScript library is not the same as leaving
"! the option out - `borderWidth: 0` draws no border, an empty `type` picks no
"! chart type. So the initial values are filtered out and the library's own
"! defaults survive.
"!
"! Use it on the bind of such a property:
"!
"!   client->_bind( val           = ms_config
"!                  custom_filter = NEW z2ui5_cl_ccont_json_filter( )
"!                  custom_mapper = z2ui5_cl_ajson_mapping=>create_camel_case(
"!                                      iv_first_json_upper = abap_false ) )
"!
"! The consequence to know about: a value that IS meaningfully zero, empty or
"! false cannot be sent this way - set it on the control's own property, or
"! express it in a field the library reads differently.
CLASS z2ui5_cl_ccont_json_filter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_ajson_filter.
    " A plain comment, not ABAP Doc: an INTERFACES statement carries no
    " documentation, and the compiler warns about one placed here.
    "
    " abap2UI5 keeps the filter as a reference ON THE BOUND ATTRIBUTE and
    " serializes the whole app between roundtrips - so a filter that cannot be
    " serialized survives the first render and is gone from the second one on.
    "
    " Nothing warns about it: the framework only checks custom_filter_back and
    " custom_mapper_back for serializability, never the forward ones. The
    " symptom is a control that renders correctly once and then ignores every
    " update, because from the second roundtrip on it receives the unfiltered
    " structure - every untouched field back as `0`, `""` or `false`.
    INTERFACES if_serializable_object.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_ccont_json_filter IMPLEMENTATION.

  METHOD z2ui5_if_ajson_filter~keep_node.

    rv_keep = abap_true.

    CASE iv_visit.

      WHEN z2ui5_if_ajson_filter=>visit_type-open
        OR z2ui5_if_ajson_filter=>visit_type-close.
        " an object/array whose every child was filtered out carries no
        " information either - emitting `{}` would still override a default
        IF is_node-children = 0.
          rv_keep = abap_false.
        ENDIF.

      WHEN z2ui5_if_ajson_filter=>visit_type-value.

        CASE is_node-type.
          WHEN z2ui5_if_ajson_types=>node_type-boolean.
            IF is_node-value = `false`.
              rv_keep = abap_false.
            ENDIF.
          WHEN z2ui5_if_ajson_types=>node_type-number.
            IF is_node-value CO ` 0.`.
              rv_keep = abap_false.
            ENDIF.
          WHEN z2ui5_if_ajson_types=>node_type-string.
            IF is_node-value IS INITIAL.
              rv_keep = abap_false.
            ENDIF.
        ENDCASE.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
