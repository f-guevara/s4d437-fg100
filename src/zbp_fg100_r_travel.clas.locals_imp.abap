CLASS lsc_zfg100_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zfg100_r_travel IMPLEMENTATION.

  METHOD save_modified.
  DATA(model) = NEW /lrn/cl_s4d437_tritem(
                  i_table_name = 'ZFG100_TRITEM' ).

  " Handle deletes
  LOOP AT delete-item ASSIGNING FIELD-SYMBOL(<item_d>).
    model->delete_item( i_uuid = <item_d>-itemuuid ).
  ENDLOOP.

  " Handle creates
  LOOP AT create-item ASSIGNING FIELD-SYMBOL(<item_c>).
    model->create_item(
      i_item = CORRESPONDING #( <item_c> MAPPING FROM ENTITY ) ).
  ENDLOOP.

  " Handle updates
  LOOP AT update-item ASSIGNING FIELD-SYMBOL(<item_u>).
    model->update_item(
      i_item  = CORRESPONDING #( <item_u> MAPPING FROM ENTITY )
      i_itemx = CORRESPONDING #( <item_u> MAPPING FROM ENTITY
                                 USING CONTROL ) ).
  ENDLOOP.

  IF create-travel IS NOT INITIAL.
  DATA event_in TYPE TABLE FOR EVENT ZFG100_R_Travel~TravelCreated.

  LOOP AT create-travel ASSIGNING FIELD-SYMBOL(<new_travel>).
    APPEND VALUE #( AgencyId = <new_travel>-AgencyId
                    TravelId = <new_travel>-TravelId
                    origin   = 'ZFG100_R_TRAVEL' )
      TO event_in.
  ENDLOOP.

  RAISE ENTITY EVENT ZFG100_R_Travel~TravelCreated
    FROM event_in.
ENDIF.
ENDMETHOD.

ENDCLASS.

CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightDate.
    METHODS determineTravelDates FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~determineTravelDates.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

 METHOD validateFlightDate.
  CONSTANTS c_area TYPE string VALUE `FLIGHTDATE`.

  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Item
    FIELDS ( AgencyId TravelId FlightDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(items).

  LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
    " Clear previous state messages
    APPEND VALUE #( %tky        = <item>-%tky
                    %state_area = c_area )
      TO reported-item.

    IF <item>-FlightDate IS INITIAL.
      APPEND VALUE #( %tky = <item>-%tky )
        TO failed-item.
      APPEND VALUE #( %tky                = <item>-%tky
                      %msg                = NEW /lrn/cm_s4d437(
                                              /lrn/cm_s4d437=>field_empty )
                      %element-FlightDate = if_abap_behv=>mk-on
                      %state_area         = c_area
                      %path-travel        = CORRESPONDING #( <item> ) )
        TO reported-item.

    ELSEIF <item>-FlightDate < cl_abap_context_info=>get_system_date( ).
      APPEND VALUE #( %tky = <item>-%tky )
        TO failed-item.
      APPEND VALUE #( %tky                = <item>-%tky
                      %msg                = NEW /lrn/cm_s4d437(
                                              /lrn/cm_s4d437=>flight_date_past )
                      %element-FlightDate = if_abap_behv=>mk-on
                      %state_area         = c_area
                      %path-travel        = CORRESPONDING #( <item> ) )
        TO reported-item.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

  METHOD determineTravelDates.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Item
    FIELDS ( FlightDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(items)
    BY \_Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels)
    LINK DATA(link).

  LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
    ASSIGN travels[ %tky =
      link[ source-%tky = <item>-%tky ]-target-%tky ]
      TO FIELD-SYMBOL(<travel>).

    " If flight date is after end date, extend end date
    IF <travel>-EndDate < <item>-FlightDate.
      <travel>-EndDate = <item>-FlightDate.
    ENDIF.

    " If flight date is before begin date and not in past, move begin date
    IF <item>-FlightDate > cl_abap_context_info=>get_system_date( )
    AND <item>-FlightDate < <travel>-BeginDate.
      <travel>-BeginDate = <item>-FlightDate.
    ENDIF.
  ENDLOOP.

  MODIFY ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( travels ).
ENDMETHOD.

ENDCLASS.

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
   METHODS determineStatus FOR DETERMINE ON MODIFY
     IMPORTING keys FOR Travel~determineStatus.
   METHODS earlynumbering_create FOR NUMBERING
     IMPORTING entities FOR CREATE Travel.
   METHODS get_instance_features FOR INSTANCE FEATURES
  IMPORTING keys REQUEST requested_features FOR Travel
  RESULT result.
   METHODS determineduration FOR DETERMINE ON SAVE
     IMPORTING keys FOR travel~determineduration.
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
  CONSTANTS c_area TYPE string VALUE `DESC`.

  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Description )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    " Clear previous state messages for this area
    APPEND VALUE #( %tky        = <travel>-%tky
                    %state_area = c_area )
      TO reported-travel.

    IF <travel>-Description IS INITIAL.
      APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
      APPEND VALUE #( %tky                 = <travel>-%tky
                      %msg                 = NEW /lrn/cm_s4d437(
                                               /lrn/cm_s4d437=>field_empty )
                      %element-Description = if_abap_behv=>mk-on
                      %state_area          = c_area )
        TO reported-travel.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

METHOD validateCustomer.
  CONSTANTS c_area TYPE string VALUE `CUST`.

  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( CustomerId )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    " Clear previous state messages for this area
    APPEND VALUE #( %tky        = <travel>-%tky
                    %state_area = c_area )
      TO reported-travel.

    IF <travel>-CustomerId IS INITIAL.
      APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
      APPEND VALUE #( %tky                  = <travel>-%tky
                      %msg                  = NEW /lrn/cm_s4d437(
                                                /lrn/cm_s4d437=>field_empty )
                      %element-CustomerId   = if_abap_behv=>mk-on
                      %state_area           = c_area )
        TO reported-travel.
    ELSE.
      SELECT SINGLE FROM /dmo/i_customer
        FIELDS CustomerID
        WHERE CustomerID = @<travel>-CustomerId
        INTO @DATA(dummy).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <travel>-%tky )
          TO failed-travel.
        APPEND VALUE #( %tky                = <travel>-%tky
                        %msg                = NEW /lrn/cm_s4d437(
                                               textid     = /lrn/cm_s4d437=>customer_not_exist
                                               customerid = <travel>-CustomerId )
                        %element-CustomerId = if_abap_behv=>mk-on
                        %state_area         = c_area )
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


  METHOD determineStatus.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  DELETE travels WHERE Status IS NOT INITIAL.
  CHECK travels IS NOT INITIAL.

  MODIFY ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Status )
    WITH VALUE #( FOR key IN travels ( %tky   = key-%tky
                                       Status = 'N' ) )
    REPORTED DATA(update_reported).

  reported = CORRESPONDING #( DEEP update_reported ).
ENDMETHOD.

METHOD get_instance_features.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Status BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    APPEND CORRESPONDING #( <travel> ) TO result
      ASSIGNING FIELD-SYMBOL(<result>).

    " Handle draft instances
    IF <travel>-%is_draft = if_abap_behv=>mk-on.
      READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
        ENTITY Travel
        FIELDS ( BeginDate EndDate )
        WITH VALUE #( ( %key     = <travel>-%key
                        %is_draft = if_abap_behv=>mk-off ) )
        RESULT DATA(travels_active).

      IF travels_active IS NOT INITIAL.
        " Edit draft: use dates from active instance
        <travel>-BeginDate = travels_active[ 1 ]-BeginDate.
        <travel>-EndDate   = travels_active[ 1 ]-EndDate.
      ELSE.
        " New draft: clear dates
        CLEAR <travel>-BeginDate.
        CLEAR <travel>-EndDate.
      ENDIF.
    ENDIF.

    " Operation control
    IF <travel>-Status = 'C' OR
    ( <travel>-EndDate IS NOT INITIAL AND
      <travel>-EndDate < cl_abap_context_info=>get_system_date( ) ).
      <result>-%update               = if_abap_behv=>fc-o-disabled.
      <result>-%action-cancel_travel = if_abap_behv=>fc-o-disabled.
    ELSE.
      <result>-%update               = if_abap_behv=>fc-o-enabled.
      <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.
    ENDIF.

    " Field control
    IF <travel>-BeginDate IS NOT INITIAL AND
       <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
      <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
      <result>-%field-BeginDate  = if_abap_behv=>fc-f-read_only.
    ELSE.
      <result>-%field-CustomerId = if_abap_behv=>fc-f-mandatory.
      <result>-%field-BeginDate  = if_abap_behv=>fc-f-mandatory.
    ENDIF.
  ENDLOOP.
ENDMETHOD.

  METHOD determineDuration.
  READ ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

  LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.
  ENDLOOP.

  MODIFY ENTITIES OF ZFG100_R_Travel IN LOCAL MODE
    ENTITY Travel
    UPDATE
    FIELDS ( Duration )
    WITH CORRESPONDING #( travels ).
ENDMETHOD.

ENDCLASS.
