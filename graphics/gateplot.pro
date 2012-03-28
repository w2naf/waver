PRO GATEPLOT,dataStruct_in                                      $
    ,WINDOWDATE         = windowDate                            $
    ,WINDOWTIME         = windowTime                            $
    ,WINDOWJULS         = windowJuls                            $
    ,GATES              = gates                                 $
    ,DATE               = date                                  $   
    ,TIME               = time                                  $   
    ,LONG               = long                                  $   
    ,JULS               = juls                                  $   
    ,RADAR              = radar                                 $   
    ,BEAM               = beam                                  $   
    ,PARAM              = param                                 $   
    ,WINLEN             = winLen                                $   
    ,STEPLEN            = stepLen                               $   
    ,BANDLIM            = bandLim                               $   
    ,INTERP             = interp                                $   
    ,DETREND            = detrend                               $   
    ,NO_HANNING         = no_hanning                            $   
    ,MAX_OFFTIME        = max_offTime                           $   
    ,MIN_ONTIME         = min_onTime                            $   
    ,EXCLUDE            = exclude                               $
    ,SCALE              = scale                                 $
    ,DBSCALE            = dbScale                               $   
    ,REALLY_RAW         = really_raw                            $
    ,VERBOSE            = verbose

COMMON rad_data_blk
COMMON WAVE_BLK

plotCharSize            = 0.75
bar                     = 0

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
IF ~KEYWORD_SET(scale)          THEN SCALE              = wave_dataproc_info.scale
IF ~KEYWORD_SET(dbScale)        THEN DBSCALE            = wave_dataproc_info.dbScale
IF ~KEYWORD_SET(verbose)        THEN VERBOSE            = wave_dataproc_info.verbose
IF ~KEYWORD_SET(filter)         THEN filter             = wave_dataproc_info.filtered
;IF ~KEYWORD_SET(ajground)       THEN ajground           = wave_dataproc_info.ajground

IF ~KEYWORD_SET(windowDate) AND ~KEYWORD_SET(windowTime) AND ~KEYWORD_SET(windowJuls)   $
    THEN windowJuls = [juls[0],juls[0]]

TIMECHECK,windowDate,windowTime,windowJuls,windowSJul,windowFJul,LONG=long

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
NaN             = !VALUES.F_NAN
red             = 253
green           = 144
blue            = 32
orange          = 208
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SET_PARAMETER,param
RAD_SET_BEAM,beam

SFJUL, date, time, sjul, fjul

IF ~KEYWORD_SET(gates) THEN BEGIN
    maxGates    = N_ELEMENTS(wave_dynfft_data.windowedTSR[0,0,0,*])
    startGate   = 0
    endGate     = maxGates - 1
ENDIF ELSE BEGIN
    IF N_ELEMENTS(gates) EQ 1 THEN gates = REPLICATE(gates,2)
    maxGates    = gates[1] - gates[0] + 1
    startGate   = gates[0]
    endGate     = gates[1]
ENDELSE

halfWinLenDays  = 0.5*winLen / 86400D 
gplTimeJul      = halfWinLenDays*[-1.,1.] + windowSJul
sfjul,gpldate,gpltime,gplTimeJul[0],gplTimeJul[1],/JUL_TO_DATE
xTicks          = GET_XTICKS(gplTimeJul[0],gplTimeJul[1])

;Plotting variables that don't need to be in the loop.
title$    = 'TSR and FFT Plot'
subtitle$ = 'MaxOff: '          + SECSTR(max_offTime)                           $
          + ', MinOn: '         + SECSTR(min_onTime)                            $
          + ', Exclude: ['+ NUMSTR(exclude[0])+', '+NUMSTR(exclude[1])+']'      $
          + ',!CIntrp: '        + SECSTR(interp)                                $
          + ', Win: '           + SECSTR(winLen)
bl$       = NUMSTR(bandLim*1000.,1)

;Start plotting and calculation loop.
FOR gk = startGate,endGate DO BEGIN
;    ;Recover offTimes from WAVE_offTimes
;    offTimesInx = WHERE(WAVE_offTimes[*,0] EQ beam AND WAVE_offTimes[*,1] EQ gk,offCnt)
;    IF offCnt GT 0 THEN BEGIN
;        offTimes        = DBLARR(offCnt,2)
;        offTimes[*,0]   = WAVE_offTimes[offTimesInx,2]
;        offTimes[*,1]   = WAVE_offTimes[offTimesInx,3]
;    ENDIF ELSE offTimes = -1
;
;
;    onTimesInx  = WHERE(WAVE_onTimes[*,0] EQ beam AND WAVE_onTimes[*,1] EQ gk,onCnt)
;    IF onCnt GT 0 THEN BEGIN
;        onTimes        = DBLARR(onCnt,2)
;        onTimes[*,0]   = WAVE_onTimes[onTimesInx,2]
;        onTimes[*,1]   = WAVE_onTimes[onTimesInx,3]
;    ENDIF ELSE onTimes = -1

    RAD_SET_GATE,gk
    IF KEYWORD_SET(verbose) THEN PRINFO,'Gate: ' + NUMSTR(gk)

    winInx  = CLOSEST(windowSJul,wave_dynfft_data.juls)
    IF ~FINITE(winInx) THEN BEGIN
        PRINFO,'Error!!!! No close by time window!!!'
        PRINT,'Center of window chosen: ' + JUL2STRING(windowSJul)
        PRINT,'Time range available:    ' + JUL2STRING(wave_dynfft_data.juls[0])      $
              +' - '+ JUL2STRING(wave_dynfft_data.juls[N_ELEMENTS(wave_dynfft_data.juls)-1])
        STOP
        CONTINUE
    ENDIF

    CLEAR_PAGE,/NEXT
    RAD_WAVE_PLOT_TITLE,1,1,0,0                                         $ 
        ,CHARTHICK      = charthick                                     $
        ,CHARSIZE       = charsize                                      $
        ,PARAMETER      = param                                         $
        ,/PARAM_INFO                                                    $
        ,BEAM           = beam                                          $
        ,BAR            = bar

    PLOT_TITLE,title$,subtitle$

    julAxis     = wave_dynfft_data.windowedTSR_deltaDays + wave_dynfft_data.juls[winInx]
    winData     = wave_dynfft_data.windowedTSR[winInx,*,beam,gk] 
    frqAxis     = wave_dynfft_data.freq
    fftData     = wave_dynfft_data.fft[winInx,*,beam,gk]

    blInx       = WHERE((frqAxis GE bandLim[0]) * (frqAxis LE bandLim[1]))
    df          = frqAxis[1] - frqAxis[0]
    psd         = fftData^2

    ;Really raw pulls things right out of the DaViT RAD_FIT_DATA block, but values
    ;above 10000 are still excluded.
    ;Otherwise, the "raw" data comes from data that was loaded earlier by the wave search
    ;routines (in the wave_dynfft structure from the WAVE_BLK common block).  This data
    ;has had everything outside of the exclude set to NaN.
    IF KEYWORD_SET(really_raw) THEN BEGIN
        RAD_FIT_READ,date,radar,TIME=time,FILTER=filter;,AJGROUND=ajground
        dataInx     = RAD_FIT_GET_DATA_INDEX()
        beamInx     = WHERE((*RAD_FIT_DATA[dataInx]).beam EQ beam)
        rawTime     = (*RAD_FIT_DATA[dataInx]).juls[beamInx]
        rawData     = (*RAD_FIT_DATA[dataInx]).power[beamInx,gk]
        goodInx     = WHERE(rawData LT 10000,cnt)
        IF cnt GT 0 THEN BEGIN
            rawTime     = rawTime[goodInx]
            rawData     = rawData[goodInx]
        ENDIF ELSE rawData = rawData * 0.
    ENDIF ELSE BEGIN
        rawInx      = WHERE(*wave_rawtsr_data[beam].rawtsr_juls GE julAxis[0]                   $
                        AND *wave_rawtsr_data[beam].rawtsr_juls LE julAxis[N_ELEMENTS(julAxis)-1])
        rawtime     = *wave_rawtsr_data[beam].rawtsr_juls
        rawtime     = rawtime[rawInx]
        rawData     = *wave_rawtsr_data[beam].rawTSR
        rawData     = rawData[rawInx,gk]

;        rawInx      = WHERE(wave_dynfft_data.rawtsr_juls[*,beam] GE julAxis[0]               $
;                        AND wave_dynfft_data.rawtsr_juls[*,beam] LE julAxis[N_ELEMENTS(julAxis)-1])
;        rawtime     = wave_dynfft_data.rawtsr_juls[rawInx,beam]
;        rawData     = wave_dynfft_data.rawTSR[rawInx,beam,gk]
    ENDELSE
    nanInx      = WHERE(~FINITE(rawData))

    IF MAX(winData,/NAN) GT MAX(rawData,/NAN) THEN yMax = MAX(winData,/NAN) ELSE yMax = MAX(rawData,/NAN)
    IF MIN(winData,/NAN) LT MIN(rawData,/NAN) THEN yMin = MIN(winData,/NAN) ELSE yMin = MIN(rawData,/NAN)
    ys          = 1.1
    yMin        = ys * yMin
    yMax        = ys * yMax

    IF ~FINITE(yMin) AND ~FINITE(ymax) THEN BEGIN
        yMin    = -5
        yMax    = 5
    ENDIF

    IF yMin EQ yMax THEN BEGIN
        yMin    = yMax - 0.2*ABS(yMax)
        yMax    = yMax + 0.2*ABS(yMax)
    ENDIF

    IF yMin GE 0 THEN yMin = -5
    IF yMax LE 0 THEN yMax = 5

; Plot time series data.
    posit       = DEFINE_PANEL(1,2,0,0,BAR=bar)
    yTitle$     = GET_DEFAULT_TITLE(param)
    PLOT,julAxis,julAxis*0                                              $
        ,/NODATA                                                        $
        ,CHARSIZE       = plotCharSize                                  $
        ,XTITLE         = 'Time [UT] - Start: '+JUL2STRING(julAxis[0])  $
        ;,YTITLE         = TEXTOIDL('Velocity [m s^{-1}]')               $
        ,YTITLE         = yTitle$                                       $
        ,XRANGE         = gplTimeJul                                    $
        ,YRANGE         = [yMin, yMax]                                  $
        ;,YRANGE         = scale                                         $
        ,XSTYLE         = 1                                             $
        ,YSTYLE         = 1                                             $
        ,XTICKS         = xTicks                                        $
        ,XTICKFORMAT    = 'LABEL_DATE'                                  $
        ,POSITION       = posit

    ;Plot reference sine waves.
    IF ABS(!Y.CRANGE[0]) LT ABS(!Y.CRANGE[1]) THEN sinAmpl = !Y.CRANGE[0] $
        ELSE sinAmpl = !Y.CRANGE[1]
    sinAmpl0            = 0.50 * sinAmpl
    sinLineStyle0       = 0
    sinThick0           = 2
    sinColor0           = green
    OPLOT,julAxis,sinAmpl0*SIN(2*!PI*bandLim[0]*86400.*julAxis)         $
        ,COLOR          = sinColor0                                     $
        ,LINESTYLE      = sinLineStyle0                                 $
        ,THICK          = sinThick0

    sinAmpl1            = 0.50 * sinAmpl0
    sinLineStyle1       = 0
    sinThick1           = 0
    sinColor1           = orange
    OPLOT,julAxis,sinAmpl1*SIN(2*!PI*bandLim[1]*86400.*julAxis)         $
        ,COLOR          = sinColor1                                     $
        ,LINESTYLE      = sinLineStyle1                                 $
        ,THICK          = sinThick1

    ;Plot the status of whether a data period was accepted or rejected.
    statusThick = 3 
    nanInx      = WHERE(~FINITE(wave_dynfft_data.preffttsr[*,beam,gk]),COMPLEMENT=goodInx)
    
    offOn       = wave_dynfft_data.preffttsr_juls * 0
    IF goodInx[0] NE -1 THEN offOn[goodInx] = 1

    IF nanInx[0] NE -1 THEN BEGIN
        OPLOT,wave_dynfft_data.preffttsr_juls[nanInx]                   $
             ,!Y.CRANGE[0]+0*wave_dynfft_data.preffttsr_juls[nanInx]    $
             ,PSYM              = 6                                     $
             ,THICK             = statusThick                           $
             ,COLOR             = 253
    ENDIF
    IF goodInx[0] NE -1 THEN BEGIN
        OPLOT,wave_dynfft_data.preffttsr_juls[goodInx]                  $
             ,!Y.CRANGE[0]+0*wave_dynfft_data.preffttsr_juls[goodInx]   $
             ,PSYM              = 6                                     $
             ,THICK             = statusThick                           $
             ,COLOR             = 144
    ENDIF
    
    ;Plot raw radar data.
    OPLOT,rawtime,rawdata                                               $
        ,PSYM           = -4                                            $
        ,COLOR          = red                                           $
        ,SYMSIZE        = 0.5                                           $
        ,THICK          = 1

    ;Plot invalid data points.
    IF nanInx[0] NE -1 THEN BEGIN
        OPLOT,rawtime[nanInx],rawtime[nanInx]*0                             $
            ,PSYM           = 4                                             $
            ,COLOR          = blue                                          $
            ,SYMSIZE        = 0.5                                           $
            ,THICK          = 1
    ENDIF

    ;Plot processed data.
    OPLOT,julAxis,winData,PSYM=-4,SYMSIZE=0.25



;    IF offCnt GT 0 THEN BEGIN
;        ;PLOTS,offTimes,0*offTimes+!Y.CRANGE[0],COLOR=253,THICK=statusThick,NOCLIP=0
;        FOR offK=0,offCnt-1 DO BEGIN
;            PLOTS,offTimes[offK,*],REPLICATE(!Y.CRANGE[0],2),COLOR=253,THICK=statusThick,NOCLIP=0
;        ENDFOR
;    ENDIF
;    IF onCnt GT 0 THEN BEGIN
;        ;PLOTS,onTimes,0*onTimes+!Y.CRANGE[0],COLOR=144,THICK=statusThick,NOCLIP=0
;        FOR onK=0,onCnt-1 DO BEGIN
;            PLOTS,onTimes[onK,*],REPLICATE(!Y.CRANGE[0],2),COLOR=144,THICK=statusThick,NOCLIP=0
;        ENDFOR
;    ENDIF
    
;Plot FFT.
;    IF ~KEYWORD_SET(dbScale)    THEN BEGIN
;        unit$   = TEXTOIDL(' [(m s^{-1})^2]')
;        intUnit$= TEXTOIDL(' [(m s^{-1})^2 Hz]')
;    ENDIF ELSE BEGIN
;        unit$   = ' [dB]'
;        intUnit$= ' [Hz dB]'
;    ENDELSE
    
    IF param EQ 'velocity' || param EQ 'width' THEN BEGIN
        unit$   = TEXTOIDL(' [(m s^{-1})^2]')
        intUnit$= TEXTOIDL(' [(m s^{-1})^2 Hz]')
    ENDIF
    IF param EQ 'power' THEN BEGIN
        unit$   = TEXTOIDL(' [(dB)^2]')
        intUnit$= TEXTOIDL(' [(dB)^2 Hz]')
    ENDIF

    posit     = DEFINE_PANEL(1,2,0,1,BAR=bar,/WITH_INFO)
    PLOT,frqAxis*1000.,fftData                                          $
        ,CHARSIZE       = plotCharSize                                  $
        ,PSYM           = -4                                            $
        ,SYMSIZE        = 0.25                                          $
        ,XTITLE         = 'Frequency [mHz]'                             $
        ,YTITLE         = 'S(f)' + unit$                                $
        ,XRANGE         = [0,10]                                        $
        ,XSTYLE         = 1                                             $
        ,YTICKFORMAT    = '(F6.1)'                                      $
        ,POSITION       = posit

OPLOT,bandLim[0]*1000*[1,1],!Y.CRANGE,COLOR=red,LINESTYLE=2,THICK=3
OPLOT,bandLim[1]*1000*[1,1],!Y.CRANGE,COLOR=red,LINESTYLE=2,THICK=3

;The following outputs the bandpass power computed within this routine.  This isn't recommended because it does not show the actual value computed by int_pwr_rti.
;XYOUTS,0.80,0.38,ALIGNMENT=1,/NORMAL,CHARSIZE=0.7                $
;    ,TEXTOIDL('\Sigma_{'+bl$[0]+' mHz}^{'+bl$[1]+' mHz}S(f) = ' + NUMSTR(intPwr[gk],4) + ' mdB')

;intPwr = wave_int_pwr_rti.data[gk,winInx]
intPwr = wave_intpsd_data.intpwrrtiarr[winInx,beam,gk]

IF intPwr LT 0.1 THEN nDec = 5 ELSE nDec = 2
;This line uses the bandpass power computed by int_pwr_rti.
XYOUTS,0.80,0.38,ALIGNMENT=1,/NORMAL,CHARSIZE=0.7                       $
    ,TEXTOIDL('\Sigma_{'+bl$[0]+' mHz}^{'+bl$[1]+' mHz}S(f) = ')        $
    +NUMSTR(intPwr,nDec) + intUnit$
;m s^{-1} Hz')

LINE_LEGEND,[0.57,0.92],['Valid Raw Data Point','Bad Raw Data Point','Interpolated/Detrended/Windowed Data']    $
    ,COLOR      = [red, blue,   0]                                                                              $
    ,PSYM       = [ -4,    4,  -4]                                                                              $
    ,CHARSIZE   = 0.5                                                                                           $
    ,THICK      = [  4,    4,   1]                                                                              $
    ,TITLE      = 'Data'

LINE_LEGEND,[0.4,0.92]                                                                                          $
    ,[NUMSTR(bandLim[0]*1000.,1) + ' mHz Sine Wave',NUMSTR(bandLim[1]*1000.,1) + ' mHz Sine Wave']              $
    ,LINESTYLE  = [sinLineStyle0, sinLineStyle1]                                                                $
    ,THICK      = [sinThick0, sinThick1]                                                                        $
    ,COLOR      = [sinColor0, sinColor1]                                                                        $
    ,CHARSIZE   = 0.5                                                                                           $
    ,TITLE      = 'Reference Signals'
ENDFOR

CLEAR_PAGE,/NEXT
RAD_WAVE_PLOT_TITLE,1,1,0,0                                             $ 
    ,CHARTHICK      = charthick                                         $
    ,CHARSIZE       = charsize                                          $
    ,PARAMETER      = param                                             $
    ,/PARAM_INFO                                                        $
    ,BEAM           = beam                                              $
    ,/NO_GATE                                                           $
    ,BAR            = bar
title$    = 'Bandpass Integrated Power (' + bl$[0] + ' - ' + bl$[1] + ' mHz)'
PLOT_TITLE,title$,subtitle$
posit   = DEFINE_PANEL(1,1,0,0,BAR=bar)
PLOT,1E6*wave_intpsd_data.intpwrrtiarr[winInx,beam,*]                                   $
    ,XTITLE     = 'Range Gate [Window Center: ' + JUL2STRING(wave_dynfft_data.juls[winInx]) + ']'       $
    ,YTITLE     = TEXTOIDL('\Sigma_{'+bl$[0]+' mHz}^{'+bl$[1]+' mHz}S(f) 10^6 \cdot ') + intUnit$   $
    ,PSYM       = -4                                                                    $
    ,SYMSIZE    = 0.40                                                                  $
    ,XSTYLE     = 1                                                                     $
    ,POSITION   = posit
END
