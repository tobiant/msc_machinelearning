*&---------------------------------------------------------------------*
*& Report ZR_CREATE_SENSOR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_create_sensor.

PARAMETERS: p_type AS LISTBOX VISIBLE LENGTH 12 TYPE zsenstyp OBLIGATORY,
            p_unit AS LISTBOX VISIBLE LENGTH 12 TYPE zsensunit OBLIGATORY,
            p_mach LIKE crhd-arbpl OBLIGATORY.



START-OF-SELECTION.

  DATA: lv_sensid TYPE zsensid,
        ls_sensor TYPE zssensor.

  DATA(lv_begintime) = sy-uzeit.

  "create log
  DATA(s_log_head) = VALUE bal_s_log( ).
  s_log_head = VALUE #(
  object = |ZMAINT|
  subobject = |CREATESENSOR|
  alchdate = sy-datum
).

  DATA(lo_log) = zcl_maint_log=>get_instance( ).
  lo_log->add_log_msg( is_loghead = s_log_head ).


  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZSENSID'
    IMPORTING
      number      = lv_sensid.

  DATA(log_msg) = VALUE bal_s_msg( ).
  log_msg = VALUE #(
    msgty = 'I'
    msgid = 'ZMC_MAINT'
    msgv1 = lv_sensid
    msgv2 = p_mach
    msgv3 = space
    msgv4 = space
    msgno = '002'
  ).

  lo_log->add_log_msg( is_logmsg = log_msg ).


  SELECT SINGLE arbpl FROM crhd
    WHERE werks = @( |1100| )
    AND arbpl = @p_mach
    INTO @DATA(lv_arbpl).

  IF sy-subrc <> 0.
    log_msg = VALUE #(
      msgty = 'E'
      msgid = 'ZMC_MAINT'
      msgv1 = lv_sensid
      msgv2 = p_mach
      msgv3 = space
      msgv4 = space
      msgno = '004'
    ).
    lo_log->add_log_msg( is_logmsg = log_msg ).

  ELSE.

    ls_sensor = VALUE #(
      id      = lv_sensid
      type    = p_type
      unit    = p_unit
      machine = p_mach
    ).

    INSERT INTO ztsensors VALUES ls_sensor.
    IF sy-subrc <> 0.
      log_msg = VALUE #(
      msgty = 'E'
      msgid = 'ZMC_MAINT'
      msgv1 = lv_sensid
      msgv2 = p_mach
      msgv3 = space
      msgv4 = space
      msgno = '004'
      ).
      lo_log->add_log_msg( is_logmsg = log_msg ).

    ELSE.
      log_msg = VALUE #(
      msgty = 'I'
      msgid = 'ZMC_MAINT'
      msgv1 = lv_sensid
      msgv2 = p_mach
      msgv3 = space
      msgv4 = space
      msgno = '003'
      ).
      lo_log->add_log_msg( is_logmsg = log_msg ).

    ENDIF.
  ENDIF.



  CALL FUNCTION 'APPL_LOG_DISPLAY'
    EXPORTING
      object                    = 'ZMAINT'
      subobject                 = 'CREATESENSOR'
      time_from                 = lv_begintime
      suppress_selection_dialog = 'X'
    EXCEPTIONS
      no_authority              = 1
      OTHERS                    = 2.
