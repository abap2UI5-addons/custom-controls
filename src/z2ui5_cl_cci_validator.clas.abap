"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Validator</p>
"!
"! The ABAP half of the z2ui5_cci.cc.Validator custom control: the view builder
"! that emits its XML element, plus the rule type the form is checked against.
"!
"! The app declares what each field has to satisfy, binds the rule table, and
"! raises <em>trigger</em> when it wants the form checked. The control marks
"! every offending field and writes <em>valid</em> and <em>errors</em> back
"! into the model, so the roundtrip that raised the trigger already brings the
"! verdict home - no second call, no JavaScript in the app.
"!
"! Ported from abap2UI5-addons/custom-controls (z2ui5_cl_cc_validator). The
"! original evaluated a JSON schema with ajv from a CDN and could only address
"! three fixed field names; this one takes a table of rules, needs no external
"! library and reports its result to ABAP.
CLASS z2ui5_cl_cci_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      "! One rule. <em>field</em> is the control id as the app wrote it in the
      "! view; it is resolved against the view the control sits in.
      "!
      "! Leave a constraint initial and it is not checked (see
      "! z2ui5_cl_cci_json_filter). An empty field only fails <em>required</em> -
      "! every other constraint measures a filled value.
      BEGIN OF ty_s_rule,
        field      TYPE string,
        "! `number`, `integer` or empty for a plain string
        type       TYPE string,
        "! `email` or `date`
        format     TYPE string,
        "! regular expression the value has to match
        pattern    TYPE string,
        required   TYPE abap_bool,
        minlength  TYPE i,
        maxlength  TYPE i,
        minimum    TYPE i,
        maximum    TYPE i,
        "! overrides the generated text, e.g. for a translated message
        message    TYPE string,
      END OF ty_s_rule.
    TYPES ty_t_rule TYPE STANDARD TABLE OF ty_s_rule WITH EMPTY KEY.

    TYPES:
      "! One rejected field, as the control writes it back.
      BEGIN OF ty_s_error,
        field   TYPE string,
        message TYPE string,
      END OF ty_s_error.
    TYPES ty_t_error TYPE STANDARD TABLE OF ty_s_error WITH EMPTY KEY.

    "! Emit &lt;z2ui5_cci:Validator/&gt; into an existing view.
    "!
    "! Bind `rules` with this library's JSON filter, or every constraint the
    "! app left alone arrives as 0 and rejects everything:
    "!
    "!   rules = client->_bind( val           = mt_rules
    "!                          custom_filter = NEW z2ui5_cl_cci_json_filter( ) )
    "!
    "! @parameter view      | the builder positioned at the parent element
    "! @parameter rules     | bind of a ty_t_rule table, see above
    "! @parameter trigger   | bind an integer; raising it runs the check
    "! @parameter valid     | bind two-way to receive the verdict
    "! @parameter errors    | bind two-way to receive a ty_t_error table
    "! @parameter validated | client->_event( ... ) fired after every check
    "! @parameter result    | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view          TYPE REF TO z2ui5_cl_ui5_view_builder
        rules         TYPE string
        trigger       TYPE string
        valid         TYPE string OPTIONAL
        errors        TYPE string OPTIONAL
        validated     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS z2ui5_cl_cci_validator IMPLEMENTATION.

  METHOD render.

    result = z2ui5_cl_cci=>tag(
        view = view
        name = `Validator`
        a    = VALUE #( ( |rules={ rules }| )
                        ( |trigger={ trigger }| )
                        ( |valid={ valid }| )
                        ( |errors={ errors }| )
                        ( |validated={ validated }| ) ) ).

  ENDMETHOD.

ENDCLASS.
