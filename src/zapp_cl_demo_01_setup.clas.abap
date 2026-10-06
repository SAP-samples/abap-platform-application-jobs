CLASS zapp_cl_demo_01_setup DEFINITION
  PUBLIC
  INHERITING FROM cl_xco_cp_adt_simple_classrun
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA package_name_of_rap_generator TYPE sxco_package READ-ONLY.

    METHODS constructor RAISING zapp_cx_demo_01.
    METHODS create_application_log_entry RETURNING VALUE(r_application_log_object_name) TYPE string RAISING zapp_cx_demo_01. "if_bali_object_handler=>ty_object RAISING zapp_cx_demo_01.
    METHODS create_job_catalog_entry RETURNING VALUE(r_job_catalog_name) TYPE string RAISING zapp_cx_demo_01. "TYPE cl_apj_dt_create_content=>ty_catalog_name RAISING zapp_cx_demo_01.
    METHODS create_job_template_entry RETURNING VALUE(r_job_template_name) TYPE string RAISING zapp_cx_demo_01. " TYPE cl_apj_dt_create_content=>ty_template_name RAISING zapp_cx_demo_01.



  PROTECTED SECTION.
    METHODS: main REDEFINITION.
  PRIVATE SECTION.

    TYPES: BEGIN OF t_longtext,
             msgv1(50),
             msgv2(50),
             msgv3(50),
             msgv4(50),
           END OF t_longtext.

    DATA transport_request TYPE sxco_transport .
**    DATA xco_on_prem_library TYPE REF TO zdmo_cl_rap_xco_on_prem_lib  .
    DATA package_of_rap_generator TYPE REF TO if_xco_package.
*    DATA xco_lib TYPE REF TO zdmo_cl_rap_xco_lib.

    METHODS create_transport RETURNING VALUE(r_transport_request) TYPE sxco_transport RAISING zapp_cx_demo_01.

*data application_log_sub_obj1_name.
    DATA suffix TYPE string VALUE '01'.
    DATA application_log_sub_obj1_name TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_01_SUB'.
    DATA application_log_sub_obj1_text TYPE if_bali_object_handler=>ty_object_text VALUE 'Application Log' .
    DATA application_log_object_name TYPE if_bali_object_handler=>ty_object VALUE 'ZAPP_DEMO_01_LOG' .
    DATA job_catalog_name TYPE cl_apj_dt_create_content=>ty_catalog_name VALUE 'ZAPP_DEMO_01'  .
    DATA job_class_name TYPE cl_apj_dt_create_content=>ty_class_name VALUE 'ZAPP_CL_DEMO_01'  .
    DATA job_catalog_text TYPE cl_apj_dt_create_content=>ty_text VALUE 'Demo Application Jobs'  .
    DATA job_template_name TYPE cl_apj_dt_create_content=>ty_template_name VALUE 'ZAPP_DEMO_01_TEMPLATE'  .
    DATA job_template_text TYPE cl_apj_dt_create_content=>ty_text VALUE 'Demo Application Jobs'  .
    DATA application_log_object_text TYPE if_bali_object_handler=>ty_object_text VALUE 'Application Log of appl job demo' .

ENDCLASS.



CLASS ZAPP_CL_DEMO_01_SETUP IMPLEMENTATION.


  METHOD main.

    TRY.
        DATA(application_log_object_name) = create_application_log_entry(  ).
        out->write( |{ application_log_object_name } | ).  ##NO_TEXT
      CATCH zapp_cx_demo_01 INTO DATA(rap_generator_setup_exception).
        out->write( rap_generator_setup_exception->get_text(  ) ).
    ENDTRY.
    TRY.
        DATA(job_catalog_name) = create_job_catalog_entry(  ).
        out->write( |{ job_catalog_name } | ).  ##NO_TEXT
      CATCH zapp_cx_demo_01 INTO rap_generator_setup_exception.
        out->write( rap_generator_setup_exception->get_text(  ) ).
    ENDTRY.
    TRY.
        DATA(job_template_name) = create_job_template_entry(  ).
        out->write( |{ job_template_name } | ).  ##NO_TEXT
      CATCH zapp_cx_demo_01 INTO rap_generator_setup_exception.
        out->write( rap_generator_setup_exception->get_text(  ) ).
    ENDTRY.

  ENDMETHOD.


  METHOD create_transport.

    DATA longtext      TYPE t_longtext.
    DATA transport_request_description TYPE sxco_ar_short_description VALUE 'Create Application Job Catalog Entry and Job Template'.
    DATA package_name_to_check TYPE sxco_package  .

    TRY.
        package_name_to_check = package_of_rap_generator->name.

        WHILE xco_cp_abap_repository=>object->devc->for( package_name_to_check )->read( )-property-transport_layer->value = '$SPL'.
*         xco_lib->get_package( package_name_to_check )->read( )-property-transport_layer->value = '$SPL'.
          package_name_to_check = xco_cp_abap_repository=>object->devc->for( package_name_to_check )->read( )-property-super_package->name.
        ENDWHILE.
        DATA(transport_target) = xco_cp_abap_repository=>object->devc->for( package_name_to_check
          )->read( )-property-transport_layer->get_transport_target( ).
        DATA(transport_target_name) = transport_target->value.
        r_transport_request = xco_cp_cts=>transports->workbench( transport_target_name )->create_request( transport_request_description )->value.
      CATCH cx_root INTO DATA(exc_getting_transport_target).
        CLEAR r_transport_request.
        longtext = exc_getting_transport_target->get_text( ).
        RAISE EXCEPTION NEW zapp_cx_demo_01( textid     = zapp_cx_demo_01=>job_scheduling_error
                                                   error_value_1   = CONV #( longtext-msgv1 )
                                                   error_value_2 = CONV #( longtext-msgv2 )
                                                   previous   = exc_getting_transport_target
                                                   ).
    ENDTRY.
  ENDMETHOD.


  METHOD create_job_catalog_entry.

    DATA longtext      TYPE t_longtext.
    DATA(lo_dt) = cl_apj_dt_create_content=>get_instance( ).

    CLEAR r_job_catalog_name.

    " Create job catalog entry (corresponds to the former report incl. selection parameters)
    " Provided implementation class iv_class_name shall implement two interfaces:
    " - if_apj_dt_exec_object to provide the definition of all supported selection parameters of the job
    "   (corresponds to the former report selection parameters) and to provide the actual default values
    " - if_apj_rt_exec_object to implement the job execution

    TRY.
        lo_dt->create_job_cat_entry(
            iv_catalog_name       =  job_catalog_name
            iv_class_name         =  job_class_name
            iv_text               =  job_catalog_text
            iv_catalog_entry_type = cl_apj_dt_create_content=>class_based
            iv_transport_request  = transport_request
            iv_package            = package_of_rap_generator->name
        ).

        r_job_catalog_name = |Job catalog {  job_catalog_name } created succesfully|. "  job_catalog_name.

      CATCH cx_apj_dt_content INTO DATA(lx_apj_dt_content).

*        IF NOT ( lx_apj_dt_content->if_t100_message~t100key-msgno = cx_apj_dt_content=>cx_object_already_exists-msgno AND
*                 lx_apj_dt_content->if_t100_message~t100key-msgid = cx_apj_dt_content=>cx_object_already_exists-msgid AND
*                 lx_apj_dt_content->object = job_catalog_name ).
        longtext = lx_apj_dt_content->get_text( ).
        RAISE EXCEPTION NEW zapp_cx_demo_01( textid     = zapp_cx_demo_01=>job_scheduling_error
                                                   error_value_1   = CONV #( longtext-msgv1 )
                                                   error_value_2 = CONV #( longtext-msgv2 )
                                                   previous   = lx_apj_dt_content
                                                   ).
*        ELSE.
*          r_job_catalog_name = lx_apj_dt_content->get_text(  ).
*        ENDIF.
    ENDTRY.
  ENDMETHOD.


  METHOD create_job_template_entry.

    " Create job template (corresponds to the former system selection variant) which is mandatory
    " to select the job later on in the Fiori app to schedule the job
    DATA lt_parameters TYPE if_apj_dt_exec_object=>tt_templ_val.

    DATA longtext      TYPE t_longtext.

    CLEAR r_job_template_name.

    DATA(lo_dt) = cl_apj_dt_create_content=>get_instance( ).
    TRY.
        lo_dt->create_job_template_entry(
            iv_template_name     =  job_template_name
            iv_catalog_name      =  job_catalog_name
            iv_text              =  job_template_text
            it_parameters        = lt_parameters
            iv_transport_request = transport_request
            iv_package           = package_of_rap_generator->name
        ).

        r_job_template_name = |Job template {  job_template_name } generated successfully|." job_template_name.

      CATCH cx_apj_dt_content INTO DATA(lx_apj_dt_content).
*        IF  NOT ( lx_apj_dt_content->if_t100_message~t100key-msgno = cx_apj_dt_content=>cx_object_already_exists-msgno AND
*                 lx_apj_dt_content->if_t100_message~t100key-msgid = cx_apj_dt_content=>cx_object_already_exists-msgid AND
*                 lx_apj_dt_content->object = job_template_name ).
*          longtext = lx_apj_dt_content->get_text( ).
        RAISE EXCEPTION NEW zapp_cx_demo_01( textid     = zapp_cx_demo_01=>job_scheduling_error
                                                   error_value_1   = CONV #( longtext-msgv1 )
                                                   error_value_2 = CONV #( longtext-msgv2 )
                                                   previous   = lx_apj_dt_content
                                                   ).
*        ELSE.
*          r_job_template_name = lx_apj_dt_content->get_text(  ).
*        ENDIF.
    ENDTRY.
  ENDMETHOD.


  METHOD create_application_log_entry.
    DATA longtext      TYPE t_longtext.

    CLEAR  r_application_log_object_name.

*    IF xco_on_prem_library->on_premise_branch_is_used(  ).
*
*      "use xco sample application log object
*      r_application_log_object_name =  'Application log object XCO_DEMO will be used'.
*
*    ELSE.

    DATA(application_log_sub_objects) = VALUE if_bali_object_handler=>ty_tab_subobject(
                                            ( subobject =  application_log_sub_obj1_name
                                              subobject_text =  application_log_sub_obj1_text )
                                           "( subobject = '' subobject_text = '' )
                                            ).

    DATA(lo_log_object) = cl_bali_object_handler=>get_instance( ).

    TRY.
        lo_log_object->create_object( EXPORTING iv_object =  application_log_object_name
                                                iv_object_text =  application_log_object_text
                                                it_subobjects = application_log_sub_objects
                                                iv_package = package_of_rap_generator->name
                                                iv_transport_request = transport_request ).

        r_application_log_object_name =  application_log_object_name.

      CATCH cx_bali_objects INTO DATA(lx_bali_objects).

        IF  NOT ( lx_bali_objects->if_t100_message~t100key-msgno = '602' AND
                  lx_bali_objects->if_t100_message~t100key-msgid = 'BL' ).
          "MSGID   BL  SYMSGID C   20
          "MSGNO   602 SYMSGNO N   3
          longtext = lx_bali_objects->get_text( ).
          RAISE EXCEPTION NEW zapp_cx_demo_01( textid     = zapp_cx_demo_01=>job_scheduling_error
                                                     error_value_1   = CONV #( longtext-msgv1 )
                                                     error_value_2 = CONV #( longtext-msgv2 )
                                                     previous   = lx_bali_objects
                                                     ).

        ELSE.
          r_application_log_object_name = |Application log object {  application_log_object_name } already exists|.
        ENDIF.
    ENDTRY.

*    ENDIF.
  ENDMETHOD.


  METHOD constructor.

*    DATA me_name  TYPE sxco_ao_object_name  .
    super->constructor( ).

*    DATA suffix TYPE string VALUE '02'.
    application_log_sub_obj1_name = |ZAPP_DEMO_{ suffix }_SUB|."'ZAPP_DEMO_01_SUB'.
    application_log_sub_obj1_text = |Application Log { suffix }| .
    application_log_object_name = |ZAPP_DEMO_{ suffix }_LOG|. "'ZAPP_DEMO_01_LOG' .
    job_catalog_name = |ZAPP_DEMO_{ suffix }| . "'ZAPP_DEMO_01'  .
    job_class_name = |ZAPP_CL_DEMO_{ suffix }| ."'ZAPP_CL_DEMO_01'  .
    job_catalog_text = |Demo Application Jobs { suffix } |  .
    job_template_name = |ZAPP_DEMO_{ suffix }_TEMPLATE| ."'ZAPP_DEMO_01_TEMPLATE'  .
    job_template_text = |Demo Application Jobs { suffix } |  .  .
    application_log_object_text = |Application Log of appl job demo { suffix } | .

*    package_name_of_rap_generator = 'Z_DEMO_APPL_JOBS'.
    DATA exception_text TYPE string.

    TRY.


        DATA(me_name) = CONV sxco_ao_object_name( substring_after( val = cl_abap_classdescr=>get_class_name( me ) sub = '\CLASS=' ) ).
        DATA(my_class) = xco_cp_abap_repository=>object->clas->for( me_name ).
        package_of_rap_generator =  my_class->if_xco_ar_object~get_package(  ).
        DATA(me_package_name) =  package_of_rap_generator->name.
*        me_name = cl_abap_classdescr=>get_class_name( me ).
*        DATA(my_class) = xco_cp_abap_repository=>object->clas->for( me_name ).
*      package_of_rap_generator =  my_class->if_xco_ar_object~get_package(  ).
*        package_of_rap_generator = xco_cp_abap_repository=>object->devc->for( package_name_of_rap_generator ).
        IF package_of_rap_generator->read( )-property-record_object_changes = abap_true.
          transport_request = create_transport(  ).
        ELSE.
          CLEAR transport_request.
        ENDIF.
        transport_request = create_transport(  ).
      CATCH zapp_cx_demo_01 INTO DATA(setup_exception).
        exception_text = setup_exception->get_text(  ).
      CATCH cx_root INTO DATA(root_exception).
        exception_text = root_exception->get_text(  ).
        RAISE EXCEPTION NEW zapp_cx_demo_01( textid     = zapp_cx_demo_01=>root_cause_exception
                                                   error_value_1   = CONV #( root_exception->get_text(  ) )
*                                                     ERROR_VALUE_2 = CONV #( longtext-msgv2 )
*                                                     previous   = lx_bali_objects
                                                   ).
    ENDTRY.


  ENDMETHOD.
ENDCLASS.
