"! <p class="shorttext synchronized" lang="en">Fill DB Table with data</p>
"! Use a copy of this class to reset your data
"! Fill the constant c_travel_table with the name of your DB tables
"! And execute as console app (F9)
CLASS zcl_fg100_travel_fill DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS zfg100_travel  TYPE tabname VALUE 'ZFG100_TRAVEL'.

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCL_FG100_TRAVEL_FILL IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    TRY.
        DATA(dbtable) = NEW lcl_dbtable( zfg100_travel ).

        IF dbtable->check_compatible( ) <> abap_true.

        ENDIF.

        IF dbtable->is_empty( ) <> abap_true.
          dbtable->delete_data( ).
        ENDIF.

        dbtable->generate_data( ).

      CATCH cx_abap_not_a_table.
        out->write( |{ zfg100_travel } is not the name of a database table| ).
      CATCH cx_abap_not_in_package.
        out->write( |{ zfg100_travel } is not a table in software component ZLOCAL| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
