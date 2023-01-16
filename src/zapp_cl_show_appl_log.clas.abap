CLASS zapp_cl_show_appl_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS is_key_filter
      IMPORTING it_filter_cond          TYPE if_rap_query_filter=>tt_name_range_pairs
      RETURNING VALUE(rv_is_key_filter) TYPE abap_bool.

ENDCLASS.



CLASS zapp_cl_show_appl_log IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.


    DATA l_handle TYPE if_bali_log=>ty_handle.

    l_handle = 'vp3Ggk4J7ksZt3pexkwCdW'.
*    l_handle = 'eOy9ubWZ7jsZlQLeIxSCGm'.


    TRY.
        DATA(l_log) = cl_bali_log_db=>get_instance( )->load_log( handle = l_handle
                                                                 read_only_header = abap_true ).

        DATA(log_items) = l_log->get_all_items( )    .

        LOOP AT log_items INTO DATA(log_item).
          DATA(output) = |number { log_item-log_item_number } Category { log_item-item->category }  Severity { log_item-item->severity } log item number { log_item-item->log_item_number } detail level { log_item-item->detail_level } | .
          output = output &&  |time stamp { log_item-item->timestamp } msg_text: { log_item-item->get_message_text(  ) }| .
          out->write( output ).
        ENDLOOP.




      CATCH cx_bali_runtime INTO DATA(l_exception).
        out->write( l_exception->get_text( ) ).
    ENDTRY.


  ENDMETHOD.

  METHOD if_rap_query_provider~select.
    DATA business_data TYPE TABLE OF ZappI_appl_log .
    DATA business_data_line TYPE Zappi_appl_log .
    DATA(top)     = io_request->get_paging( )->get_page_size( ).
    DATA(skip)    = io_request->get_paging( )->get_offset( ).
    DATA(requested_fields)  = io_request->get_requested_elements( ).
    DATA(sort_order)    = io_request->get_sort_elements( ).
*    DATA xco_lib TYPE REF TO ZDMO_cl_rap_xco_lib.
    TRY.
        DATA(filter_condition_string) = io_request->get_filter( )->get_as_sql_string( ).
        DATA(filter_condition_ranges) = io_request->get_filter( )->get_as_ranges( ).

        IF is_key_filter( filter_condition_ranges ) = abap_true.
          DATA(is_single_read) = abap_true.
        ENDIF.


        READ TABLE filter_condition_ranges WITH KEY name = 'LOG_HANDLE'
        INTO DATA(filter_condition_log_handle).

        READ TABLE filter_condition_ranges WITH KEY name = 'LOG_ITEM_NUMBER'
        INTO DATA(filter_condition_log_item_num).

        IF filter_condition_log_handle IS NOT INITIAL.

          DATA l_handle TYPE if_bali_log=>ty_handle.
          l_handle = filter_condition_log_handle-range[ 1 ]-low.
          IF l_handle IS NOT INITIAL.
            TRY.
                DATA(l_log) = cl_bali_log_db=>get_instance( )->load_log( handle = l_handle
                                                                         read_only_header = abap_true ).

                DATA(log_items) = l_log->get_all_items( )    .

                LOOP AT log_items INTO DATA(log_item).

                  "fill key fields
                  business_data_line-Log_handle = l_handle.
                  business_data_line-Log_item_number = log_item-log_item_number.
                  "fill properties
                  business_data_line-category = log_item-item->category.
                  business_data_line-severity = log_item-item->severity.
                  business_data_line-detail_level = log_item-item->detail_level.
                  business_data_line-timestamp = log_item-item->timestamp.

                  business_data_line-message_text = log_item-item->get_message_text(  ).
                  APPEND business_data_line TO business_Data.
                ENDLOOP.




              CATCH cx_bali_runtime INTO DATA(l_exception).
                DATA(l_exception_t100_key) = cl_message_helper=>get_latest_t100_exception( l_exception )->t100key.
                RAISE EXCEPTION TYPE zapp_cx_demo_01
                  EXPORTING
                    textid   = VALUE scx_t100key( msgid = l_exception_t100_key-msgid
                                                  msgno = l_exception_t100_key-msgno
                                                  attr1 = l_exception_t100_key-attr1
                                                  attr2 = l_exception_t100_key-attr2
                                                  attr3 = l_exception_t100_key-attr3
                                                  attr4 = l_exception_t100_key-attr4 )
                    previous = l_exception.
            ENDTRY.
          ENDIF.


        ENDIF.

        DATA(total_number_of_records) = lines( business_data ).

        IF sort_order IS NOT INITIAL.

          DATA order_by_string TYPE string.

          CLEAR order_by_string.
          LOOP AT sort_order INTO DATA(ls_orderby_property).
            IF ls_orderby_property-descending = abap_true.
              CONCATENATE order_by_string ls_orderby_property-element_name 'DESCENDING' INTO order_by_string SEPARATED BY space.
            ELSE.
              CONCATENATE order_by_string ls_orderby_property-element_name 'ASCENDING' INTO order_by_string SEPARATED BY space.
            ENDIF.
          ENDLOOP.


        ENDIF.

*        SELECT * FROM @business_data AS data_source_fields
*  WHERE (filter_condition_string)
*  "order by (sort_order)
*  INTO TABLE @business_data
*  UP TO @top ROWS.

        IF top IS NOT INITIAL AND top > 0.
          DATA(max_index) = top + skip.
        ELSE.
          max_index = 0.
        ENDIF.

        SELECT  Log_item_number FROM @business_data AS data_source_fields
           WHERE (filter_condition_string)
           ORDER BY (order_by_string)
           INTO TABLE @DATA(log_item_number_table)
           UP TO @max_index ROWS
           .



        DATA s_log_item_number_table TYPE RANGE OF ZappI_appl_log-Log_item_number.
        DATA s_log_item_number_table_line LIKE LINE OF s_log_item_number_table.

        LOOP AT log_item_number_table INTO DATA(log_item_number_line).
          s_log_item_number_table_line-sign = 'I'.
          s_log_item_number_table_line-option = 'EQ'.
          s_log_item_number_table_line-low = log_item_number_line-Log_item_number.
          APPEND s_log_item_number_table_line TO s_log_item_number_table.
        ENDLOOP.

        DELETE business_data WHERE Log_item_number NOT IN s_log_item_number_table.

        IF skip IS NOT INITIAL.
          DELETE business_data TO skip.
        ENDIF.

*public static constant  c_severity_error  type if_bali_constants=>ty_severity value 'E'
*public static constant  c_severity_exit  type if_bali_constants=>ty_severity value 'X'
*public static constant  c_severity_information  type if_bali_constants=>ty_severity value 'I'
*public static constant  c_severity_status  type if_bali_constants=>ty_severity value 'S'
*public static constant  c_severity_termination  type if_bali_constants=>ty_severity value 'A'
*public static constant  c_severity_warning  type if_bali_constants=>ty_severity value 'W'

        LOOP AT business_data ASSIGNING FIELD-SYMBOL(<business_data>).
          CASE <business_data>-severity.
            WHEN 'S' OR 'I'. "Status, Information
              <business_data>-Criticality = 3.
            WHEN 'E' OR 'A'. "Error, Termination
              <business_data>-Criticality = 1.
            WHEN 'W' OR 'X'. "Warning, Exit
              <business_data>-Criticality = 2.
            WHEN OTHERS.
              <business_data>-Criticality = 0.
          ENDCASE.
        ENDLOOP.

        IF is_single_read = abap_false.

          io_response->set_total_number_of_records( CONV #( total_number_of_records ) ).
          io_response->set_data( business_data ).

        ELSE.

          io_response->set_total_number_of_records( CONV #( 1 ) ).
          io_response->set_data( business_data ).

        ENDIF.

      CATCH cx_root INTO DATA(exception).
        DATA(exception_message) = cl_message_helper=>get_latest_t100_exception( exception )->if_message~get_longtext( ).

        DATA(exception_t100_key) = cl_message_helper=>get_latest_t100_exception( exception )->t100key.

        RAISE EXCEPTION TYPE zapp_cx_demo_01
          EXPORTING
            textid   = VALUE scx_t100key( msgid = exception_t100_key-msgid
                                          msgno = exception_t100_key-msgno
                                          attr1 = exception_t100_key-attr1
                                          attr2 = exception_t100_key-attr2
                                          attr3 = exception_t100_key-attr3
                                          attr4 = exception_t100_key-attr4 )
            previous = exception.

*        ELSE.
*        ENDIF.
    ENDTRY.
  ENDMETHOD.

  METHOD is_key_filter.

    "check if the request is a single read

    READ TABLE it_filter_cond WITH KEY name = 'LOG_HANDLE' INTO DATA(filter_condition_log_handle).
    IF sy-subrc = 0 AND lines( filter_condition_log_handle-range ) = 1.
      READ TABLE filter_condition_log_handle-range INTO DATA(ls_id_option) INDEX 1.
      IF sy-subrc = 0 AND ls_id_option-sign = 'I' AND ls_id_option-option = 'EQ' AND ls_id_option-low IS NOT INITIAL.
        "read details for single record in list
        rv_is_key_filter = abap_true.
      ELSE.
        rv_is_key_filter = abap_false.
      ENDIF.
    ENDIF.

    CHECK rv_is_key_filter = abap_true.

    READ TABLE it_filter_cond WITH KEY name = 'LOG_ITEM_NUMBER' INTO DATA(filter_condition_item_num).
    IF sy-subrc = 0 AND lines( filter_condition_item_num-range ) = 1.
      READ TABLE filter_condition_item_num-range INTO DATA(ls_item_option) INDEX 1.
      IF sy-subrc = 0 AND ls_item_option-sign = 'I' AND ls_item_option-option = 'EQ' AND ls_item_option-low IS NOT INITIAL.
        "read details for single record in list
        rv_is_key_filter = abap_true.
      ELSE.
        rv_is_key_filter = abap_false.
      ENDIF.
    ENDIF.


  ENDMETHOD.

ENDCLASS.
