CLASS lhc_inventory DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
*      get_global_authorizations FOR GLOBAL AUTHORIZATION
*        IMPORTING
*        REQUEST requested_authorizations FOR Inventory
*        RESULT result,
      calculateinventoryid FOR DETERMINE ON SAVE
        IMPORTING
          keys FOR  Inventory~CalculateInventoryID ,
      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR Inventory RESULT result.

    METHODS calculateInventory FOR MODIFY
      IMPORTING keys FOR ACTION Inventory~calculateInventory RESULT result.
ENDCLASS.

CLASS lhc_inventory IMPLEMENTATION.
*  METHOD get_global_authorizations.
*  ENDMETHOD.
  METHOD calculateinventoryid.
    "Ensure idempotence
    READ ENTITIES OF zappr_inventorytp_01 IN LOCAL MODE
      ENTITY Inventory
        FIELDS ( InventoryID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(inventories).

    DELETE inventories WHERE InventoryID IS NOT INITIAL.
    CHECK inventories IS NOT INITIAL.

    "Get max inventory_id
    SELECT SINGLE FROM zapp_inven_01 FIELDS MAX( inventory_id ) INTO @DATA(max_inventory).

    "update involved instances
    MODIFY ENTITIES OF zappr_inventorytp_01 IN LOCAL MODE
      ENTITY Inventory
        UPDATE FIELDS ( InventoryID )
        WITH VALUE #( FOR inventory IN inventories INDEX INTO i (
                           %tky      = inventory-%tky
                           inventoryID  = max_inventory + i ) )
    REPORTED DATA(lt_reported).

    "fill reported
    reported = CORRESPONDING #( DEEP lt_reported ).
  ENDMETHOD.
  METHOD get_instance_features.

    DATA result_line TYPE STRUCTURE FOR INSTANCE FEATURES RESULT zappr_inventorytp_01\\inventory.

    READ ENTITIES OF ZAPPR_InventoryTP_01 IN LOCAL MODE
      ENTITY Inventory
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(inventories).

    LOOP AT inventories INTO DATA(inventory).

      result_line-%tky = inventory-%tky.

      TRY.
          cl_apj_rt_api=>get_job_status(
            EXPORTING
              iv_jobname  = inventory-JobName
              iv_jobcount = inventory-JobCount
            IMPORTING
              ev_job_status = DATA(JobStatus)
              ev_job_status_text = DATA(jobstatustext)
            ).
        CATCH cx_apj_rt INTO DATA(job_status_exception).
          IF job_status_exception->if_t100_message~t100key-msgid = 'APJ_RT'  AND
             job_status_exception->if_t100_message~t100key-msgno = '003'  .
            jobstatus = ' '.
          ENDIF.
      ENDTRY.

      IF inventory-%is_draft = if_abap_behv=>mk-on.
        result_line-%action-calculateInventory = if_abap_behv=>fc-o-disabled.
      ELSE.
        CASE jobstatus.
          WHEN ' '.
            result_line-%action-calculateInventory = if_abap_behv=>fc-o-enabled.
          WHEN 'F'. "Finished
            result_line-%action-calculateInventory = if_abap_behv=>fc-o-enabled.
          WHEN 'A'. "Aborted
            result_line-%action-calculateInventory = if_abap_behv=>fc-o-enabled.
          WHEN 'R'. "Running
            result_line-%action-calculateInventory = if_abap_behv=>fc-o-disabled.
          WHEN OTHERS.
            result_line-%action-calculateInventory = if_abap_behv=>fc-o-disabled.
        ENDCASE.
      ENDIF.
      APPEND result_line TO result.
    ENDLOOP.


  ENDMETHOD.

  METHOD calculateInventory.

    DATA update TYPE TABLE FOR UPDATE ZAPPR_InventoryTP_01\\Inventory.
    DATA update_line TYPE STRUCTURE FOR UPDATE ZAPPR_InventoryTP_01\\Inventory .
    DATA result_line LIKE LINE OF result.

    READ ENTITIES OF ZAPPR_InventoryTP_01 IN LOCAL MODE
          ENTITY Inventory
            ALL FIELDS
            WITH CORRESPONDING #( keys )
            RESULT DATA(inventories).

    LOOP AT inventories INTO DATA(inventory).
      CLEAR update_line.
      update_line-%key = inventory-%key.
      update_line-ScheduleJob =  abap_true.
      APPEND update_line TO update.
    ENDLOOP.

    MODIFY ENTITIES OF ZAPPR_InventoryTP_01 IN LOCAL MODE
         ENTITY Inventory
           UPDATE FIELDS (
                          ScheduleJob
                          ) WITH update
        REPORTED reported
        FAILED failed
        MAPPED mapped.

    IF failed IS INITIAL.
      "Read changed data for action result
      READ ENTITIES OF ZAPPR_InventoryTP_01 IN LOCAL MODE
        ENTITY Inventory
          ALL FIELDS WITH
          CORRESPONDING #( keys )
        RESULT inventories.
*      result = VALUE #( FOR inventory_2 IN inventories ( %tky   = inventory_2-%tky
*                                                         %param = inventory_2 ) ).
    ENDIF.

    LOOP AT inventories INTO inventory.

      result_line-%tky = inventory-%tky.
      result_line-%param = inventory.
      APPEND result_line TO result.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_inventory DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_inventory IMPLEMENTATION.

  METHOD save_modified.

    DATA job_template_name TYPE cl_apj_rt_api=>ty_template_name VALUE 'ZAPP_DEMO_01_TEMPLATE'.

    DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA job_parameter TYPE cl_apj_rt_api=>ty_job_parameter_value.
    DATA range_value TYPE cl_apj_rt_api=>ty_value_range.
    DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
    DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.

    LOOP AT update-inventory INTO DATA(update_inventory)
            WHERE ScheduleJob = abap_true AND
                  %control-ScheduleJob = if_abap_behv=>mk-on.

      TRY.

          " job_start_info-start_immediately MUST NOT BE USED in on premise systems
          " since it performs a commit work which would cause a dump

          GET TIME STAMP FIELD DATA(start_time_of_job).
*          job_start_info-timestamp = start_time_of_job.
          job_start_info-start_immediately = abap_true.

          job_parameter-name = zapp_cl_demo_01=>selection_name . "'INVENT'.
          range_value-sign = 'I'.
          range_value-option = 'EQ'.
          range_value-low = update_inventory-uuid.
          APPEND range_value TO job_parameter-t_value.
          APPEND job_parameter TO job_parameters.


          cl_apj_rt_api=>schedule_job(
              EXPORTING
              iv_job_template_name = job_template_name
              iv_job_text = |Calculate inventory of { update_inventory-ProductID }|
              is_start_info = job_start_info
              it_job_parameter_value = job_parameters
              IMPORTING
              ev_jobname  = job_name
              ev_jobcount = job_count
              ).

          UPDATE zapp_inven_01 SET job_count = @job_count , job_name = @job_name WHERE uuid = @update_inventory-uuid.



        CATCH cx_apj_rt INTO DATA(job_scheduling_error).

          "reported-<entity name>
          APPEND VALUE #(  uuid = update_inventory-uuid

                           %msg = new_message(
                                               id = 'ZAPP_CM_DEMO_01'
                                               number   = 000
                                               severity = if_abap_behv_message=>severity-error
                                               v1       = |Job Sched Error: { job_scheduling_error->get_text(  ) }|
                                               )
                          )
            TO reported-inventory.
          DATA(error_message) = job_scheduling_error->get_text( ).

        CATCH cx_root INTO DATA(root_exception).

          "reported-<entity name>
          APPEND VALUE #(  uuid = update_inventory-uuid
                           %msg = new_message(
                           id       = 'ZAPP_CM_DEMO_01'
                           number   = 000
                           severity = if_abap_behv_message=>severity-error
                           v1       = |Root Exc: { root_exception->get_text(  ) }|
                           )
                         )
            TO reported-inventory.

          DATA(error_message_root) = root_exception->get_text( ).
      ENDTRY.


    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
