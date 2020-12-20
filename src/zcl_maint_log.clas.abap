class ZCL_MAINT_LOG definition
  public
  final
  create private .

public section.

  methods GET_ABAP_DATETIME
    importing
      !UNIX_TIMESTAMP type ZUNXTS
    exporting
      !ABAP_DATE type D
      !ABAP_TIME type T
      !ABAP_TIMESTAMP type P .
  class-methods CLASS_CONSTRUCTOR .
  methods ADD_LOG_MSG
    importing
      !IS_LOGMSG type BAL_S_MSG optional
      !IS_LOGHEAD type BAL_S_LOG optional .
  class-methods GET_INSTANCE
    returning
      value(R_SINGLETON) type ref to ZCL_MAINT_LOG .
  PROTECTED SECTION.
private section.

  data HANDLE type BALLOGHNDL .
  class-data GO_SINGLETON type ref to ZCL_MAINT_LOG .
ENDCLASS.



CLASS ZCL_MAINT_LOG IMPLEMENTATION.


  METHOD add_log_msg.

    IF is_loghead IS SUPPLIED.
      CALL FUNCTION 'BAL_LOG_CREATE'
        EXPORTING
          i_s_log      = is_loghead
        IMPORTING
          e_log_handle = me->handle.
    ENDIF.

    IF is_logmsg IS SUPPLIED.
      CALL FUNCTION 'BAL_LOG_MSG_ADD'
        EXPORTING
          i_log_handle = me->handle
          i_s_msg      = is_logmsg.
    ENDIF.

    DATA lt_log_handle TYPE bal_t_logh.
    INSERT me->handle INTO TABLE lt_log_handle.
    CALL FUNCTION 'BAL_DB_SAVE'
      EXPORTING
        i_t_log_handle = lt_log_handle.

    COMMIT WORK.

  ENDMETHOD.


  METHOD class_constructor.

    go_singleton = NEW #( ).

  ENDMETHOD.


  METHOD get_abap_datetime.


    DATA:
      lv_timezone_sec(5)  TYPE p,
      lv_timezone_name(7) TYPE c.

    CALL 'C_GET_TIMEZONE' ID 'NAME' FIELD lv_timezone_name
                        ID 'SEC'  FIELD lv_timezone_sec.

    DATA: opcode         TYPE x,
          timestamp      TYPE i,
          timezone       TYPE i,
          tz             LIKE sy-zonlo,
          date           TYPE d,
          time           TYPE t,
          timestring(10),
          abapstamp(14),
          abaptstamp     TYPE timestamp.

    timestamp = unix_timestamp.
    " wandle den timestamp in ABAP Format um
    opcode = 3.
    CALL 'RstrDateConv'
      ID 'OPCODE' FIELD opcode
      ID 'TIMESTAMP' FIELD timestamp
      ID 'ABAPSTAMP' FIELD abapstamp.
    abaptstamp = abapstamp.

    " timezone Korrektur
    timezone = lv_timezone_sec / 3600.
    IF timezone > 0.
      WRITE timezone TO tz LEFT-JUSTIFIED.
      CONCATENATE 'UTC-' tz INTO tz.
    ELSEIF timezone < 0.
      timezone = timezone * -1.
      WRITE timezone TO tz LEFT-JUSTIFIED.
      CONCATENATE 'UTC+' tz INTO tz.
    ELSE.
      tz = 'UTC'.
    ENDIF.

    " finalize
    CONVERT TIME STAMP abaptstamp TIME ZONE tz INTO DATE date
      TIME time.
    IF sy-subrc <> 0.
      date = abapstamp(8).
      time = abapstamp+8.
    ENDIF.


    WRITE: time(2) TO timestring(2),
         ':' TO timestring+2(1),
         time+2(2) TO timestring+3(2),
         ':' TO timestring+5(1),
         time+4(2) TO timestring+6(2).

    "move timestring to A13_time.
    "move date to A13_DATE.

    abap_date = date.
    abap_time = time.
    abap_timestamp = abapstamp.




  ENDMETHOD.


  METHOD get_instance.
    r_singleton = go_singleton.
  ENDMETHOD.
ENDCLASS.
