CLASS zcl_fg100_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070000'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00006001'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_FG100_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
  READ ENTITIES OF ZFG100_R_Travel
    ENTITY ZFG100_R_Travel
    ALL FIELDS WITH
    VALUE #( ( AgencyId = c_agency_id
               TravelId = c_travel_id ) )
    RESULT DATA(travels)
    FAILED DATA(failed).

  IF failed IS NOT INITIAL.
    out->write( `Error retrieving the travel` ).
  ELSE.
    MODIFY ENTITIES OF ZFG100_R_Travel
      ENTITY ZFG100_R_Travel
      UPDATE FIELDS ( Description )
      WITH VALUE #( ( AgencyId    = c_agency_id
                      TravelId    = c_travel_id
                      Description = `My new Description` ) )
      FAILED failed.

    IF failed IS INITIAL.
      COMMIT ENTITIES.
      out->write( `Description successfully updated` ).
    ELSE.
      ROLLBACK ENTITIES.
      out->write( `Error updating the description` ).
    ENDIF.
  ENDIF.
ENDMETHOD.

ENDCLASS.
