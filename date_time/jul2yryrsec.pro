;+
; NAME:
; JUL2YRYRSEC
;
; PURPOSE:
;
; Calculates the year and seconds from the beginning of the year for given Julian Dates.
;
; INPUTS:
; JULS: A vector giving the Julian dates to be converted.
;
; OUTPUTS: 
; A 2 x nDates vector containing the year and yrsec values is returned.
;
; MODIFICATION HISTORY:
; Written by Nathaniel Frissell, March 6, 2012
;-
FUNCTION JUL2YRYRSEC,juls

IF ~KEYWORD_SET(juls) THEN BEGIN
    PRINFO,'Error: No input Julian date set.'
    RETURN,-1
ENDIF

nDates          = N_ELEMENTS(juls)
result          = DBLARR(2,nDates)

FOR kk=0,nDates-1 DO BEGIN
    CALDAT,juls[kk],month,day,year,hour,min,sec
    jul0                = JULDAY(year,01,01,00,00,00)
    yrsec               = (juls[kk] - jul0) * 86400.

    result[0,kk]        = year
    result[1,kk]        = yrSec
ENDFOR

RETURN,REFORM(result)
END
