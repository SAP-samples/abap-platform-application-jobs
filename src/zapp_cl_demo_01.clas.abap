CLASS zapp_cl_demo_01 DEFINITION
  PUBLIC

  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS : default_inventory_id          TYPE c LENGTH 1 VALUE '1',
                wait_time_in_seconds          TYPE i VALUE 5,
                selection_name                TYPE c LENGTH 8   VALUE 'INVENT',
                selection_description         TYPE c LENGTH 255 VALUE 'Inventory data',
                application_log_object_name   TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_ALOG_01',
                application_log_sub_obj1_name TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_ALOGS_01'.

    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES if_oo_adt_classrun.

    METHODS constructor.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS add_text_to_app_log_or_console
      IMPORTING
        i_text TYPE cl_bali_free_text_setter=>ty_text
      RAISING
        cx_bali_runtime.



    DATA out TYPE REF TO if_oo_adt_classrun_out.
    DATA application_log TYPE REF TO if_bali_log .


ENDCLASS.



CLASS ZAPP_CL_DEMO_01 IMPLEMENTATION.


  METHOD constructor.
    application_log = cl_bali_log=>create_with_header(
                           header = cl_bali_header_setter=>create( object = 'ZAPP_DEMO_01_LOG'
                                                                   subobject = 'ZAPP_DEMO_01_SUB'
                                                                   external_id = 'External ID' ) ).

  ENDMETHOD.


  METHOD if_apj_dt_exec_object~get_parameters.

    " Return the supported selection parameters here
    et_parameter_def = VALUE #(
      ( selname = selection_name
        kind = if_apj_dt_exec_object=>parameter
        datatype = 'C'
        length =  32
        param_text = selection_description
        changeable_ind = abap_true )
    ).

    " Return the default parameters values here

    SELECT SINGLE * FROM ZAPPR_InventoryTP_01
    WHERE inventoryid = @default_inventory_id
    INTO @DATA(my_inventory).

    et_parameter_val = VALUE #(
      ( selname = selection_name
        kind = if_apj_dt_exec_object=>parameter
        sign = 'I'
        option = 'EQ'
        low = my_inventory-uuid )
    ).

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    me->out = out.
    "test run of application job
    "since application job cannot be debugged we test it via F9

    SELECT SINGLE * FROM ZAPPR_InventoryTP_01
    WHERE inventoryid = @default_inventory_id
    INTO @DATA(my_inventory).

    DATA  et_parameters TYPE if_apj_rt_exec_object=>tt_templ_val  .

    et_parameters = VALUE #(
        ( selname = selection_name
          kind = if_apj_dt_exec_object=>parameter
          sign = 'I'
          option = 'EQ'
          low = my_inventory-uuid )
      ).

    TRY.

        if_apj_rt_exec_object~execute( it_parameters = et_parameters ).
        out->write( |Finished| ).

      CATCH cx_root INTO DATA(job_scheduling_exception).
        out->write( |Exception has occured: { job_scheduling_exception->get_text(  ) }| ).
    ENDTRY.

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.


    DATA messages TYPE string_table.

    DATA update TYPE TABLE FOR UPDATE ZAPPR_InventoryTP_01\\Inventory.
    DATA update_line TYPE STRUCTURE FOR UPDATE ZAPPR_InventoryTP_01\\Inventory .
    DATA reported TYPE RESPONSE FOR REPORTED EARLY ZAPPR_InventoryTP_01  .
    DATA failed TYPE RESPONSE FOR FAILED EARLY ZAPPR_InventoryTP_01  .
    DATA mapped TYPE RESPONSE FOR MAPPED EARLY ZAPPR_InventoryTP_01  .
    DATA reported_late TYPE RESPONSE FOR REPORTED LATE ZAPPR_InventoryTP_01  .


    TRY.

        add_text_to_app_log_or_console( 'start job' ).

        IF it_parameters IS INITIAL.
          add_text_to_app_log_or_console( |it_parameters is initial | ).
        ENDIF.

        " Getting the actual parameter values
        LOOP AT it_parameters INTO DATA(ls_parameter).

          DATA(sel_string) = |ls_paramter-selname { ls_parameter-selname }  low { ls_parameter-low } |.
          sel_string = sel_string && |high { ls_parameter-high }  kind { ls_parameter-kind } |.
          sel_string = sel_string && |option { ls_parameter-option }  sign { ls_parameter-sign } |.
          add_text_to_app_log_or_console( CONV #( sel_string ) ).

          CASE ls_parameter-selname.
            WHEN selection_name .

              add_text_to_app_log_or_console( |selection_name { selection_name } uuid { ls_parameter-low }|  ).

              IF ls_parameter-low IS NOT INITIAL.

                "Get current quantity
                SELECT SINGLE * FROM ZAPPR_InventoryTP_01
                WHERE uuid = @ls_parameter-low
                INTO @DATA(current_quantity).

                IF sy-subrc = 0.

                  add_text_to_app_log_or_console( |currenty quantity before { current_quantity-quantity }| ).

                  current_quantity-quantity += 10.

                  add_text_to_app_log_or_console( |currenty quantity after { current_quantity-quantity }| ).

                  DATA(log_handle) = application_log->get_handle( ).

                  add_text_to_app_log_or_console( |loghandle { log_handle }| ).


                  update_line-uuid = ls_parameter-low.
                  update_line-Quantity = current_quantity-quantity.
                  update_line-QuantityUnit = current_quantity-QuantityUnit.
                  update_line-LogHandle = log_handle.

                  APPEND update_line TO update.
                ELSE.
                  add_text_to_app_log_or_console( |uuid { ls_parameter-low } not found| ).
                ENDIF.
              ENDIF.
          ENDCASE.
        ENDLOOP.

        IF update IS NOT INITIAL.
          MODIFY ENTITIES OF ZAPPR_InventoryTP_01
               ENTITY Inventory
                 UPDATE FIELDS (
                                LogHandle
                                Quantity
                                QuantityUnit
                                uuid
                                ) WITH update
              REPORTED DATA(update_reported)
              FAILED DATA(update_failed)
              .
        ENDIF.

        add_text_to_app_log_or_console( |wait up to { wait_time_in_seconds } seconds ...| ).
*        WAIT UP TO wait_time_in_seconds SECONDS.

        IF update IS NOT INITIAL AND update_failed IS INITIAL.

          COMMIT ENTITIES RESPONSE OF ZAPPR_InventoryTP_01
                          REPORTED DATA(commit_reported)
                          FAILED DATA(commit_failed).

          "commit_failed and commit_reported are of type late
          "failed and reported are of type early
          reported = CORRESPONDING #( DEEP commit_reported ).
          failed = CORRESPONDING #( DEEP commit_failed ).

        ELSE.
          reported = CORRESPONDING #( update_reported ).
          failed = CORRESPONDING #( update_failed ).
        ENDIF.

        IF failed IS INITIAL.

          add_text_to_app_log_or_console( |failed is initial| ).

          LOOP AT update INTO DATA(update_inventory).
            SELECT SINGLE * FROM ZAPPR_InventoryTP_01
                        WHERE uuid = @update_inventory-uuid
                        INTO @DATA(updated_inventory).
            add_text_to_app_log_or_console( |changed inventory { updated_inventory-InventoryID } successfuylly. New value { updated_inventory-quantity }| ).
          ENDLOOP.

        ELSE.

          LOOP AT failed-inventory INTO DATA(failed_inventory).
            " raise an exception with failed and / or reported
            add_text_to_app_log_or_console( |failed to add new quantity { failed_inventory-uuid }| ).
            add_text_to_app_log_or_console( |reason { failed_inventory-%fail-cause }| ).

          ENDLOOP.

        ENDIF.

        IF reported IS INITIAL.
          add_text_to_app_log_or_console( |reported is initial| ).
        ELSE.
          add_text_to_app_log_or_console( |reported is not initial| ).
        ENDIF.

        add_text_to_app_log_or_console( |wait up to { wait_time_in_seconds } seconds ...| ).
*        WAIT UP TO wait_time_in_seconds SECONDS.

        add_text_to_app_log_or_console( |job finished| ).

      CATCH cx_bali_runtime INTO DATA(application_log_exception).

        DATA(bali_log_exception) = application_log_exception->get_text(  ).

        RAISE EXCEPTION TYPE cx_apj_rt_content
          EXPORTING
            previous = application_log_exception.

    ENDTRY.

  ENDMETHOD.


  METHOD add_text_to_app_log_or_console.
    IF sy-batch = abap_true.
      DATA(application_log_free_text) = cl_bali_free_text_setter=>create(
                                severity = if_bali_constants=>c_severity_status
                                text = i_text ).
      application_log_free_text->set_detail_level( detail_level = '1' ).
      application_log->add_item( item = application_log_free_text ).
      cl_bali_log_db=>get_instance( )->save_log(
                                                 log = application_log
*                                                 assign_to_current_appl_job = abap_true
                                                 ).
    ELSE.
      out->write( |sy-batch = abap_false | ).
      out->write( i_text ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
