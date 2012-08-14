PRO RAD_WAVE_PLOT_PREFFT_RTI                                    $   
    ,YRANGE             = yRange                                $
    ,DATE               = _date                                 $   
    ,TIME               = _time                                 $   
    ,LONG               = long                                  $   
    ,JULS               = juls                                  $   
    ,BEAM               = beam                                  $   
    ,EXCLUDE            = exclude                               $   
    ,SCALE              = scale                                 $   
    ,DBSCALE            = dbScale                               $   
    ,VERBOSE            = verbose

COMMON WAVE_BLK
IF KEYWORD_SET(juls) THEN BEGIN
    SFJUL,date,time,juls[0],juls[1],/JUL_TO_DATE
ENDIF
IF KEYWORD_SET(_date) THEN BEGIN
    IF ~KEYWORD_SET(_time) THEN _time = [0000, 2400]
    juls        = DBLARR(2)
    SFJUL,_date,_time,juls[0],juls[1]
    date    = _date
    time    = _time
ENDIF
 
IF ~KEYWORD_SET(date)           THEN DATE               = wave_dataproc_info.date
IF ~KEYWORD_SET(time)           THEN TIME               = wave_dataproc_info.time
IF ~KEYWORD_SET(long)           THEN LONG               = wave_dataproc_info.long
IF ~KEYWORD_SET(juls)           THEN JULS               = wave_dataproc_info.juls
IF ~KEYWORD_SET(beam)           THEN BEAM               = 0 
IF ~KEYWORD_SET(winLen)         THEN WINLEN             = wave_dataproc_info.winLen
IF ~KEYWORD_SET(stepLen)        THEN STEPLEN            = wave_dataproc_info.stepLen
IF ~KEYWORD_SET(bandLim)        THEN BANDLIM            = wave_dataproc_info.bandLim
IF ~KEYWORD_SET(max_offTime)    THEN max_offTime        = wave_dataproc_info.max_offTime
IF ~KEYWORD_SET(interp)         THEN INTERP             = wave_dataproc_info.interp
IF ~KEYWORD_SET(detrend)        THEN DETREND            = wave_dataproc_info.detrend
IF ~KEYWORD_SET(no_hanning)     THEN NO_HANNING         = wave_dataproc_info.no_hanning
IF ~KEYWORD_SET(min_onTime)     THEN MIN_ONTIME         = wave_dataproc_info.min_onTime
IF ~KEYWORD_SET(exclude)        THEN EXCLUDE            = wave_dataproc_info.exclude
IF ~KEYWORD_SET(scale)          THEN SCALE              = wave_dataproc_info.scale
IF ~KEYWORD_SET(dbScale)        THEN DBSCALE            = wave_dataproc_info.dbScale
IF ~KEYWORD_SET(verbose)        THEN VERBOSE            = wave_dataproc_info.verbose
IF ~KEYWORD_SET(filter)         THEN filter             = wave_dataproc_info.filtered

CLEAR_PAGE,/NEXT

RAD_WAVE_PLOT_TITLE,1,1,0,0                                             $
        ,CHARTHICK              = charthick                             $
        ,CHARSIZE               = charsize                              $
        ,BEAM                   = beam                                  $
        ,/PARAM_INFO                                                    $
        ,/NO_GATE                                                       $
        ,/BAR

title$    = 'Pre-FFT RTI Plot'
subtitle$ = 'MaxOff: '          + SECSTR(max_offTime)                           $ 
          + ', MinOn: '         + SECSTR(min_onTime)                            $
          + ', Exclude: ['+ NUMSTR(exclude[0])+', '+NUMSTR(exclude[1])+']'      $
          + ',!CIntrp: '         + SECSTR(interp)                               $   
          + ', Win: ' + SECSTR(winLen)

PLOT_TITLE,title$,subtitle$

RAD_WAVE_PLOT_PREFFT_RTI_COLORBAR,1,1,0,0                               $
    ,BEAM               = beam                                          $
    ,SCALE              = scale

RAD_WAVE_PLOT_PREFFT_RTI_PANEL,1,1,0,0                                  $
    ,YRANGE             = yRange                                        $
    ,JULS               = juls                                          $
    ,BEAM               = beam                                          $
    ,EXCLUDE            = exclude                                       $
    ,SCALE              = scale                                         $
    ,VERBOSE            = verbose                                       $
    ,/FIRST,/LAST,/BAR

END
