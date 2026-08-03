"! <p class="shorttext synchronized" lang="en">abap2UI5 custom controls - Messaging</p>
"!
"! The ABAP half of the z2ui5cc.cc.Messaging custom control: the view builder
"! that emits its XML element, plus the row type of the table it mirrors the
"! UI5 message model into.
"!
"! UI5 collects messages in one place - a binding whose type constraints are
"! violated files one automatically. That model lives in the frontend, so an
"! abap2UI5 app normally cannot see it. Bind <em>items</em> two-way and the
"! bridge works in both directions: frontend validation errors show up in the
"! table, and rows the backend puts into the table become UI5 messages, with
"! the value state on the field they point at.
"!
"! Needs UI5 1.118 or newer (sap/ui/core/Messaging).
"!
"! Ported from abap2UI5-addons/custom-controls, which shipped it twice -
"! z2ui5_cl_cc_messaging and z2ui5_cl_cc_message_m, the second one on the
"! deprecated MessageManager. Only the modern one is carried over.
CLASS zcl_z2ui5cc_messaging DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    "! One message. <em>target</em> is <em>&lt;control id&gt;/&lt;property&gt;</em>
    "! with the id as the app wrote it in the view, e.g. `quantity/value`; it
    "! is resolved against the view the control sits in, so a nested view or a
    "! popup needs no special handling. <em>type</em> is a UI5 message type:
    "! Error, Warning, Success, Information or None.
    TYPES:
      BEGIN OF ty_s_item,
        message        TYPE string,
        description    TYPE string,
        type           TYPE string,
        target         TYPE string,
        additionaltext TYPE string,
        date           TYPE string,
        descriptionurl TYPE string,
        persistent     TYPE abap_bool,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

    "! Emit <z2ui5cc:Messaging/> into an existing view.
    "!
    "! @parameter view           | the builder positioned at the parent element
    "! @parameter items          | bind a ty_t_item table two-way
    "! @parameter registerview   | `false` to not register the view for
    "!                             binding validation messages
    "! @parameter messageschange | client->_event( ... ) fired when the
    "!                             frontend changed the message list
    "! @parameter result         | the unchanged view builder, for chaining
    CLASS-METHODS render
      IMPORTING
        view           TYPE REF TO z2ui5_cl_ai_xml
        items          TYPE string
        registerview   TYPE string OPTIONAL
        messageschange TYPE string OPTIONAL
      RETURNING
        VALUE(result)  TYPE REF TO z2ui5_cl_ai_xml.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_z2ui5cc_messaging IMPLEMENTATION.

  METHOD render.

    result = zcl_z2ui5cc=>leaf(
        view = view
        name = `Messaging`
        a    = VALUE #( ( |items={ items }| )
                        ( |registerView={ registerview }| )
                        ( |messagesChange={ messageschange }| ) ) ).

  ENDMETHOD.

ENDCLASS.
