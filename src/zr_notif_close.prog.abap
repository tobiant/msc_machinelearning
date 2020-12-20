*&---------------------------------------------------------------------*
*& Report ZR_NOTIF_CLOSE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_notif_close.

DATA ls_status TYPE bapi2080_notsti.
DATA no TYPE bapi2080_nothdre-notif_no.
DATA lt_return TYPE TABLE OF bapiret2.
ls_status = VALUE #(
                    langu = sy-langu
                    languiso = sy-langu
                    refdate = sy-datum
                    reftime = sy-uzeit
                    ).
no = |{ '10000026' ALPHA = IN }| .

CALL FUNCTION 'BAPI_ALM_NOTIF_CLOSE'
  EXPORTING
    number   = no
    syststat = ls_status
**   TESTRUN            = ' '
** IMPORTING
**   SYSTEMSTATUS       =
**   USERSTATUS         =
  TABLES
    return   = lt_return.
COMMIT WORK.
