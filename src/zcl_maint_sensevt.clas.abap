class ZCL_MAINT_SENSEVT definition
  public
  inheriting from ZCL_MAINT
  final
  create public .

public section.

  methods NOTIFY_CLIENTS .
  methods GET_ERR_PROBABILITY
    returning
      value(R_ERROR_PROBABILITY) type ZERR_PROBABILITY .
  methods PROCESS_INCOMING
    raising
      ZCX_MAINT .
  methods CONSTRUCTOR
    importing
      !IV_FUNCTION_PARAMETERS type /IWBEP/T_MGW_NAME_VALUE_PAIR
    raising
      ZCX_MAINT .
  methods VALIDATE_EVENT
    raising
      ZCX_MAINT .
  methods SAVE_EVENT
    raising
      ZCX_MAINT .
protected section.
private section.

  data G_ARBPL type ARBPL .
  data G_SENSVAL1 type ZSENSVAL .
  data G_SENSVAL2 type ZSENSVAL .
  data G_LAST_ERR_PROBABILITY type ZERR_PROBABILITY .
  data G_NOTIFICATION_THRESHOLD type ZERR_PROBABILITY value '0.6' ##NO_TEXT.

  methods CREATE_NOTIFICATION .
ENDCLASS.



CLASS ZCL_MAINT_SENSEVT IMPLEMENTATION.


  METHOD constructor.
    "create log
    DATA(ls_log_head) = VALUE bal_s_log( ).
    ls_log_head = VALUE #(
      object = |ZMAINT|
      subobject = |RECEIVESENSORDATA|
      alchdate = sy-datum
    ).
    super->constructor( ls_log_head ).

    TRY.
        "fill attributes
        me->g_arbpl  = iv_function_parameters[ name = |ID| ]-value.
        me->g_sensval1 = iv_function_parameters[ name = |VALUE1| ]-value.
        me->g_sensval2 = iv_function_parameters[ name = |VALUE2| ]-value.

        "log incoming ping
        DATA(log_msg) = VALUE bal_s_msg( ).
        log_msg = VALUE #(
          msgty = 'I'
          msgid = 'ZMC_MAINT'
          msgv1 = me->g_arbpl
          msgv2 = condense( val = |{ me->g_sensval1 }| del = ` ` )
          msgv3 = condense( val = |{ me->g_sensval2 }| del = ` ` )
          msgno = '000'
        ).
        me->log_message( is_message = log_msg ).

      CATCH cx_sy_itab_line_not_found.
        "log failed request params
        FREE log_msg.
        log_msg = VALUE #(
          msgty = 'E'
          msgid = 'ZMC_MAINT'
          msgno = '011'
          msgv1 = me->g_arbpl
          msgv2 = condense( val = |{ me->g_sensval1 }| del = ` ` )
          msgv3 = condense( val = |{ me->g_sensval2 }| del = ` ` )
        ).
        me->log_message( is_message = log_msg ).
        "cancel object instanciation
        RAISE EXCEPTION TYPE zcx_maint.
    ENDTRY.
  ENDMETHOD.


  METHOD create_notification.

    DATA:
      gs_notif_type         TYPE bapi2080-notif_type,
      gs_notifheader        TYPE bapi2080_nothdri,
      gs_notifheader_export TYPE bapi2080_nothdre,
      gt_notitem            TYPE TABLE OF bapi2080_notitemi, "WITH HEADER LINE,
      gs_notitem            TYPE bapi2080_notitemi, "WITH HEADER LINE,
      gs_notifcaus          TYPE bapi2080_notcausi, "WITH HEADER LINE,
      gt_notifcaus          TYPE TABLE OF bapi2080_notcausi, "WITH HEADER LINE,
      gs_longtexts          TYPE bapi2080_notfulltxti, "WITH HEADER LINE,
      gt_longtexts          TYPE TABLE OF bapi2080_notfulltxti, "WITH HEADER LINE,
      gt_return             TYPE TABLE OF bapiret2, "WITH HEADER LINE,
      gs_return             TYPE bapiret2, "WITH HEADER LINE,
      g_ind                 TYPE c,
      gs_return_notifheader TYPE bapi2080_nothdre.

    DATA(o_randomer) = cl_abap_random_int=>create( seed = CONV i( sy-uzeit )
                                          min  = 1
                                          max = 99 ).
    DATA(random_int) = o_randomer->get_next( ).

    DATA random_string TYPE string.
    random_string = random_int.


    DATA(arbpl) = 10000185.

* Meldungstyp
    gs_notif_type = 'M2'.

* Kopfdaten
    gs_notifheader = VALUE #(
      funct_loc	  = '1000-001-AA-01'
      short_text  = 'Generierte Meldung'
      priority    = '1'
      reportedby  = 'TGUBE'
      code_group  = '$$OSS001'
      coding      = '$$01'
      pm_wkctr = arbpl   "Arbpl
    ).




* Positionen
    gs_notitem-item_key = '0001'.
    gs_notitem-item_sort_no = '0001'.
    .
    gs_notitem-dl_codegrp = 'PM1'. " parte objeto
    gs_notitem-dl_code = '1'.


    gs_notitem-descript = | Ausfallwahrscheinlichkeit { g_last_err_probability }% |.
    INSERT gs_notitem INTO TABLE gt_notitem.



    CALL FUNCTION 'BAPI_ALM_NOTIF_CREATE'
      EXPORTING
        notif_type         = gs_notif_type
        notifheader        = gs_notifheader
      IMPORTING
        notifheader_export = gs_notifheader_export
      TABLES
        notitem            = gt_notitem
        notifcaus          = gt_notifcaus
        longtexts          = gt_longtexts
        return             = gt_return.

    CHECK g_ind IS INITIAL.


    CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
      EXPORTING
        number      = gs_notifheader_export-notif_no
      IMPORTING
        notifheader = gs_return_notifheader
      TABLES
        return      = gt_return.


    DATA(log_msg) = VALUE bal_s_msg( ).
    log_msg = VALUE #(
      msgty = 'I'
      msgid = 'ZMC_MAINT'
      msgv1 = gs_return_notifheader-notif_no
      msgno = '016'
    ).
    me->log_message( is_message = log_msg ).


    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      IMPORTING
        return = gs_return.

    DATA lv_rfc_name TYPE tfdir-funcname.
    DATA lv_destination TYPE rfcdest.
    DATA lv_chan TYPE amc_channel_id.

    lv_destination = 'IGSCLNT100'.
    lv_chan = 'SMART1'.
    CALL FUNCTION 'Z_MAINT_PUSHMSG' DESTINATION lv_destination
      EXPORTING
        i_type    = 'u'
        i_channel = lv_chan.


  ENDMETHOD.


  method GET_ERR_PROBABILITY.
    r_error_probability = g_last_err_probability.
  endmethod.


  METHOD notify_clients.


    DATA lv_rfc_name TYPE tfdir-funcname.
    DATA lv_destination TYPE rfcdest.
    DATA lv_chan TYPE amc_channel_id.

    lv_destination = 'IGSCLNT100'.
    lv_chan = g_arbpl.
    CALL FUNCTION 'Z_MAINT_PUSHMSG' DESTINATION lv_destination
      EXPORTING
        i_type            = 'v'
        i_channel         = lv_chan
        i_err_probability = g_last_err_probability
        i_value1          = g_sensval1
        i_value2          = g_sensval2.

  ENDMETHOD.


  METHOD process_incoming.
    TRY.
        me->validate_event( ).
        me->save_event( ).

        "calc new error Probability
        DATA(o_logreg) = NEW zcl_logreg(
            i_arbpl         = g_arbpl
          ).

        o_logreg->init(
            i_values = VALUE #( value1 = g_sensval1 value2 = g_sensval2 )
        ).
        DATA err TYPE p LENGTH 3 DECIMALS 2.
        err = o_logreg->calc_y_hat(  ).
        me->g_last_err_probability = err * 100.

        DATA(log_msg) = VALUE bal_s_msg( ).
          log_msg = VALUE #(
            msgty = 'I'
            msgid = 'ZMC_MAINT'
            msgv1 = me->g_last_err_probability
            msgno = '015'
          ).
          me->log_message( is_message = log_msg ).


        IF err > g_notification_threshold.
          create_notification( ).
        ENDIF.


      CATCH zcx_maint INTO DATA(lo_err).
        RAISE EXCEPTION TYPE zcx_maint EXPORTING previous = lo_err.
    ENDTRY.
  ENDMETHOD.


  METHOD save_event.
    TRY.

        "generate pingid and timestamp
        DATA(lv_pingid) = me->create_pingid( ).
        DATA(lv_timestamp) = me->create_timestamp( ).

        "fill structure for db
        DATA(ls_sensorlog) = VALUE zssensorlog( ).
        ls_sensorlog = VALUE #(
         id         = lv_pingid
         sensorid   = me->g_arbpl
         timestamp  = lv_timestamp
         value1      = me->g_sensval1
         value2      = me->g_sensval2
        ).
        "insert into db
        INSERT INTO ztsensorlog VALUES ls_sensorlog.
        IF sy-subrc <> 0.
          "log db fail
          DATA(log_msg) = VALUE bal_s_msg( ).
          log_msg = VALUE #(
            msgty = 'E'
            msgid = 'ZMC_MAINT'
            msgv1 = me->g_arbpl
            msgno = '005'
          ).
          me->log_message( is_message = log_msg ).
          RAISE EXCEPTION TYPE zcx_maint.
        ELSE.
          "log db success
          FREE log_msg.
          log_msg = VALUE #(
            msgty = 'I'
            msgid = 'ZMC_MAINT'
            msgv1 = me->g_arbpl
            msgno = '001'
          ).
          me->log_message( is_message = log_msg ).
        ENDIF.

      CATCH zcx_maint INTO DATA(lo_err).
        RAISE EXCEPTION TYPE zcx_maint EXPORTING previous = lo_err.
    ENDTRY.
  ENDMETHOD.


  METHOD validate_event.
    TRY.
        DATA(sensor) = me->get_sensor_byid( me->g_arbpl ).
      CATCH zcx_maint INTO DATA(lo_err).
        RAISE EXCEPTION TYPE zcx_maint EXPORTING previous = lo_err.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
