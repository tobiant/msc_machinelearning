class ZCL_Z_MAINTENANCE_DPC_EXT definition
  public
  inheriting from ZCL_Z_MAINTENANCE_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION
    redefinition .
protected section.

  methods ORDERHEADSET_GET_ENTITY
    redefinition .
  methods ORDERHEADSET_GET_ENTITYSET
    redefinition .
  methods ORDERPOSSET_GET_ENTITYSET
    redefinition .
  methods SENSOR1SET_GET_ENTITYSET
    redefinition .
  methods ORDERMATSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_Z_MAINTENANCE_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~execute_action.
    CASE iv_action_name.

      WHEN 'setSensorData'.
        DATA lo_sensevt TYPE REF TO zcl_maint_sensevt.
        DATA ls_return TYPE zcl_z_maintenance_mpc=>sensorreturn.

        TRY.
            lo_sensevt = NEW #( io_tech_request_context->get_parameters( ) ).
            lo_sensevt->process_incoming( ).
            lo_sensevt->notify_clients( ).
          CATCH zcx_maint INTO DATA(lo_err).
            lo_sensevt->log_error( lo_err ).
        ENDTRY.

        ls_return = VALUE #( error_probability = lo_sensevt->get_err_probability( ) ).

        me->copy_data_to_ref( EXPORTING is_data = ls_return
                      CHANGING cr_data = er_data ).

      WHEN 'setState'.
        DATA(lv_function_parameters) = io_tech_request_context->get_parameters( ).
        DATA(lv_type) = lv_function_parameters[ name = 'TYPE' ]-value.
        DATA lt_return TYPE TABLE OF bapiret2.

        CASE lv_type.

          WHEN 'M2'.
            DATA: lv_qmel TYPE bapi2080_nothdre-notif_no.
            DATA(lv_qmel_val) = lv_function_parameters[ name = 'AUFNR' ]-value.
            lv_qmel = |{ lv_qmel_val ALPHA = IN }|.
            DATA ls_status TYPE bapi2080_notsti.

            ls_status = VALUE #(
                                langu = sy-langu
                                languiso = sy-langu
                                refdate = sy-datum
                                reftime = sy-uzeit
                                ).

            CALL FUNCTION 'BAPI_ALM_NOTIF_CLOSE'
              EXPORTING
                number   = lv_qmel
                syststat = ls_status
              TABLES
                return   = lt_return.
            COMMIT WORK.

          WHEN OTHERS. "Auftrag fertigmelden

            DATA: ls_header TYPE bapi_alm_order_headers_i,
                  lt_header TYPE TABLE OF bapi_alm_order_headers_i.
            DATA: lv_aufnr TYPE aufnr.
            DATA(lv_aufnr_val) = lv_function_parameters[ name = 'AUFNR' ]-value.
            lv_aufnr = |{ lv_aufnr_val ALPHA = IN }|.
*            lv_aufnr = '00000' && lv_function_parameters[ name = 'AUFNR' ]-value.

            DATA(ls_method) = VALUE bapi_alm_order_method( ).
            DATA lt_methods TYPE TABLE OF bapi_alm_order_method.

            ls_method = VALUE #(
              refnumber = 1
              objectkey = lv_aufnr
              objecttype = 'SRULE'
              method = 'CREATE'
            ).
            APPEND ls_method TO lt_methods.

            ls_method = VALUE #(
              refnumber = 1
              objectkey = lv_aufnr
              objecttype = 'HEADER'
              method = 'TECHNICALCOMPLETE'
            ).
            APPEND ls_method TO lt_methods.

            ls_method = VALUE #(
            refnumber = 1
            objectkey = space
            objecttype = space
            method = 'SAVE'
            ).
            APPEND ls_method TO lt_methods.

            ls_header = VALUE #(
              orderid    = lv_aufnr
            ).

            APPEND ls_header TO lt_header.

**            Abrechnungsregel
            DATA ls_srule TYPE bapi_alm_order_srule.
            DATA lt_srule TYPE TABLE OF bapi_alm_order_srule.

            ls_srule = VALUE #(
            percentage = '100'
            source = 'PSP'
             objnr = 'OR' && lv_aufnr
             settl_type = 'PER'
             wbs_element = 'A01'
            ).

            INSERT ls_srule INTO TABLE lt_srule.

            CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
              TABLES
                it_header  = lt_header
                it_srule   = lt_srule
                it_methods = lt_methods
                return     = lt_return.
            COMMIT WORK.

        ENDCASE.

        me->copy_data_to_ref( EXPORTING is_data = lt_return
                              CHANGING cr_data = er_data ).

        DATA lv_rfc_name TYPE tfdir-funcname.
        DATA lv_destination TYPE rfcdest.
        DATA lv_chan TYPE amc_channel_id.
        lv_destination = 'IGSCLNT100'.
        lv_chan = 'SMART1'.
        CALL FUNCTION 'Z_MAINT_PUSHMSG' DESTINATION lv_destination
          EXPORTING
            i_type    = 'u'
            i_channel = lv_chan.

      WHEN 'createOrder'.

        DATA: "ls_header    TYPE bapi_alm_order_headers_i,
          "lt_header    TYPE TABLE OF bapi_alm_order_headers_i,
          ls_header_up TYPE bapi_alm_order_headers_up,
          lt_header_up TYPE TABLE OF bapi_alm_order_headers_up,
          ls_operation TYPE bapi_alm_order_operation,
          lt_operation TYPE TABLE OF bapi_alm_order_operation,
          lt_numbers   TYPE TABLE OF bapi_alm_numbers.

        lv_function_parameters = io_tech_request_context->get_parameters( ).
        DATA lv_notif_nr(12) TYPE c.
        lv_notif_nr = lv_function_parameters[ name = 'ID' ]-value.


        CLEAR ls_method.
        CLEAR lt_methods.
*        clear ls_return.
        CLEAR lt_return.


        ls_method = VALUE #(
          refnumber   = '000001'
          objecttype  = 'HEADER'
          method      = 'CREATETONOTIF'
          objectkey   = '%000000000010000' && lv_notif_nr
        ).
        APPEND ls_method TO lt_methods.

        FREE ls_method.
        ls_method = VALUE #(
          refnumber   = '000001'
          objecttype  = 'OPERATION'
          method      = 'CREATE'
          objectkey   = '%00000000001'
        ).
        APPEND ls_method TO lt_methods.

        FREE ls_method.
        ls_method = VALUE #(
          refnumber   = '000001'
          method      = 'SAVE'
        ).
        APPEND ls_method TO lt_methods.

        ls_header = VALUE #(
*  orderid    = '%00000000001'
          order_type = 'PM02'
          planplant  = '1100'
          mn_wk_ctr  = 'SMART1'
        ).


        APPEND ls_header TO lt_header.

        ls_header_up = VALUE #(
          orderid   = '%00000000001'
          notif_no = 'X'
        ).
        APPEND ls_header_up TO lt_header_up.

        ls_operation = VALUE #(
          activity    = '0010'
          plant       = '1100'
          work_cntr   = 'SMART1'
          calc_key    = '1'
          control_key = 'PM02'
          description = 'TEST'
        ).
        APPEND ls_operation TO lt_operation.

        CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
          TABLES
            it_methods   = lt_methods
            it_header    = lt_header
*           it_header_up = lt_header_up
            it_operation = lt_operation
            return       = lt_return
            et_numbers   = lt_numbers.
*
        me->copy_data_to_ref( EXPORTING is_data = lt_return
                                      CHANGING cr_data = er_data ).



        IF NOT line_exists( lt_return[ type = 'E' ] ).
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.
        ELSE.
          ROLLBACK WORK.
        ENDIF.
**********************************************************************
        "meldung abschließen
        DATA: lv_qmel2 TYPE bapi2080_nothdre-notif_no.
        lv_qmel2 = |{ lv_notif_nr ALPHA = IN }|.
        DATA ls_status2 TYPE bapi2080_notsti.

        ls_status2 = VALUE #(
                            langu = sy-langu
                            languiso = sy-langu
                            refdate = sy-datum
                            reftime = sy-uzeit
                            ).


        CALL FUNCTION 'BAPI_ALM_NOTIF_CLOSE'
          EXPORTING
            number   = lv_qmel2
            syststat = ls_status2
          TABLES
            return   = lt_return.
        COMMIT WORK.

**********************************************************************
        "neuen Auftrag freigeben

        TRY .
            DATA(aufnr) = lt_numbers[ 1 ]-aufnr_new.

            CLEAR: lt_methods, lt_header.
            ls_method = VALUE #(
              refnumber = 1
              objectkey = aufnr
              objecttype = 'HEADER'
              method = 'RELEASE'
            ).
            APPEND ls_method TO lt_methods.

            ls_method = VALUE #(
            refnumber = 1
            objectkey = space
            objecttype = space
            method = 'SAVE'
            ).
            APPEND ls_method TO lt_methods.


            ls_header = VALUE #(
              orderid    = aufnr
            ).

            APPEND ls_header TO lt_header.

            CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
              TABLES
                it_header  = lt_header
                it_methods = lt_methods
                return     = lt_return.

            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.

          CATCH cx_root.

        ENDTRY.




      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.


  METHOD orderheadset_get_entity.
    DATA(lv_key_tab_val) = it_key_tab[ name = 'id' ]-value.
    DATA: lv_aufnr TYPE afko-aufnr,
          lt_ltxt  TYPE TABLE OF tline.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_key_tab_val
      IMPORTING
        output = lv_aufnr.

* Meldung
    SELECT SINGLE
      qmel~qmart AS type,
      qmel~qmnum AS id,
      qmel~qmtxt AS txt,
      qmel~qmdat AS date,
      qmel~mzeit AS time,
      crhd~arbpl,
      tplnr
      FROM qmel
      INNER JOIN qmih ON qmih~qmnum EQ qmel~qmnum
      INNER JOIN iloa ON iloa~iloan EQ qmih~iloan
      INNER JOIN crhd ON crhd~objid EQ qmel~arbpl
      WHERE qmart EQ 'M2'
      AND qmel~qmnum EQ @lv_aufnr
      AND NOT EXISTS ( SELECT * FROM jest WHERE objnr = qmel~objnr AND stat EQ 'I0072' AND inact = @space ) "keine technisch abgeschlossen Aufträge lesen (TABG)
      INTO @DATA(ls_notif).
    MOVE-CORRESPONDING ls_notif TO er_entity.

* Auftrag
    IF ls_notif IS INITIAL.
      SELECT SINGLE
          afko~aufnr AS id,
          aufk~ktext AS txt,
          aufk~vaplz AS arbpl,
          aufk~idat1 AS date,
          aufk~auart AS type,
          tplnr
          FROM aufk
          INNER JOIN jest ON jest~objnr EQ aufk~objnr
          INNER JOIN afko ON afko~aufnr EQ aufk~aufnr
          INNER JOIN afih ON afih~aufnr EQ aufk~aufnr
          INNER JOIN iloa ON iloa~iloan EQ afih~iloan
          WHERE aufk~auart EQ 'PM02'
          AND aufk~aufnr EQ @lv_aufnr
*          AND jest~chgnr = ( SELECT MAX( chgnr ) FROM jest AS jest2 WHERE jest2~objnr = jest~objnr AND jest2~stat = jest~stat )
          AND jest~inact = ''
          AND jest~stat EQ 'I0002'
          INTO @DATA(ls_order).


      MOVE-CORRESPONDING ls_order TO er_entity.
    ENDIF.

* Katalogdaten - 1.Position aus der Meldung : Objekt, Schadensbild und Ursache
* Zusätzliche Daten: Priorität, qmel~ausvn, qmel~auztv
    SELECT SINGLE
      afih~qmnum,
      afih~priok,
      viqmel~ausvn,
      viqmel~auztv,
      viqmfe~otgrp,
      viqmfe~oteil,
      viqmfe~fegrp,
      viqmfe~fecod,
      viqmfe~fetxt,
      viqmur~urgrp,
      viqmur~urcod,
      viqmur~urtxt
      FROM viqmel
      LEFT JOIN afih ON afih~aufnr EQ @lv_aufnr OR afih~qmnum EQ @lv_aufnr
      LEFT JOIN viqmur ON viqmur~qmnum EQ @lv_aufnr OR viqmur~qmnum EQ afih~qmnum AND viqmur~fenum EQ '0001'
      LEFT JOIN viqmfe ON viqmfe~qmnum EQ @lv_aufnr OR viqmfe~qmnum eq afih~qmnum AND viqmfe~posnr EQ '0001'
      WHERE viqmel~qmnum EQ @lv_aufnr or viqmel~qmnum eq afih~qmnum
      INTO @DATA(ls_catdata).

    MOVE-CORRESPONDING ls_catdata TO er_entity.

* Texte aus Katalog

* Objekttext
    SELECT SINGLE
      qpct~kurztext AS oktxt
      FROM qpct
      WHERE qpct~codegruppe = @ls_catdata-otgrp
      AND qpct~code = @ls_catdata-oteil
      INTO @DATA(ls_oktxt).
    er_entity-oktxt = ls_oktxt.
*
* Schadentext
    SELECT SINGLE
      qpct~kurztext AS oktxt
      FROM qpct
      WHERE qpct~codegruppe = @ls_catdata-fegrp
      AND qpct~code = @ls_catdata-fecod
      INTO @DATA(ls_fktxt).
    er_entity-fktxt = ls_fktxt.

* Ursachentext
    SELECT SINGLE
      qpct~kurztext AS oktxt
      FROM qpct
      WHERE qpct~codegruppe = @ls_catdata-urgrp
      AND qpct~code = @ls_catdata-urcod
      INTO @DATA(ls_urktxt).
    er_entity-urktxt = ls_urktxt.


* Langtext zur Meldung/Auftrag
    DATA(lv_object) = COND thead-tdobject( WHEN ls_notif IS INITIAL THEN 'AUFK' ELSE 'QMEL' ).
    DATA(lv_name) = CONV thead-tdname( lv_aufnr ).
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id       = 'LTXT'
        language = sy-langu
        name     = lv_name
        object   = lv_object
      TABLES
        lines    = lt_ltxt
      EXCEPTIONS
        OTHERS   = 0.

    LOOP AT lt_ltxt INTO DATA(ls_ltxt).
      SHIFT ls_ltxt BY 4 PLACES.
      MODIFY lt_ltxt FROM ls_ltxt.
    ENDLOOP.
    er_entity-ltxt = concat_lines_of( table = lt_ltxt sep = ';' ).


  ENDMETHOD.


  METHOD orderheadset_get_entityset.

    TRY.

        SELECT
          qmel~qmart AS type,
          qmel~qmnum AS id,
          qmel~qmtxt AS txt,
          qmel~qmdat AS date,
          qmel~mzeit AS time,
          crhd~arbpl AS arbpl,
          tplnr
          FROM qmel
          INNER JOIN qmih ON qmih~qmnum EQ qmel~qmnum
          INNER JOIN iloa ON iloa~iloan EQ qmih~iloan
          INNER JOIN crhd ON crhd~objid EQ qmel~arbpl
          WHERE qmart EQ 'M2'
          and qmel~qmnum ne '000010000099'
          and qmel~qmnum ne '000010000098'
          AND NOT EXISTS ( SELECT * FROM jest WHERE objnr = qmel~objnr AND stat EQ 'I0072' AND inact = @space ) "keine technisch abgeschlossen Aufträge lesen (TABG)
          ORDER BY id DESCENDING
          INTO TABLE @DATA(lt_mel).

*qmfe~FENUM

        SELECT
          afko~aufnr AS id,
          aufk~ktext AS txt,
          aufk~vaplz AS arbpl,
          aufk~idat1 AS date,
          aufk~auart AS type,
          tplnr
          FROM aufk
          INNER JOIN jest ON jest~objnr EQ aufk~objnr
          INNER JOIN afko ON afko~aufnr EQ aufk~aufnr
          INNER JOIN afih ON afih~aufnr EQ aufk~aufnr
          INNER JOIN iloa ON iloa~iloan EQ afih~iloan
          WHERE aufk~auart EQ 'PM02'
*          AND jest~chgnr = ( SELECT MAX( chgnr ) FROM jest AS jest2 WHERE jest2~objnr = jest~objnr AND jest2~stat = jest~stat )
          AND jest~inact = ''
          AND jest~stat EQ 'I0002'
          INTO TABLE @DATA(lt_data).

        DATA ls_entityset TYPE zcl_z_maintenance_mpc=>ts_orderhead.


        MOVE-CORRESPONDING lt_mel TO et_entityset.

        LOOP AT lt_data INTO DATA(ls_data).
          CLEAR ls_entityset.
          ls_entityset-id = ls_data-id.
          ls_entityset-arbpl = ls_data-arbpl.
          ls_entityset-txt = ls_data-txt.
          ls_entityset-date = ls_data-date.
          ls_entityset-type = 'PM02'.
          ls_entityset-tplnr = ls_data-tplnr.
          APPEND ls_entityset TO et_entityset.
        ENDLOOP.


      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD ordermatset_get_entityset.

    DATA(lv_key_tab_val) = it_key_tab[ name = 'id' ]-value.
    DATA: lv_aufnr TYPE afko-aufnr.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_key_tab_val
      IMPORTING
        output = lv_aufnr.

    SELECT
      resb~aufnr AS id,
      resb~vornr,
      resb~bdmng AS menge,
      resb~meins AS einheit,
      makt~maktx AS matxt
      FROM resb
      INNER JOIN makt ON makt~matnr EQ resb~matnr
      WHERE aufnr = @lv_aufnr
      INTO TABLE @DATA(lt_data).


    MOVE-CORRESPONDING lt_data TO et_entityset.


  ENDMETHOD.


  METHOD orderposset_get_entityset.
    DATA(lv_key_tab_val) = it_key_tab[ name = 'id' ]-value.
    DATA: lv_aufnr TYPE afko-aufnr.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_key_tab_val
      IMPORTING
        output = lv_aufnr.

    SELECT
       qmel~qmart AS type,
       qmel~qmnum AS id,
       qmfe~fenum AS posid,
*        iloa~tplnr,
*       qmel~qmtxt AS txt,
*       qmel~qmdat AS date,
*       qmel~mzeit AS time,
*       qmel~arbpl,
       fetxt
       FROM qmel
*       INNER JOIN qmih ON qmih~qmnum EQ qmel~qmnum
*       INNER JOIN iloa ON iloa~iloan EQ qmih~iloan
       INNER JOIN qmfe ON qmfe~qmnum = qmel~qmnum
       WHERE qmart EQ 'M2'
       AND qmel~qmnum EQ @lv_aufnr
       INTO TABLE @DATA(lt_mel).

*
*    SELECT SINGLE aufpl FROM afko
*      WHERE aufnr = @lv_aufnr
*      INTO @DATA(lv_aufpl).
*
*    SELECT * FROM afvc
*      WHERE aufpl = @lv_aufpl
*      INTO CORRESPONDING FIELDS OF TABLE @et_entityset."@DATA(lt_aufpl).


    MOVE-CORRESPONDING lt_mel TO et_entityset.



    IF lt_mel IS INITIAL.


      SELECT
        aufk~auart AS type,
        aufk~aufnr AS id,
        afvc~vornr AS posid,
        afvc~ltxa1 AS fetxt
        FROM aufk
        INNER JOIN afko ON afko~aufnr EQ aufk~aufnr
        INNER JOIN afvc ON afvc~aufpl EQ afko~aufpl
        WHERE aufk~aufnr EQ @lv_aufnr
        INTO TABLE @DATA(lt_order).

      MOVE-CORRESPONDING lt_order TO et_entityset.

    ENDIF.

  ENDMETHOD.


  METHOD sensor1set_get_entityset.

    DATA entity TYPE zcl_z_maintenance_mpc=>ts_sensor1.
    DATA(o_converter) = zcl_maint_log=>get_instance( ).

    SELECT
      id,
      timestamp AS ts,
      value1,
      value2
      FROM ztsensorlog INTO TABLE @DATA(sensors).

    LOOP AT sensors REFERENCE INTO DATA(sensor).
      o_converter->get_abap_datetime(
        EXPORTING
          unix_timestamp = sensor->ts
        IMPORTING
          abap_timestamp = DATA(abap_ts)
      ).
      entity = VALUE #(
       id = sensor->id
       ts = abap_ts
       value1 = sensor->value1
       value2 = sensor->value2
      ).
      INSERT entity INTO TABLE et_entityset.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
