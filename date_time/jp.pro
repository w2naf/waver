;JULPRINT
PRO JP,juls_in,TRANSPOSE=transpose
out$    = JUL2STRING(juls_in)
IF KEYWORD_SET(transpose) THEN out$ = TRANSPOSE(out$)
PRINT,out$
END
