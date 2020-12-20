class ZCL_LOGREG definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF str_sample,
        value1      TYPE decfloat34,
        value2      TYPE decfloat34,
        y           TYPE decfloat34,
        y_hat       TYPE decfloat34,
        dot_product TYPE decfloat34,
      END OF str_sample .
  types:
    BEGIN OF str_s_w,
        value1 TYPE decfloat34,
        value2 TYPE decfloat34,
      END OF str_s_w .
  types TT_SAMPLE type ref to DATA .

  methods CONSTRUCTOR
    importing
      !I_ARBPL type ARBPL
      !I_BIAS type DECFLOAT34 optional
      !I_ITERATION type I optional
      !I_LEARNING_RATE type ZFLOAT optional
      !I_WEIGHTS type STR_S_W optional
      !I_PREDICTORS type I optional
      !I_SAMPLE_SIZE type I optional .
  methods DERIVATE .
  methods TRANSPOSE .
  methods INIT
    importing
      !I_VALUES type STR_S_W optional .
  methods GET_LEARNING_RATE
    returning
      value(R_RESULT) type ZFLOAT .
  methods SET_LEARNING_RATE
    importing
      !I_LEARNING_RATE type ZFLOAT .
  methods GET_ITERATION
    returning
      value(R_RESULT) type I .
  methods SET_ITERATION
    importing
      !I_ITERATION type I .
  methods GET_ARBPL
    returning
      value(R_RESULT) type ARBPL .
  methods SET_ARBPL
    importing
      !I_ARBPL type ARBPL .
  methods GET_BIAS
    returning
      value(R_RESULT) type ZFLOAT .
  methods SET_BIAS
    importing
      !I_BIAS type ZFLOAT .
  methods GET_NO_OF_PREDICTORS
    returning
      value(R_RESULT) type I .
  methods SET_NO_OF_PREDICTORS
    importing
      !I_NO_OF_PREDICTORS type I .
  methods CALC_Y_HAT
    returning
      value(R_Y_HAT) type DECFLOAT34 .
  methods GET_S_W
    returning
      value(R_RESULT) type STR_SAMPLE .
  methods SET_S_W
    importing
      !I_S_W type STR_SAMPLE .
  PROTECTED SECTION.
private section.

  data GR_DATA1 type ref to DATA .
  data ARBPL type ARBPL .
  data T_TRIMMED_SAMPLE_TRANSPOSED type ref to DATA .
  data Y_HAT type DECFLOAT34 .
  data Y type DECFLOAT34 .
  data LEARNING_RATE type ZFLOAT .
  data ITERATION type I .
  data BIAS type ZFLOAT .
  data SAMPLESIZE type I value 1000 ##NO_TEXT.
  data NO_OF_PREDICTORS type I .
  data DERIVATION_W type DECFLOAT34 .
    data S_WEIGHTS type STR_S_W .
  data:
    t_sample TYPE STANDARD TABLE OF ztsensorlog .
  data:
    t_trimmed_sample TYPE STANDARD TABLE OF str_sample .
ENDCLASS.



CLASS ZCL_LOGREG IMPLEMENTATION.


  METHOD calc_y_hat.

    DATA dot_product TYPE decfloat34.
    DATA r_arithmetic_error TYPE REF TO cx_sy_arithmetic_error.

    TRY.
        LOOP AT t_trimmed_sample REFERENCE INTO DATA(r_sample).
          r_sample->dot_product = r_sample->value1 * s_weights-value1 +  r_sample->value2 * s_weights-value2.
          r_sample->y_hat = 1 / ( 1 + exp( ( ( -1 ) * r_sample->dot_product + bias ) ) ).
          r_y_hat = r_sample->y_hat.
        ENDLOOP.
      CATCH cx_sy_arithmetic_error INTO r_arithmetic_error.
        DATA(error) = r_arithmetic_error->get_text( ).
        MESSAGE error TYPE 'E'.
    ENDTRY.

  ENDMETHOD.


  METHOD constructor.
    me->arbpl = i_arbpl.

    IF i_bias IS NOT SUPPLIED.
      SELECT SINGLE bias FROM ztsensors WHERE machine EQ @i_arbpl INTO @me->bias.
    ELSE.
      me->bias = i_bias.
    ENDIF.

    IF i_bias IS NOT SUPPLIED.
      SELECT * FROM ztsensors WHERE machine EQ @i_arbpl INTO TABLE @DATA(t_sensors).
      me->s_weights = VALUE #(
      value1 = t_sensors[ 1 ]-weight
      value2 = t_sensors[ 2 ]-weight
      ).
    ELSE.
      me->s_weights = i_weights.
    ENDIF.

    me->iteration = i_iteration.
    me->learning_rate = i_learning_rate.
    me->no_of_predictors = i_predictors.
    me->samplesize = i_sample_size.

  ENDMETHOD.


  METHOD derivate.
    FIELD-SYMBOLS: <field_line_1> TYPE any.
    FIELD-SYMBOLS: <field_line_2> TYPE any.
    FIELD-SYMBOLS: <field_line_3> TYPE any.
    FIELD-SYMBOLS: <field_line_4> TYPE any.
    FIELD-SYMBOLS: <table> TYPE table.

    DATA sum1 TYPE decfloat34.
    DATA sum_y_hat TYPE decfloat34.
    DATA sum_y TYPE decfloat34.
    DATA sum2 TYPE decfloat34.

    ASSIGN t_trimmed_sample_transposed->* TO <table>.
    DO.
      DATA(column) = sy-index.
      ASSIGN COMPONENT column OF STRUCTURE <table>[ 1 ] TO <field_line_1>. "value1
      IF sy-subrc NE 0.
        EXIT.
      ENDIF.
      ASSIGN COMPONENT column OF STRUCTURE <table>[ 2 ] TO <field_line_2>. "Value2
      ASSIGN COMPONENT column OF STRUCTURE <table>[ 3 ] TO <field_line_3>. "y
      ASSIGN COMPONENT column OF STRUCTURE <table>[ 4 ] TO <field_line_4>. "y_hat

      sum_y = sum_y + <field_line_3>.
      sum_y_hat = sum_y_hat + <field_line_4>.

      sum1 = sum1 + ( <field_line_1> * ( <field_line_4> - <field_line_3> ) ).
      sum2 = sum2 + ( <field_line_2> * ( <field_line_4> - <field_line_3> ) ).
    ENDDO.

    "derivate
    DATA(pre_w1) = 1 / samplesize *  sum1. "ableitung gewicht 1
    DATA(pre_w2) = 1 / samplesize *  sum2. "ableitung gewich 2
    DATA(new_bias) = 1 / samplesize * ( sum_y_hat - sum_y ). "ableitung bias

    "update global parameter bias and weight
    me->s_weights-value1 = me->s_weights-value1 - ( learning_rate * pre_w1 ).
    me->s_weights-value2 = me->s_weights-value2 - ( learning_rate * pre_w2 ).
    me->bias = me->bias - ( learning_rate * new_bias ).

  ENDMETHOD.


  METHOD get_arbpl.
    r_result = me->arbpl.
  ENDMETHOD.


  METHOD get_bias.
    r_result = me->bias.
  ENDMETHOD.


  METHOD get_iteration.
    r_result = me->iteration.
  ENDMETHOD.


  METHOD get_learning_rate.
    r_result = me->learning_rate.
  ENDMETHOD.


  METHOD get_no_of_predictors.
    r_result = me->no_of_predictors.
  ENDMETHOD.


  METHOD get_s_w.
    r_result = me->s_weights.
  ENDMETHOD.


  METHOD init.
    DATA ls_sample TYPE str_sample.

    IF i_values IS SUPPLIED.
      ls_sample = i_values.
      INSERT ls_sample INTO TABLE t_trimmed_sample.
    ELSE.
      SELECT * FROM ztsensorlog INTO TABLE t_sample
      UP TO samplesize ROWS
      WHERE sensorid EQ me->arbpl.

      LOOP AT t_sample REFERENCE INTO DATA(r_sample).
        ls_sample = VALUE #(
          value1 = r_sample->value1
          value2 = r_sample->value2
          y = r_sample->error
        ).
        INSERT ls_sample INTO TABLE t_trimmed_sample.
      ENDLOOP.
    ENDIF.


  ENDMETHOD.


  METHOD set_arbpl.
    me->arbpl = i_arbpl.
  ENDMETHOD.


  METHOD set_bias.
    me->bias = i_bias.
  ENDMETHOD.


  METHOD set_iteration.
    me->iteration = i_iteration.
  ENDMETHOD.


  METHOD set_learning_rate.
    me->learning_rate = i_learning_rate.
  ENDMETHOD.


  METHOD set_no_of_predictors.
    me->no_of_predictors = i_no_of_predictors.
  ENDMETHOD.


  METHOD set_s_w.
    me->s_weights = i_s_w.
  ENDMETHOD.


  METHOD transpose.


    DATA
      : gt_fcat     TYPE        lvc_t_fcat
      , gs_fcat     TYPE         lvc_s_fcat
      , gr_table    TYPE REF TO data
      , gr_struc    TYPE REF TO data
      .
    FIELD-SYMBOLS
      : <gs_fcat>   TYPE        lvc_s_fcat
      , <gt_table>  TYPE STANDARD TABLE
      , <gs_struc>  TYPE        any
      , <gs_struc2>  TYPE        any
      , <gs_struc3>  TYPE        any
      , <gs_struc4>  TYPE        any
      , <gs_struc5>  TYPE        any
      , <gs_struc6>  TYPE        any
      , <gv_comp>   TYPE        any
      , <my_table>  TYPE STANDARD TABLE
      .

    FIELD-SYMBOLS: <table> TYPE table.
    FIELD-SYMBOLS: <row> TYPE any.
*    ASSIGN t_trimmed_sample_transposed->* TO <table>.

    IF gr_data1 IS INITIAL.
      LOOP AT t_trimmed_sample INTO DATA(sample).
        " Feldkatalog rudimentär aufbauen
        APPEND INITIAL LINE TO gt_fcat ASSIGNING <gs_fcat>.
        <gs_fcat>-fieldname = 'ID' && CONV num8( sy-tabix ).          " Feldname
        <gs_fcat>-rollname  = 'ZLOGREG'.          " Datenelement
        <gs_fcat>-ref_field = 'VALUE'.
        <gs_fcat>-ref_table = 'ZTCOE'.
      ENDLOOP.

      CALL FUNCTION 'LVC_FIELDCAT_COMPLETE'
        EXPORTING
          i_buffer_active = abap_false
        CHANGING
          ct_fieldcat     = gt_fcat.

      " Tabelle dynamisch erstellen
      CALL METHOD cl_alv_table_create=>create_dynamic_table
        EXPORTING
          it_fieldcatalog           = gt_fcat
        IMPORTING
          ep_table                  = gr_data1
        EXCEPTIONS
          generate_subpool_dir_full = 1
          OTHERS                    = 2.
      IF sy-subrc <> 0.
        WRITE: / 'Shit! Das war nix!'.
      ENDIF.

      ASSIGN gr_data1->* TO <my_table>.
      APPEND INITIAL LINE TO <my_table> ASSIGNING <gs_struc>.
      APPEND INITIAL LINE TO <my_table> ASSIGNING <gs_struc2>.
      APPEND INITIAL LINE TO <my_table> ASSIGNING <gs_struc3>.
      APPEND INITIAL LINE TO <my_table> ASSIGNING <gs_struc4>.
      APPEND INITIAL LINE TO <my_table> ASSIGNING <gs_struc5>.
    ELSE.

      ASSIGN gr_data1->* TO <my_table>.
      READ TABLE <my_table> ASSIGNING <gs_struc> INDEX 1.
      READ TABLE <my_table> ASSIGNING <gs_struc2> INDEX 2.
      READ TABLE <my_table> ASSIGNING <gs_struc3> INDEX 3.
      READ TABLE <my_table> ASSIGNING <gs_struc4> INDEX 4.
      READ TABLE <my_table> ASSIGNING <gs_struc5> INDEX 5.
    ENDIF.


    LOOP AT t_trimmed_sample INTO sample.
      DATA(fieldname) = |ID{ CONV num8( sy-tabix ) }|.
      ASSIGN COMPONENT fieldname OF STRUCTURE <gs_struc> TO <gv_comp>.
      <gv_comp> = sample-value1.
      fieldname = |ID{ CONV num8( sy-tabix ) }|.
      ASSIGN COMPONENT fieldname OF STRUCTURE <gs_struc2> TO <gv_comp>.
      <gv_comp> = sample-value2.
      fieldname = |ID{ CONV num8( sy-tabix ) }|.
      ASSIGN COMPONENT fieldname OF STRUCTURE <gs_struc3> TO <gv_comp>.
      <gv_comp> = sample-y.
      fieldname = |ID{ CONV num8( sy-tabix ) }|.
      ASSIGN COMPONENT fieldname OF STRUCTURE <gs_struc4> TO <gv_comp>.
      <gv_comp> = sample-y_hat.
      fieldname = |ID{ CONV num8( sy-tabix ) }|.
      ASSIGN COMPONENT fieldname OF STRUCTURE <gs_struc5> TO <gv_comp>.
      <gv_comp> = sample-dot_product.
    ENDLOOP.

    GET REFERENCE OF <my_table> INTO me->t_trimmed_sample_transposed.


  ENDMETHOD.
ENDCLASS.
