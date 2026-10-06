CLASS zapp_cl_demo_dev DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_apj_rt_run .

    "! <p class="shorttext synchronized" lang="en">Travel IDs</p>
    DATA travel_ids TYPE RANGE OF /dmo/travel_id.
    "! <p class="shorttext synchronized" lang="en">Agencies available</p>
    DATA agencies_available TYPE abap_bool VALUE abap_true.
    "! <p class="shorttext synchronized" lang="en">Agencies</p>
    DATA agency_ids TYPE RANGE OF /dmo/agency_id.
    "! <p class="shorttext synchronized" lang="en">Customers</p>
    DATA customer_ids TYPE RANGE OF /dmo/customer_id    .
    "! <p class="shorttext synchronized" lang="en">Status</p>
    DATA status TYPE /dmo/overall_status.

    METHODS constructor
      RAISING
        cx_bali_runtime.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS add_text_to_app_log
      IMPORTING
        i_text     TYPE cl_bali_free_text_setter=>ty_text
        i_severity TYPE if_bali_constants=>ty_severity DEFAULT if_bali_constants=>c_severity_information
      RAISING
        cx_bali_runtime.

    DATA application_log TYPE REF TO if_bali_log .
ENDCLASS.



CLASS zapp_cl_demo_dev IMPLEMENTATION.

  METHOD if_apj_rt_run~execute.

    DATA wait_time_in_seconds TYPE n VALUE 1.

    add_text_to_app_log( 'start job' ).
*    add_text_to_app_log( |parameter travel_ids| ).
*    LOOP AT travel_ids INTO DATA(travel_id).
*      add_text_to_app_log( |low { travel_id-low }| ).
*      add_text_to_app_log( |high { travel_id-high }| ).
*      add_text_to_app_log( |option { travel_id-option }| ).
*      add_text_to_app_log( |sign { travel_id-sign }| ).
*    ENDLOOP.
*
*    add_text_to_app_log( |parameter agency_ids| ).
*    LOOP AT agency_ids INTO DATA(agency_id).
*      add_text_to_app_log( |low { agency_id-low }| ).
*      add_text_to_app_log( |high { agency_id-high }| ).
*      add_text_to_app_log( |option { agency_id-option }| ).
*      add_text_to_app_log( |sign { agency_id-sign }| ).
*    ENDLOOP.
*
*    add_text_to_app_log( |customer_ids| ).
*    LOOP AT agency_ids INTO DATA(customer_id).
*      add_text_to_app_log( |low { customer_id-low }| ).
*      add_text_to_app_log( |high { customer_id-high }| ).
*      add_text_to_app_log( |option { customer_id-option }| ).
*      add_text_to_app_log( |sign { customer_id-sign }| ).
*    ENDLOOP.
*
*    add_text_to_app_log( |status| ).
*    add_text_to_app_log( |low { status }| ).

    SELECT * FROM /DMO/R_Travel_D
    WHERE TravelID IN  @travel_ids AND
          AgencyID IN @agency_ids  AND
          CustomerID IN @customer_ids AND
          OverallStatus = @status
    INTO TABLE @DATA(travels).
    DATA(count_travels) = lines( travels ).

    IF count_travels > 10.
      add_text_to_app_log( |more than 10 travels found| ).
      add_text_to_app_log(
        i_text     = 'job aborted'
        i_severity =  if_bali_constants=>c_severity_error
      ).
*      CATCH cx_bali_runtime..
      EXIT.
    ENDIF.

    IF travels IS INITIAL.
      add_text_to_app_log(
        i_text     = |no travel data found.|
        i_severity = if_bali_constants=>c_severity_warning
      ).
*      CATCH cx_bali_runtime..
    ENDIF.

    LOOP AT travels INTO DATA(travel).
      add_text_to_app_log( |wait up to { wait_time_in_seconds } seconds ...| ).
      WAIT UP TO wait_time_in_seconds SECONDS.
      add_text_to_app_log( |travel { travel-TravelID }.| ).
    ENDLOOP.

    add_text_to_app_log( 'job finished' ).

  ENDMETHOD.

  METHOD add_text_to_app_log.
    DATA(application_log_free_text) = cl_bali_free_text_setter=>create(
                                    severity = i_severity
                                    text = i_text ).
    application_log_free_text->set_detail_level( detail_level = '1' ).
    application_log->add_item( item = application_log_free_text ).
    cl_bali_log_db=>get_instance( )->save_log(
                                               log = application_log
                                               assign_to_current_appl_job = abap_true
                                               ).

  ENDMETHOD.

  METHOD constructor.
    application_log = cl_bali_log=>create_with_header(
                               header = cl_bali_header_setter=>create( object = 'ZAPP_DEMO_LOG_DEV'
                                                                       subobject = 'ZAPP_DEMO_LOG_DEV_SO'
                                                                       external_id = 'ZAPP_DEMO_LOG_DEV'
                                                                       ) ).
  ENDMETHOD.

ENDCLASS.
