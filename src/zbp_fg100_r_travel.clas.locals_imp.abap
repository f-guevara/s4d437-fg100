CLASS lhc_ZFG100_R_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ZFG100_R_Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZFG100_R_Travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION ZFG100_R_Travel~cancel_travel.
   METHODS validateDescription FOR VALIDATE ON SAVE
  IMPORTING keys FOR Travel~validateDescription.
   METHODS validateCustomer FOR VALIDATE ON SAVE
  IMPORTING keys FOR Travel~validateCustomer.
   METHODS earlynumbering_create FOR NUMBERING
     IMPORTING entities FOR CREATE Travel.
ENDCLASS.

CLASS lhc_ZFG100_R_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
  result = CORRESPONDING #( keys ).

  LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
    DATA(rc) = /lrn/cl_s4d437_model=>authority_check(
                 i_agencyid = <result>-agencyid
                 i_actvt    = '02' ).

    IF rc <> 0.
      <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
      <result>-%update               = if_abap_behv=>auth-unauthorized.
    ELSE.
      <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
      <result>-%update               = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels INTO DATA(travel).
    IF travel-status <> 'C'.
      MODIFY ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
        ENTITY Travel
        UPDATE
        FIELDS ( status )
        WITH VALUE #( ( %tky   = travel-%tky
                        status = 'C' ) ).
    ELSE.
      APPEND VALUE #( %tky = travel-%tky )
        TO failed-travel.
      APPEND VALUE #(
        %tky = travel-%tky
        %msg = NEW /lrn/cm_s4d437(
          textid = /lrn/cm_s4d437=>already_canceled ) )
        TO reported-travel.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

METHOD validateDescription.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Description )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    IF <travel>-Description IS INITIAL.
      APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
      APPEND VALUE #( %tky = <travel>-%tky
                      %msg = NEW /lrn/cm_s4d437(
                               /lrn/cm_s4d437=>field_empty )
                      %element-Description = if_abap_behv=>mk-on )
        TO reported-travel.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

METHOD validateCustomer.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    IF <travel>-CustomerId IS INITIAL.
      APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
      APPEND VALUE #( %tky = <travel>-%tky
                      %msg = NEW /lrn/cm_s4d437(
                               /lrn/cm_s4d437=>field_empty )
                      %element-CustomerId = if_abap_behv=>mk-on )
        TO reported-travel.
    ELSE.
      SELECT SINGLE FROM /dmo/i_customer
        FIELDS CustomerID
        WHERE CustomerID = @<travel>-CustomerId
        INTO @DATA(dummy).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.
        APPEND VALUE #( %tky = <travel>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                 textid     = /lrn/cm_s4d437=>customer_not_exist
                                 customerid = <travel>-CustomerId )
                        %element-CustomerId = if_abap_behv=>mk-on )
          TO reported-travel.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

METHOD earlynumbering_create.
  DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( ).

  mapped-travel = CORRESPONDING #( entities ).

  LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).
    <mapping>-AgencyId = agencyid.
    <mapping>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid( ).
  ENDLOOP.
ENDMETHOD.


ENDCLASS.
