*&---------------------------------------------------------------------*
*& Report ZR_ORDER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_order.

DATA: notif_header        LIKE bapi2080_nothdri,
      notif_type          TYPE bapi2080-notif_type,
      notif_header_export TYPE bapi2080_nothdre,
      it_return           TYPE TABLE OF  bapiret2 WITH HEADER LINE,
      lt_return           TYPE TABLE OF  bapiret2 WITH HEADER LINE,
      ls_methods          TYPE bapi_alm_order_method,
      lt_methods          TYPE TABLE OF bapi_alm_order_method,
      ls_header           TYPE bapi_alm_order_headers_i,
      lt_header           TYPE TABLE OF bapi_alm_order_headers_i,
      ls_header_up        TYPE bapi_alm_order_headers_up,
      lt_header_up        TYPE TABLE OF bapi_alm_order_headers_up,
      ls_operation        TYPE bapi_alm_order_operation,
      lt_operation        TYPE TABLE OF bapi_alm_order_operation,
      lt_numbers          TYPE TABLE OF bapi_alm_numbers.


*notif_header-desstdate = sy-datum.
*notif_header-short_text = 'Add Notification to Order'.
*notif_header-reportedby = sy-uname.
*notif_type = 'M2'.
*
*CALL FUNCTION 'BAPI_ALM_NOTIF_CREATE'
*  EXPORTING
*    notif_type         = notif_type
*    notifheader        = notif_header
*  IMPORTING
*    notifheader_export = notif_header_export.
*
*CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
*  EXPORTING
*    number      = notif_header_export-notif_no
*  IMPORTING
*    notifheader = notif_header_export
*  TABLES
*    return      = it_return.




*------ Create Oder -------*
*OBJECTKEY
*•0-12 Auftragsnummer.
*•13-16 Vorgangsnummer
*•17-20 Untervorgangsnummer
*•13-24 Meldungsnummer (nur bei Methode CREATETONOTIF)

*OBJECTKEY
*%00000000001000012345678
*notif_header_export-notif_no
ls_methods-refnumber = '000001'.
ls_methods-objecttype = 'HEADER'.
ls_methods-method = 'CREATETONOTIF'.
*CONCATENATE '%00000000001' '000010000095' INTO ls_methods-objectkey.
ls_methods-objectkey = '000010000088'.
INSERT ls_methods INTO TABLE lt_methods.
*FREE ls_methods.


ls_methods-refnumber = '000001'.
*ls_methods-objectkey = '%00000000001'.
ls_methods-method = 'SAVE'.
INSERT ls_methods INTO TABLE lt_methods.

*000010000095
ls_header-orderid = '%00000000001'.
*ls_header-notif_type = 'M1'.
ls_header-order_type = 'PM01'.
ls_header-planplant = '1100'.
ls_header-bus_area = '1000'.
ls_header-mn_wk_ctr = 'SMART1'.


ls_header-start_date = sy-datum.
INSERT ls_header INTO TABLE lt_header.

ls_header_up-orderid = '%00000000001'.
ls_header_up-notif_no = 'X'.
INSERT ls_header_up INTO TABLE lt_header_up.


*ls_operation-activity = '0010'.
*ls_operation-control_key = 'PM01'.
*ls_operation-plant = '1100'.
*ls_operation-work_cntr = 'SMART1'.
*ls_operation-CALC_KEY = 1.

INSERT ls_operation INTO TABLE lt_operation.

CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
  TABLES
    it_methods   = lt_methods
    it_header    = lt_header
    it_header_up = lt_header_up
*    it_operation = lt_operation
    return       = lt_return
    et_numbers   = lt_numbers.

*IF line_exists( lt_return[ type = 'E' ] ).
  LOOP AT lt_return.
    WRITE: lt_return-message.
  ENDLOOP.
*ENDIF.

CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
