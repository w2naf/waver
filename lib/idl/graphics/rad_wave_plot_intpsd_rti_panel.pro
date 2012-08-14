PRO RAD_WAVE_PLOT_INTPSD_RTI_PANEL,xmaps,ymaps,xmap,ymap        $
    ,YTITLE             = yTitle                                $
    ,YRANGE             = yrange                                $   
    ,DATE               = _date                                 $   
    ,TIME               = _time                                 $   
    ,LONG               = long                                  $   
    ,JULS               = juls                                  $   
    ,BEAM               = beam                                  $   
    ,EXCLUDE            = exclude                               $   
    ,SCALE              = scale                                 $   
    ,DBSCALE            = dbScale                               $   
    ,BAR                = bar                                   $
    ,WITH_INFO          = with_info                             $
    ,FIRST              = first                                 $
    ,LAST               = last                                  $
    ,COORDS             = coords                                $
    ,CHARSIZE           = charSize                              $
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
IF ~KEYWORD_SET(radar)          THEN RADAR              = wave_dataproc_info.radar
IF ~KEYWORD_SET(beam)           THEN BEAM               = 0 
IF ~KEYWORD_SET(param)          THEN PARAM              = wave_dataproc_info.param
IF ~KEYWORD_SET(winLen)         THEN WINLEN             = wave_dataproc_info.winLen
IF ~KEYWORD_SET(stepLen)        THEN STEPLEN            = wave_dataproc_info.stepLen
IF ~KEYWORD_SET(bandLim)        THEN BANDLIM            = wave_dataproc_info.bandLim
IF ~KEYWORD_SET(max_offTime)    THEN max_offTime        = wave_dataproc_info.max_offTime
IF ~KEYWORD_SET(interp)         THEN INTERP             = wave_dataproc_info.interp
IF ~KEYWORD_SET(detrend)        THEN DETREND            = wave_dataproc_info.detrend
IF ~KEYWORD_SET(no_hanning)     THEN NO_HANNING         = wave_dataproc_info.no_hanning
IF ~KEYWORD_SET(min_onTime)     THEN MIN_ONTIME         = wave_dataproc_info.min_onTime
IF ~KEYWORD_SET(exclude)        THEN EXCLUDE            = wave_dataproc_info.exclude
;IF ~KEYWORD_SET(scale)          THEN SCALE              = wave_dataproc_info.scale
IF ~KEYWORD_SET(dbScale)        THEN DBSCALE            = wave_dataproc_info.dbScale
IF ~KEYWORD_SET(verbose)        THEN VERBOSE            = wave_dataproc_info.verbose
IF ~KEYWORD_SET(filter)         THEN filter             = wave_dataproc_info.filtered
;IF ~KEYWORD_SET(ajground)       THEN ajground           = wave_dataproc_info.ajground

waveRTI         = TRANSPOSE(REFORM(wave_intpsd_data.intPwrRtiArr[*,beam,*]))
waveRTIjulVec   = wave_intpsd_data.intPwrRtiJulVec


; Set up yAxis for different coordinate systems. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
nGates          = N_ELEMENTS(waveRTI[*,0])
nBeams          = N_ELEMENTS(wave_intpsd_data.intPwrRtiArr[0,*,0])

yAxis           = INDGEN(nGates+1)

IF ~KEYWORD_SET(coords) THEN coords = GET_COORDINATES()

IF ~IS_VALID_COORD_SYSTEM(coords) THEN BEGIN
        PRINFO, 'Not a valid coordinate system: '+coords
        PRINFO, 'Using gate.'
        coords = 'gate'
ENDIF

IF coords NE 'gate' THEN BEGIN
    smsepArr    = REFORM(wave_intpsd_data.intPwrRTIsmsep)
    lagfrArr    = REFORM(wave_intpsd_data.intPwrRTIlagfr)

    timeInx         = WHERE(waveRtiJulVec GE juls[0],cnt)
    IF cnt NE 0 THEN BEGIN
        sJul    = waveRTIJulVec[timeInx[0]]
        CALDAT,sJul, mm, dd, year
        yrsec   = (sJul-julday(1,1,year,0,0,0))*86400.d
        RAD_DEFINE_BEAMS, wave_dataproc_info.id, nBeams, nGates, year, yrsec                    $
            ,COORDS             = coords                                                        $
            ,LAGFR0             = lagfrArr[timeInx[0]]                                          $
            ,SMSEP0             = smsepArr[timeInx[0]]                                          $
            ,FOV_LOC_FULL       = fov_loc_full                                                  $
            ,FOV_LOC_CENTER     = fov_loc_center, /NORMAL
        yAxis   = REFORM(FOV_LOC_CENTER[0,beam,*])

        yInx    = WHERE(FINITE(yAxis),NCOMPLEMENT=nBadYinx)
        IF (yInx[0] NE -1) AND nBadYinx NE 0 THEN BEGIN
            yAxis       = yAxis[yInx]
            waveRTI     = waveRTI[yInx[1:*],*]
        ENDIF
    ENDIF
ENDIF           

IF ~KEYWORD_SET(yTitle) THEN _yTitle = GET_DEFAULT_TITLE(coords) ELSE _yTitle = yTitle
IF  KEYWORD_SET(yRange) THEN _yrange = yRange
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IF KEYWORD_SET(dbScale) THEN BEGIN
    waveRTI         =   10 * ALOG10(waveRTI)
    IF ~KEYWORD_SET(scale) THEN scale = [-35.,0.]
ENDIF ELSE BEGIN
    IF ~KEYWORD_SET(scale) THEN scale = [MIN(waveRTI,/NAN),MAX(waveRTI,/NAN)]
ENDELSE

IF N_PARAMS() NE 4 THEN BEGIN
    posit = DEFINE_PANEL(1,1,0,0,BAR=bar,WITH_INFO=with_info)
ENDIF ELSE BEGIN
    posit = DEFINE_PANEL(xmaps,ymaps,xmap,ymap,BAR=bar,WITH_INFO=with_info)
ENDELSE

date$           = TIME_STRING(JUL2EPOCH(juls[0]),TFORMAT='DD-MTH-YYYY')

timeAxis        = [waveRTIjulVec, MAX(waveRTIjulVec)+waveRTIjulVec[1]-waveRTIjulVec[0]]

IF ~KEYWORD_SET(xticks) THEN xticks = GET_XTICKS(juls[0], juls[1], XMINOR=_xminor)

image   = GET_COLOR_INDEX(waveRTI,COLORSTEPS=GET_NCOLORS(),SCALE=scale,PARAM='power',/NAN)
image   = TRANSPOSE(REFORM(image,SIZE(waveRTI,/DIMENSIONS)))

_xTitle         = 'Time (UT) - '+date$
_xTickFormat    = 'LABEL_DATE'

fmt = get_format(sardines=sd, tokyo=ty)
if sd and ~keyword_set(last) then begin
        if ~keyword_set(xtitle) then $
                _xtitle = ' ' 
        if ~keyword_set(xtickformat) then $
                _xtickformat = ''
        if ~keyword_set(xtickname) then $
                _xtickname = replicate(' ', 60) 
endif
if ty and ~keyword_set(first) then begin
        if ~keyword_set(ytitle) then $
                _ytitle = ' ' 
        if ~keyword_set(ytickformat) then $
                _ytickformat = ''
        if ~keyword_set(ytickname) then $
                _ytickname = replicate(' ', 60) 
endif

DRAW_IMAGE,image,timeAxis,yAxis                                         $
        ,POSITION       =       posit                                   $
        ,/NO_SCALE                                                      $
        ,XTITLE         =       _xTitle                                 $
        ,XTICKFORMAT    =       _xTickFormat                            $
        ,XTICKNAME      =       _xTickName                              $
        ,XMINOR         =       _xminor                                 $
        ,XTICKS         =       xticks                                  $
        ,XSTYLE         =       1                                       $
        ,XRANGE         =       juls                                    $
        ,YTITLE         =       _yTitle                                 $
        ,YTICKFORMAT    =       _ytickformat                            $
        ,YTICKNAME      =       _ytickname                              $
        ,YSTYLE         =       ystyle                                  $
        ,YTICKS         =       yticks                                  $
        ,YRANGE         =       _yRange                                 $
        ,TITLE          =       title                                   $
        ,CHARTHICK      =       charthick                               $
        ,CHARSIZE       =       charsize                                $
        ,COLOR          =       get_foreground()
END
