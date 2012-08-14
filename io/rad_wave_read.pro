PRO RAD_WAVE_READ,date,radar                                    $
    ,PARAM              = param                                 $
    ,BANDLIM            = bandLim                               $
    ,DIR                = _dir                                  $
    ,FILENAME           = fileName                              $
    ,VERBOSE            = verbose                               $
    ,DYNFFT_ONLY        = dynfft_only                           $
    ,INTPSD_ONLY        = intpsd_only                           $
    ,FTEST              = fTest                                 $
    ,WRITE              = write

COMMON WAVE_BLK

IF N_ELEMENTS(fTest) NE 0 THEN s = TEMPORARY(fTest)

IF ~KEYWORD_SET(fileName) THEN BEGIN
    IF KEYWORD_SET(_dir) THEN dir = _dir ELSE dir = 'psdsav/'

    fileName        = NUMSTR(date[0]) + '.'                                            $   
                    + radar + '.'                                                      $   
                    + param + '.'                                                      $   
                    + NUMSTR(1E6*bandLim[0]) + '-' + NUMSTR(1E6*bandLim[1])
                   

    fileName        = dir + fileName
ENDIF

IF ~KEYWORD_SET(write) THEN BEGIN
    IF ~KEYWORD_SET(dynfft_only) THEN BEGIN
        suffix      = '.intpsd.sav'
        fTest           = FILE_TEST(fileName+suffix)
        IF fTest THEN BEGIN
            PRINFO,'Reading ' + fileName+suffix
            RESTORE,fileName+suffix,VERBOSE=verbose
        ENDIF ELSE BEGIN
            PRINFO,'ERROR! Missing file: ' + fileName+suffix
            RETURN
        ENDELSE
    ENDIF

    IF ~KEYWORD_SET(intpsd_only) THEN BEGIN
        suffix      = '.rawtsr.sav'
        fTest           = FILE_TEST(fileName+suffix)
        IF fTest THEN BEGIN
            PRINFO,'Reading ' + fileName+suffix
            RESTORE,fileName+suffix,VERBOSE=verbose
        ENDIF ELSE BEGIN
            PRINFO,'ERROR! Missing file: ' + fileName+suffix
            RETURN
        ENDELSE

        suffix      = '.dynfft.sav'
        fTest           = FILE_TEST(fileName+suffix)
        IF fTest THEN BEGIN
            PRINFO,'Reading ' + fileName+suffix
            RESTORE,fileName+suffix,VERBOSE=verbose
        ENDIF ELSE BEGIN
            PRINFO,'ERROR! Missing file: ' + fileName+suffix
            RETURN
        ENDELSE
    ENDIF
    fileName    = fileName+suffix
    RETURN
ENDIF ELSE BEGIN
    IF ~FILE_TEST(dir,/DIRECTORY) THEN FILE_MKDIR,dir
    suffix      = '.rawtsr.sav'
    SAVE                                                        $
        ,wave_dataproc_info                                     $
        ,WAVE_rawtsr_data                                       $
        ,FILENAME               = fileName + suffix

    suffix      = '.dynfft.sav'
    SAVE                                                        $
        ,wave_dataproc_info                                     $
        ,WAVE_dynfft_data                                       $
        ,FILENAME               = fileName + suffix

    suffix      = '.intpsd.sav'
    SAVE                                                        $
        ,wave_dataproc_info                                     $
        ,WAVE_intpsd_data                                       $
        ,FILENAME               = fileName + suffix

    FILENAME               = fileName + suffix
ENDELSE
END
