;+
; NAME:
; date2yrYrsec
;
; PURPOSE:
;
; Calculates the year and seconds from the beginning of the year for a given date/time.
; If no time is given, time = 0000 is assumed. 
;
; INPUTS:
; DATE: A vector giving the dates to be converted, in YYYYMMDD format.
;
; TIME: A vector giving the time to be converted, in HHII format.
;
; KEYWORD PARAMETERS:
; LONG: Set this keyword to indicate that the TIME value is in HHIISS format
; rather than HHII format.
;
; OUTPUTS: 
; A 2 x nDates vector containing the year and yrsec values is returned.
;
; MODIFICATION HISTORY:
; Written by Nathaniel Frissell, March 6, 2012
;-
FUNCTION DATE2YRYRSEC,date,time,LONG=long

IF ~KEYWORD_SET(date) THEN BEGIN
    PRINFO,'Error: No date set.'
    RETURN,-1
ENDIF

IF KEYWORD_SET(time) THEN BEGIN
    IF N_ELEMENTS(time) NE N_ELEMENTS(date) THEN BEGIN
        PRINFO,'Input number of times and dates do not match.  Fix it!'
        RETURN,-1
    ENDIF
ENDIF
        
nDates          = N_ELEMENTS(date)
result          = DBLARR(2,nDates)

IF ~KEYWORD_SET(time) THEN time = INTARR(ndates)

FOR kk=0,nDates-1 DO BEGIN
    jul                 = CALC_JUL(date[kk],time[kk],LONG=long)

    CALDAT,jul,month,day,year,hour,min,sec
    jul0                = JULDAY(year,01,01,00,00,00)
    yrsec               = (jul - jul0) * 86400.

    result[0,kk]        = year
    result[1,kk]        = yrSec
ENDFOR

RETURN,REFORM(result)
END
