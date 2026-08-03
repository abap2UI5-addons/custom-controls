"! <p class="shorttext synchronized" lang="en">test-cc - frontend bootstrap</p>
"!
"! Collects the JavaScript of every custom control in this library into one
"! string, ready to be handed to abap2UI5 through z2ui5_if_exit.
"!
"! The result is executed inside the z2ui5/Component.js module of the embedded
"! frontend, i.e. before the first XML view is built. Every control registers
"! itself under an explicit module name (sap.ui.define("testcc/cc/...")), so
"! the ui5loader resolves <testcc:Counter/> straight from its registry - no
"! HTTP request, no resourceRoot, no second BSP needed.
"!
"! Systems that run the abap2UI5-frontend BSP do NOT execute this - see the
"! "Known limitation" section of README.md.
CLASS zcl_testcc_bootstrap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! The JavaScript of all custom controls of this library.
    "!
    "! Wire it into abap2UI5 from your own z2ui5_if_exit implementation:
    "!   cs_config-custom_js = zcl_testcc_bootstrap=>get_js( ).
    "! ZCL_TESTCC_EXIT does exactly that, for systems that have no exit yet.
    CLASS-METHODS get_js
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_testcc_bootstrap IMPLEMENTATION.

  METHOD get_js.

    " one line per control - add new controls here
    result = |{ zcl_testcc_counter=>get_js( ) }\n|.

  ENDMETHOD.

ENDCLASS.
