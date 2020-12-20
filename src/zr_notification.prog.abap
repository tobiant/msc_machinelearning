*&---------------------------------------------------------------------*
*& Report ZR_NOTIFICATION
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_notification.

DATA:

  gs_notif_type         TYPE bapi2080-notif_type,
  gs_notifheader        TYPE bapi2080_nothdri,
  gs_notifheader_export TYPE bapi2080_nothdre,
  gt_notitem            TYPE TABLE OF bapi2080_notitemi WITH HEADER LINE,
  gt_notifcaus          TYPE TABLE OF bapi2080_notcausi WITH HEADER LINE,
  gt_longtexts          TYPE TABLE OF bapi2080_notfulltxti WITH HEADER LINE,
  gt_return             TYPE TABLE OF bapiret2 WITH HEADER LINE,
  g_ind                 TYPE c,
  gs_return_notifheader TYPE bapi2080_nothdre.

DATA(o_randomer) = cl_abap_random_int=>create( seed = CONV i( sy-uzeit )
                                      min  = 1
                                      max = 99 ).
DATA(random_int) = o_randomer->get_next( ).

DATA random_string TYPE string.
random_string = random_int.

IF random_int > 50.
  DATA(arbpl) = '10000185'. "10000185 SMART1
ELSE.
  arbpl = '10000186'."*10000186 SMART2
ENDIF.

* Meldungstyp
gs_notif_type = 'M2'.

* Kopfdaten
gs_notifheader = VALUE #(
  funct_loc	  = '1000-001-AA-01'
  short_text  = 'Meldung_' && random_string
  priority    = '1'
*  desstdate  = ''
*  dessttime  = ''
*  desenddate  = ''
*  desendtm  = ''
*  strmlfndate  = ''
*  strmlfntime  = ''
  reportedby  = 'TGUBE'
*  notif_date  = ''
*  notiftime  = ''
  code_group  = '$$OSS001'
  coding      = '$$01'
*  endmlfndate  = ''
*  endmlfntime  = ''
  pm_wkctr = arbpl   "Arbpl
).




* Positionen
gt_notitem-item_key = '0001'.
gt_notitem-item_sort_no = '0001'.

*gt_notitem-item_key = '0002'.
*gt_notitem-item_sort_no = '0001'.
gt_notitem-dl_codegrp = 'PM1'. " parte objeto
gt_notitem-dl_code = '1'.
*gt_notitem-d_codegrp = 'S.LAVBOT'. " sint. averia
*gt_notitem-d_codegrp = '0010'.
gt_notitem-descript = 'Ausnahme1 aufgetreten'.
APPEND gt_notitem.

gt_notitem-item_key = '0002'.
gt_notitem-item_sort_no = '0002'.
gt_notitem-dl_codegrp = 'PM1'. " parte objeto
gt_notitem-dl_code = '2'.
*gt_notitem-d_codegrp = 'S.LAVBOT'. " sint. averia
*gt_notitem-d_codegrp = '0010'.
gt_notitem-descript = 'Ausnahme2 aufgetreten'.

APPEND gt_notitem.

* Position mit Meldungsgrund
*gt_notifcaus-cause_key = '0002'.
*gt_notifcaus-cause_sort_no = '0001'.
*gt_notifcaus-item_key = '0002'.
*gt_notifcaus-cause_codegrp = 'C.LAVBOT'.
*gt_notifcaus-cause_code = '0010'.
*gt_notifcaus-causetext = 'CAUSAS PRUEBA'.

*APPEND gt_notifcaus.

*texto de cabecera
*gt_longtexts-objtype = 'QMEL'.
*gt_longtexts-objkey = '0001'.
*gt_longtexts-format_col = '*'.
*gt_longtexts-text_line = 'Linea 1 Prueba de Texto'.

*APPEND gt_longtexts.

*texto de notificacion
*gt_longtexts-objtype = 'QMFE'.
*gt_longtexts-objkey = '0002'.
*gt_longtexts-format_col = '*'.
*gt_longtexts-text_line = 'Linea 1A Prueba de Texto'.

*APPEND gt_longtexts.

*texto de causa
*gt_longtexts-objtype = 'QMUR'.
*gt_longtexts-objkey = '0003'.
*gt_longtexts-format_col = '*'.
*gt_longtexts-text_line = 'Linea 1B Prueba de Texto'.

*APPEND gt_longtexts.


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

*LOOP AT gt_return WHERE type EQ 'E'.
*  WRITE: gt_return-message.
*  g_ind = 'X'.
*ENDLOOP.

CHECK g_ind IS INITIAL.

CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
  EXPORTING
    number      = gs_notifheader_export-notif_no
  IMPORTING
    notifheader = gs_return_notifheader
  TABLES
    return      = gt_return.

*WRITE: 'Meldungsnummer', gs_return_notifheader-notif_no.

CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
  IMPORTING
    return = gt_return.

*LOOP AT gt_return.
*  WRITE: gt_return-message.
*ENDLOOP.
