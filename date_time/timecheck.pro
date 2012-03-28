PRO TIMECHECK,date,time,juls,sjul,fjul,LONG=long

IF ~KEYWORD_SET(long) THEN long = 0

IF ~KEYWORD_SET(juls)   THEN BEGIN
    date        = GET_DATE(date)
    time        = GET_TIME(time)
    IF date[0] NE -1    THEN BEGIN
        SFJUL,date,time,sjul,fjul,LONG=long,/DATE_TO_JUL
        juls    = [sjul, fjul]
    ENDIF
ENDIF ELSE BEGIN
    IF N_ELEMENTS(juls) EQ 1 THEN BEGIN
        date    = REPLICATE(LONG(FORMAT_JULDATE(juls,/SHORT_DATE)),2)
        time    = [0000, 2400]
    ENDIF ELSE BEGIN
        sjul    = jul[0]
        fjul    = jul[1]
        SFJUL,date,time,sjul,fjul,LONG=long,/JUL_TO_DATE
    ENDELSE
ENDELSE

END
