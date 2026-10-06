CLASS zapp_cl_schedule_demo_dev DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zapp_cl_schedule_demo_dev IMPLEMENTATION.



  METHOD if_oo_adt_classrun~main.

    DATA job_start_info TYPE cl_apj_rt_api=>ty_start_info.
    DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA job_parameter TYPE cl_apj_rt_api=>ty_job_parameter_value.
    DATA range_value TYPE cl_apj_rt_api=>ty_value_range.
    DATA job_name TYPE cl_apj_rt_api=>ty_jobname.
    DATA job_count TYPE cl_apj_rt_api=>ty_jobcount.

    " job_start_info-start_immediately MUST NOT BE USED in on premise systems
    " since it performs a commit work which would cause a dump

    GET TIME STAMP FIELD DATA(start_time_of_job).
*          job_start_info-timestamp = start_time_of_job.
    job_start_info-start_immediately = abap_true.

    job_parameter-name = 'STATUS'.

    range_value-sign = 'I'.
    range_value-option = 'EQ'.
    range_value-low = 'X'.
    APPEND range_value TO job_parameter-t_value.
    APPEND job_parameter TO job_parameters.

    DATA jobuser TYPE syuname.


    jobuser = 'CB9980000602'.
*      jobuser = sy-uname.

    SELECT SINGLE * FROM I_BusinessUserVH WHERE UserID = @jobuser
                        INTO @DATA(business_user).
    cl_apj_rt_api=>schedule_job(
        EXPORTING
        iv_job_template_name = 'Z_DEMO_APPL_JOB_TEMPL_DEV'
        iv_job_text = |use user { business_user-FirstName }, {  business_user-lastName }|
        is_start_info = job_start_info
        it_job_parameter_value = job_parameters
        iv_username = jobuser
        IMPORTING
        ev_jobname  = job_name
        ev_jobcount = job_count
        ).

    out->write( |job name { job_name } job count { job_count }| ).

  ENDMETHOD.

ENDCLASS.
