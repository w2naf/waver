FUNCTION GET_TIME,time,SILENT=silent
COMMON rad_data_blk

IF ~KEYWORD_SET(time) THEN BEGIN
    data_index = RAD_FIT_GET_DATA_INDEX()
    IF data_index NE -1 THEN BEGIN
        IF ~KEYWORD_SET(silent) THEN        $
            prinfo, 'No TIME given, trying for scan time.'
        caldat, (*rad_fit_info[data_index]).sjul, mm, dd, yy, shh, sii
        caldat, (*rad_fit_info[data_index]).fjul, mm, dd, yy, fhh, fii
        time = [shh*100, ( (fhh+( fii lt 10 ? 0 : 1 )) < 24 )*100]
    ENDIF ELSE BEGIN
        IF ~KEYWORD_SET(silent) THEN        $
            prinfo, 'WARNING: No TIME specified or loaded.  Settin time to [0000,2400].'
        time = [0000, 2400]
    ENDELSE
ENDIF

IF (N_ELEMENTS(time) EQ 1) THEN time = [time, time]

RETURN,time
END
