FUNCTION GET_DATE,date,SILENT=silent
COMMON rad_data_blk

IF ~KEYWORD_SET(date) THEN BEGIN
    data_index = RAD_FIT_GET_DATA_INDEX()
    IF data_index NE -1 THEN BEGIN
        IF ~KEYWORD_SET(silent) THEN        $
                prinfo, 'No DATE given, trying for scan date.'

        CALDAT, (*rad_fit_info[data_index]).sjul, month, day, year
        date0 = year*10000L + month*100L + day 

        CALDAT, (*rad_fit_info[data_index]).fjul, month, day, year
        date1 = year*10000L + month*100L + day 

        date  = [date0, date1]
    ENDIF ELSE BEGIN
        IF ~KEYWORD_SET(silent) THEN        $
                PRINFO, 'ERROR: No DATE specified or currently loaded.'
        date = -1
    ENDELSE
ENDIF

IF (N_ELEMENTS(date) EQ 1) AND (date[0] NE -1) THEN date = REPLICATE(date,2)

RETURN,date
END
