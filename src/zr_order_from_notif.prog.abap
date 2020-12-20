*&---------------------------------------------------------------------*
*& Report ZR_ORDER_FROM_NOTIF
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_order_from_notif.

DATA: it_return       TYPE TABLE OF  bapiret2 WITH HEADER LINE,
      lt_return       TYPE TABLE OF  bapiret2 WITH HEADER LINE,
      ls_methods      TYPE bapi_alm_order_method,
      lt_methods      TYPE TABLE OF bapi_alm_order_method,
      ls_header       TYPE bapi_alm_order_headers_i,
      lt_header       TYPE TABLE OF bapi_alm_order_headers_i,
      ls_header_up    TYPE bapi_alm_order_headers_up,
      lt_header_up    TYPE TABLE OF bapi_alm_order_headers_up,
      ls_operation    TYPE bapi_alm_order_operation,
      lt_operation    TYPE TABLE OF bapi_alm_order_operation,
      lt_numbers      TYPE TABLE OF bapi_alm_numbers,
      lv_notif_nr(12) TYPE c VALUE '000010000093'.

ls_methods = VALUE #(
  refnumber   = '000001'
  objecttype  = 'HEADER'
  method      = 'CREATETONOTIF'
  objectkey   = '%00000000001' && lv_notif_nr
).
APPEND ls_methods TO lt_methods.

FREE ls_methods.
ls_methods = VALUE #(
  refnumber   = '000001'
  objecttype  = 'OPERATION'
  method      = 'CREATE'
  objectkey   = '%00000000001'
).
APPEND ls_methods TO lt_methods.

FREE ls_methods.
ls_methods = VALUE #(
  refnumber   = '000001'
  method      = 'SAVE'
).
APPEND ls_methods TO lt_methods.

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
  description = 'TEST NERO'

).
APPEND ls_operation TO lt_operation.

CALL FUNCTION 'BAPI_ALM_ORDER_MAINTAIN'
  TABLES
    it_methods   = lt_methods
    it_header    = lt_header
*   it_header_up = lt_header_up
    it_operation = lt_operation
    return       = lt_return
    et_numbers   = lt_numbers.


LOOP AT lt_return.
  WRITE: / |{ lt_return-type }{ lt_return-number }({ lt_return-id }): { lt_return-message }|.

ENDLOOP.
*ENDIF.
LOOP AT lt_numbers INTO DATA(ls_numbers).
  DATA(createdorder) = ls_numbers-aufnr_new.
ENDLOOP.

IF NOT line_exists( lt_return[ type = 'E' ] ).
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.
ELSE.
  ROLLBACK WORK.
ENDIF.

CALL FUNCTION 'DEQUEUE_ALL'
  EXPORTING
    _synchron = 'X'.
COMMIT WORK AND WAIT.

* Contains number of created order
SHIFT createdorder LEFT DELETING LEADING '0'.
WRITE:/ 'Works Order:', createdorder.
