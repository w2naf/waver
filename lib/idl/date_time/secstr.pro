FUNCTION SECSTR,seconds

IF seconds LE 120.      THEN BEGIN
    val         = seconds
    unit$       = 's'
    output$     = NUMSTR(val,1) + ' ' + unit$
    RETURN,output$
ENDIF

IF seconds LE 3600.     THEN BEGIN
    val         = seconds / 60.
    unit$       = 'min'
    output$     = NUMSTR(val,1) + ' ' + unit$
    RETURN,output$
ENDIF

IF seconds LE 86400.    THEN BEGIN
    val         = seconds / 3600.
    unit$       = 'hr'
    output$     = NUMSTR(val,1) + ' ' + unit$
    RETURN,output$
ENDIF

val         = seconds / 86400.
unit$       = 'days'
output$     = NUMSTR(val,1) + ' ' + unit$
RETURN,output$
END
