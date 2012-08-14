FUNCTION GET_RADAR,radar,SILENT=silent
COMMON rad_data_blk

IF ~KEYWORD_SET(radar) THEN BEGIN
    data_index = RAD_FIT_GET_DATA_INDEX()
    IF data_index NE -1 THEN BEGIN
        IF ~KEYWORD_SET(silent) THEN        $
            PRINFO, 'No RADAR given, trying for currently loaded radar.'
        radar       = (*rad_fit_info[data_index]).code
    ENDIF ELSE BEGIN
        IF ~KEYWORD_SET(silent) THEN        $
                PRINFO, 'ERROR: No RADAR specified or currently loaded.'
        radar = -1
    ENDELSE
ENDIF

RETURN,radar
END
