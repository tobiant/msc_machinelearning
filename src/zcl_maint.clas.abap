class ZCL_MAINT definition
  public
  abstract
  create public .

public section.

  methods LOG_ERROR
    importing
      !IO_ERR type ref to CX_ROOT .
  methods LOG_MESSAGE
    importing
      !IS_MESSAGE type BAL_S_MSG .
  methods CONSTRUCTOR
    importing
      !IV_LOG_HEAD type BAL_S_LOG .
protected section.

  methods GET_SENSOR_BYID
    importing
      !IV_ARBPL type ARBPL
    returning
      value(R_SENSOR) type ZSSENSOR
    raising
      ZCX_MAINT .
  methods GET_MACHINE_BYID
    importing
      !IV_MACHINEID type ARBPL
    returning
      value(R_ARBPL) type CRHD .
  methods CREATE_PINGID
    returning
      value(R_PINGID) type ZPINGID
    raising
      ZCX_MAINT .
  methods CREATE_TIMESTAMP
    returning
      value(R_TIMESTAMP) type ZUNXTS
    raising
      ZCX_MAINT .
private section.

  data GO_MAINT_LOG type ref to ZCL_MAINT_LOG .
ENDCLASS.



CLASS ZCL_MAINT IMPLEMENTATION.


  METHOD constructor.

    me->go_maint_log = zcl_maint_log=>get_instance( ).
    me->go_maint_log->add_log_msg( is_loghead = iv_log_head ).

  ENDMETHOD.


  METHOD create_pingid.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr       = '01'
        object            = 'ZPINGID'
      IMPORTING
        number            = r_pingid
      EXCEPTIONS
        interval_overflow = 1
        OTHERS            = 2.
    CASE sy-subrc.
      WHEN 1.
        "log interval overflow
        DATA(log_msg) = VALUE bal_s_msg( ).
        log_msg = VALUE #(
          msgty = 'E'
          msgid = 'ZMC_MAINT'
          msgno = '009'
        ).
        me->go_maint_log->add_log_msg( is_logmsg = log_msg ).
        RAISE EXCEPTION TYPE zcx_maint.
      WHEN 2.
        log_msg = VALUE #(
          msgty = 'E'
          msgid = 'ZMC_MAINT'
          msgno = '013'
        ).
        me->go_maint_log->add_log_msg( is_logmsg = log_msg ).
        RAISE EXCEPTION TYPE zcx_maint.
    ENDCASE.
    log_msg = VALUE #(
        msgty = 'I'
        msgid = 'ZMC_MAINT'
        msgno = '014'
        msgv1 = r_pingid
      ).
    me->go_maint_log->add_log_msg( is_logmsg = log_msg ).
  ENDMETHOD.


  METHOD create_timestamp.

    DATA:
      lv_timezone_sec(5)  TYPE p,
      lv_timezone_name(7) TYPE c.

    CALL 'C_GET_TIMEZONE' ID 'NAME' FIELD lv_timezone_name
                          ID 'SEC'  FIELD lv_timezone_sec.

    DATA: BEGIN OF ls_calc,
            days(6)       TYPE p,            " for computing the date
            h_accu(6)     TYPE p,            " for computing hours
            m_accu(6)     TYPE p,            " for computing minutes
            s_accu(6)     TYPE p,            " for computing seconds
            h_c2(2)       TYPE c,
            m_c2(2)       TYPE c,
            s_c2(2)       TYPE c,
            hhmmss(6)     TYPE c,
            datebase_p(6) TYPE p,
            datebase_d    TYPE d,
          END OF ls_calc.

* Convert type D to days since 1900
    MOVE sy-datum TO ls_calc-days.

* Convert to days since 1970
    ls_calc-datebase_d = '19700101'.
    ls_calc-datebase_p = ls_calc-datebase_d.
    SUBTRACT ls_calc-datebase_p FROM ls_calc-days.
    IF ls_calc-days < 0.
      ls_calc-days = 0.
    ENDIF.

* Convert time to numbers
    MOVE sy-uzeit TO ls_calc-hhmmss.
    MOVE ls_calc-hhmmss(2)   TO ls_calc-h_c2.
    MOVE ls_calc-hhmmss+2(2) TO ls_calc-m_c2.
    MOVE ls_calc-hhmmss+4(2) TO ls_calc-s_c2.
    MOVE ls_calc-h_c2 TO ls_calc-h_accu.
    MOVE ls_calc-m_c2 TO ls_calc-m_accu.
    MOVE ls_calc-s_c2 TO ls_calc-s_accu.

* Combine all to seconds
    MULTIPLY ls_calc-days   BY 86400.
    MULTIPLY ls_calc-h_accu BY  3600.
    MULTIPLY ls_calc-m_accu BY    60.
    ADD ls_calc-h_accu TO ls_calc-days.
    ADD ls_calc-m_accu TO ls_calc-days.
    ADD ls_calc-s_accu TO ls_calc-days.
    MOVE ls_calc-days TO r_timestamp.

* Correct between GMT/UTC and local time.
    ADD lv_timezone_sec TO r_timestamp.

  ENDMETHOD.


  METHOD get_machine_byid.
    SELECT SINGLE * FROM crhd
      WHERE arbpl = @iv_machineid
      INTO @r_arbpl.
    IF sy-subrc <> 0.
      "log unknown machine
      DATA(log_msg) = VALUE bal_s_msg( ).
      log_msg = VALUE #(
        msgty = 'W'
        msgid = 'ZMC_MAINT'
        msgv1 = iv_machineid
        msgv2 = space
        msgv3 = space
        msgv4 = space
        msgno = '007'
      ).
      me->log_message( is_message = log_msg ).
    ENDIF.
  ENDMETHOD.


  METHOD get_sensor_byid.

    SELECT SINGLE * FROM ztsensors
      WHERE machine = @iv_arbpl
      INTO @r_sensor.
    IF sy-subrc <> 0.
      "log unknown machine
      DATA(log_msg) = VALUE bal_s_msg( ).
      log_msg = VALUE #(
        msgty = 'E'
        msgid = 'ZMC_MAINT'
        msgv1 = iv_arbpl
        msgno = '006'
      ).
      me->log_message( is_message = log_msg ).
      RAISE EXCEPTION TYPE zcx_maint.
    ELSE.
      "sensor validated
      log_msg = VALUE #(
        msgty = 'I'
        msgid = 'ZMC_MAINT'
        msgv1 = iv_arbpl
        msgv2 = r_sensor-type
        msgno = '012'
      ).
    ENDIF.

  ENDMETHOD.


METHOD log_error.

  "log error
  DATA(log_msg) = VALUE bal_s_msg( ).
  log_msg = VALUE #(
    msgno = '010'
    msgid = 'ZCM_MAINT'
    msgty = 'E'
*    msgid = io_err->textid
    msgv1 = io_err->get_text( )
    msgv2 = io_err->get_longtext( )
  ).

  me->GO_MAINT_LOG->add_log_msg( is_logmsg = log_msg ).

ENDMETHOD.


  METHOD log_message.

    me->go_maint_log->add_log_msg( is_logmsg = is_message ).

  ENDMETHOD.
ENDCLASS.
