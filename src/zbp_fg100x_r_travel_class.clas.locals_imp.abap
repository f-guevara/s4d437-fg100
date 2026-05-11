CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZvalidateClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ZZvalidateClass.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD ZZvalidateClass.
    " Read the item data
    READ ENTITIES OF ZFG100_R_TRAVEL IN LOCAL MODE
      ENTITY Item
        FIELDS ( ZZClassZIT )
        WITH CORRESPONDING #( keys )
        RESULT DATA(items).

    LOOP AT items INTO DATA(item).
      " Ignore if the extension field is empty
      IF item-ZZClassZIT IS INITIAL.
        CONTINUE.
      ENDIF.

      " Check if the entered class exists in the standard value help view
      SELECT SINGLE @abap_true
        FROM /lrn/437_i_classstdvh
        WHERE ClassID = @item-ZZClassZIT
        INTO @DATA(exists).

      " If it does not exist, report an error
      IF exists = abap_false.
        APPEND VALUE #( %tky = item-%tky ) TO failed-item.

        APPEND VALUE #( %tky = item-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Booking Class { item-ZZClassZIT } does not exist.|
                               )
                        %element-ZZClassZIT = if_abap_behv=>mk-on
                       ) TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZFG100_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZFG100_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.
    " Combine items that were newly created and items that were updated.
    " In both cases, we might need to save the booking class extension field.
    DATA(lt_items_to_process) = update-item.
    APPEND LINES OF create-item TO lt_items_to_process.

    " Loop through the relevant items
    LOOP AT lt_items_to_process ASSIGNING FIELD-SYMBOL(<ls_item>)
       " CRITICAL CHECK: Only process if the extension field was actually
       " provided or changed by the UI.
       " *** IF YOU GET A SYNTAX ERROR HERE, change ZZClassZFG100 to your actual extension field name ***
       WHERE %control-ZZClassZIT = if_abap_behv=>mk-on.

      " IMPORTANT: Use UPDATE, not INSERT.
      " The standard behavior has already inserted the main item record into the DB.
      " We use SET to only update our specific extension column on that existing record.
      " *** IF YOU GET A SYNTAX ERROR HERE, change zzclasszfg100 (database column name) to match your DB table ***
      UPDATE zfg100_tritem
        SET zzclasszit = @<ls_item>-ZZClassZIT
        WHERE item_uuid = @<ls_item>-ItemUuid.

    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
