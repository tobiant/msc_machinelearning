*&---------------------------------------------------------------------*
*& Report ZR_TRAININGDATACREATOR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_trainingdatacreator.

DELETE FROM ztsensorlog.


DATA pingid TYPE zpingid.
DATA ls_senslog TYPE ztsensorlog.
DATA ts TYPE zunxts VALUE 1570710600.
DATA error_count TYPE i.
DATA error_prozent TYPE decfloat34.
DATA datasets1 TYPE i VALUE 500.
DATA datasets2 TYPE i VALUE 500.
DATA error TYPE c1.


"wide range, will produce high error percentage
DATA(o_temp_randomer) = cl_abap_random_int=>create(
                                                     seed = CONV i( sy-tabix )
                                                     min  = 17
                                                     max = 45
                                                 ).

DATA(o_humid_randomer) = cl_abap_random_int=>create(
                                                     seed = CONV i( sy-uzeit )
                                                     min  = 45
                                                     max = 80
                                                 ).

DO datasets1 TIMES.
  error = 0.

  DATA(random_temp) = o_temp_randomer->get_next( ).
  DATA(random_humid) = o_humid_randomer->get_next( ).

  IF random_temp NOT BETWEEN 15 AND 30.
    error = 1.
  ENDIF.

  IF random_humid NOT BETWEEN 40 AND 70.
    error = 1.
  ENDIF.

  IF error EQ 1.
    ADD 1 TO error_count.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZPINGID'
    IMPORTING
      number      = pingid.

  ls_senslog = VALUE #(
    id = pingid
    sensorid = 'SMART1'
    timestamp = ts
    value1 = random_temp
    value2 = random_humid
    error = error
  ).

  INSERT ztsensorlog FROM ls_senslog.

  ADD 10 TO ts.

ENDDO.


"add some more values in the regular range that dont procude errors
o_temp_randomer = cl_abap_random_int=>create(
                                                 seed = CONV i( sy-tabix )
                                                 min  = 20
                                                 max = 30
                                                 ).
o_humid_randomer = cl_abap_random_int=>create(
                                                 seed = CONV i( sy-uzeit )
                                                 min  = 50
                                                 max = 65
                                                 ).

"add some more values in the regular range that dont procude errors
DO datasets2 TIMES.
  error = 0.

  random_temp = o_temp_randomer->get_next( ).
  random_humid = o_humid_randomer->get_next( ).

  IF random_temp NOT BETWEEN 15 AND 30.
    error = 1.
  ENDIF.

  IF random_humid NOT BETWEEN 40 AND 70.
    error = 1.
  ENDIF.

  IF error EQ 1.
    ADD 1 TO error_count.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZPINGID'
    IMPORTING
      number      = pingid.

  ls_senslog = VALUE #(
    id = pingid
    sensorid = 'SMART1'
    timestamp = ts
    value1 = random_temp
    value2 = random_humid
    error = error
  ).

  INSERT ztsensorlog FROM ls_senslog.

  ADD 10 TO ts.

ENDDO.

DATA(datasets) = datasets1 + datasets2.
error_prozent = ( error_count / datasets ) * 100.

WRITE: '% '  && error_prozent.
