CLASS zapp_cl_demo_01_sched_via_f9 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZAPP_CL_DEMO_01_SCHED_VIA_F9 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA update TYPE TABLE FOR UPDATE ZAPPR_InventoryTP_01\\Inventory.
    DATA update_line TYPE STRUCTURE FOR UPDATE ZAPPR_InventoryTP_01\\Inventory .
    DATA job_template_name TYPE cl_apj_rt_api=>ty_template_name        VALUE 'ZAPP_DEMO_01_TEMPLATE'.
    DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA job_parameter TYPE cl_apj_rt_api=>ty_job_parameter_value.
    DATA range_value TYPE cl_apj_rt_api=>ty_value_range.
    DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
    DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.
*    DATA result_line LIKE LINE OF result.

    SELECT * FROM ZAPPR_InventoryTP_01       WHERE inventoryid = '1' OR inventoryid = '2'
                                             INTO TABLE @DATA(my_inventory).

    READ ENTITIES OF ZAPPR_InventoryTP_01
          ENTITY Inventory
            ALL FIELDS
            WITH VALUE #( ( uuid = my_inventory[ 1 ]-uuid )
                          ( uuid = my_inventory[ 2 ]-uuid )   )
            RESULT DATA(inventories).

    SORT inventories BY InventoryID.

    "Do check
    LOOP AT inventories INTO DATA(inventory).
      CLEAR job_parameter.
      CLEAR job_parameters.
      CLEAR range_value.
      out->write( |inventory id { inventory-InventoryID } quantity { inventory-Quantity } | ).

      " ls_start_info-start_immediately MUST NOT BE USED in on premise systems
      " since it performs a commit work which would cause a dump

*      GET TIME STAMP FIELD DATA(start_time_of_job).
*      job_start_info-timestamp = start_time_of_job.

      job_start_info-start_immediately = abap_true.

      job_parameter-name = zapp_cl_demo_01=>selection_name . "'INVENT'.
      range_value-sign = 'I'.
      range_value-option = 'EQ'.
      range_value-low = inventory-uuid.
      APPEND range_value TO job_parameter-t_value.
      APPEND job_parameter TO job_parameters.

      TRY.
          CASE inventory-InventoryID.
            WHEN '000001'.
              cl_apj_rt_api=>schedule_job(
                  EXPORTING
                  iv_job_template_name = job_template_name
                  iv_job_text = |Calculate inventory of { inventory-InventoryID }|
                  is_start_info = job_start_info
                  it_job_parameter_value = job_parameters
                  IMPORTING
                  ev_jobname  = job_name
                  ev_jobcount = job_count
                  ).
            WHEN '000002'.
              cl_apj_rt_api=>schedule_job(
                    EXPORTING
                    iv_job_template_name = job_template_name
                    iv_job_text = |Calculate inventory of { inventory-InventoryID }|
                    is_start_info = job_start_info
                    it_job_parameter_value = job_parameters
                    IMPORTING
                    ev_jobname  = job_name
                    ev_jobcount = job_count
                    ).


              CLEAR update.
              CLEAR update_line.

              update_line-%key = inventory-%key.
              update_line-JobCount =  job_count.
              update_line-jobname = job_name.
              APPEND update_line TO update.

              MODIFY ENTITIES OF ZAPPR_InventoryTP_01
                   ENTITY Inventory
                     UPDATE FIELDS (
                                    JobCount
                                    JobName
                                    ) WITH update
                  REPORTED DATA(reported)
                  FAILED DATA(failed)
                  MAPPED DATA(mapped).
              IF mapped IS NOT INITIAL.
                out->write( |success| ).
              ENDIF.

            WHEN OTHERS.
              out->write( |inventoryid { inventory-InventoryID } not found. No job scheduled.| ).
          ENDCASE.
        CATCH cx_apj_rt INTO DATA(job_scheduling_error).

          DATA(error_message) = job_scheduling_error->bapimsg-message.

          out->write( |error_message: { error_message }  | ).
        CATCH cx_root INTO DATA(root_exception).

          out->write( |root exception: { cl_message_helper=>get_latest_t100_exception( root_exception )->if_message~get_longtext( ) } | ).
      ENDTRY.

    ENDLOOP.



  ENDMETHOD.
ENDCLASS.
