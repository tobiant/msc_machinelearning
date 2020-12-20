*&---------------------------------------------------------------------*
*& Report zr_makeprediction
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zr_makeprediction.

DATA(o_logreg) = NEW zcl_logreg(
  i_arbpl         = 'SMART1'
).

DATA eins TYPE decfloat34 VALUE 10.
DATA zwei TYPE decfloat34 VALUE 90.

o_logreg->init(
    i_values = VALUE #( value1 = eins value2 = zwei )
).
DATA(new_y_hat) = o_logreg->calc_y_hat(  ).

"results
WRITE 'new y hat'.
SKIP.
WRITE new_y_hat.
