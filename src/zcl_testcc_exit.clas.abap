"! <p class="shorttext synchronized" lang="en">test-cc - abap2UI5 exit (optional)</p>
"!
"! Hands this library's custom-control JavaScript to abap2UI5 through the
"! public z2ui5_if_exit extension point. This is the whole integration - the
"! framework needs no knowledge of the controls themselves.
"!
"! <strong>Only ONE exit class can be active per system.</strong>
"! z2ui5_cl_exit=>get_user_exit_class( ) scans for implementations of
"! Z2UI5_IF_EXIT, sorts them by class name and takes the first one. If your
"! system already has an exit, DELETE this class after the abapGit pull and
"! call the bootstrap from your own exit instead:
"!
"!   METHOD z2ui5_if_exit~set_config_http_get.
"!     cs_config-custom_js = zcl_testcc_bootstrap=>get_js( ).
"!   ENDMETHOD.
"!
"! Otherwise the two exits shadow each other and which one runs depends on
"! nothing but the alphabet.
CLASS zcl_testcc_exit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES z2ui5_if_exit.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_testcc_exit IMPLEMENTATION.

  METHOD z2ui5_if_exit~set_config_http_get.

    " cs_config arrives pre-filled by z2ui5_cl_exit (title, theme, bootstrap
    " src, CSP, security headers) - only add to it, never rebuild it
    cs_config-custom_js = |{ cs_config-custom_js }{ zcl_testcc_bootstrap=>get_js( ) }|.

  ENDMETHOD.

  METHOD z2ui5_if_exit~set_config_http_post.

    " nothing to change - keep the framework defaults (draft expiry, CSRF)

  ENDMETHOD.

ENDCLASS.
