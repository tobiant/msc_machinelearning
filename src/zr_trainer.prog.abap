*&---------------------------------------------------------------------*
*& Report ZR_TRAINER
*&---------------------------------------------------------------------*
*& Evaluate
*&---------------------------------------------------------------------*
REPORT zr_trainer.

DATA(o_logreg) = NEW zcl_logreg(
  i_arbpl         = 'SMART1'
  i_bias          = 0
  i_iteration     = 1000
  i_learning_rate = '0.001'
  i_weights       = VALUE #( value1 = 0 value2 = 0 )
  i_predictors    = 2
  i_sample_size   = 700 "2/3 of dataset
).

o_logreg->init( ).

DO o_logreg->get_iteration( ) TIMES.
  o_logreg->calc_y_hat( ).
  o_logreg->transpose( ).
  o_logreg->derivate( ).
ENDDO.

o_logreg->evaluate( ).

"update sensordb with weights an biases
DATA(arbpl) = o_logreg->get_arbpl(  ).
SELECT * FROM ztsensors
WHERE machine EQ @arbpl
INTO TABLE @DATA(t_sensors).
t_sensors[ 1 ]-weight =  o_logreg->get_s_w( )-value1.
t_sensors[ 2 ]-weight =  o_logreg->get_s_w( )-value2.
LOOP AT t_sensors REFERENCE INTO DATA(sensor).
  sensor->bias = o_logreg->get_bias( ).
ENDLOOP.
UPDATE ztsensors FROM TABLE t_sensors.

WRITE 'bias:'.
SKIP.
WRITE o_logreg->get_bias( ).
SKIP.
SKIP.
WRITE: 'weights:'.
SKIP.
WRITE: o_logreg->get_s_w( )-value1, o_logreg->get_s_w( )-value2.
