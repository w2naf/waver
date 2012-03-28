FUNCTION INT_PWR_RTI,dataStruct_in,bandLimits                   $
    ,RADAR                      = radar                         $
    ,BEAM                       = beam                          $
    ,STARTGATE                  = startGate                     $
    ,ENDGATE                    = endGate                       $
    ,EXCLUDE                    = exclude                       $
    ,max_offTime                = max_offTime                   $
    ,ONTIMES                    = onTimes                       $
    ,MIN_ONTIME                 = min_onTime                    $
    ,INTERPOLATE                = interp                        $
    ,DETREND                    = detrend                       $
    ,WINDOWLENGTH               = winLen                        $
    ,STEPLENGTH                 = stepLen                       $
    ,NOHANNING                  = noHanning                     $
    ,DBSCALE                    = dbScale                       $
    ,VERBOSE                    = verbose

COMMON WAVE_BLK

IF ~KEYWORD_SET(radar)          THEN radar = wave_dataproc_info.radar
IF N_ELEMENTS(beam) EQ 0        THEN beam = 0

dataStruct      = dataStruct_in
data            = dataStruct.data
juls            = dataStruct.juls

nData           = N_ELEMENTS(juls)
timeRes         = TIMERES(juls) * 86400.

sjul            = juls[0]
fjul            = juls[nData-1]

maxGates        = N_ELEMENTS(data[0,*])
IF ~KEYWORD_SET(startGate)              THEN startGate  = 0
IF ~KEYWORD_SET(endGate)                THEN endGate    = maxGates - 1
nGate           = (endGate - startGate) + 1

IF ~KEYWORD_SET(exclude)                THEN exclude    = [10000,10000]
FOR gate=startGate,endGate DO BEGIN
    IF  KEYWORD_SET(verbose) THEN PRINFO                                        $
        , ' Radar: ' + radar                                                    $
        + ' Beam: ' + NUMSTR(beam)                                              $
        + ' Gate: ' + NUMSTR(gate)

    gateDataStruct  = {time:juls, data:data[*,gate]}

    nanInx      = WHERE(gateDataStruct.data LE exclude[0]               $
                     OR gateDataStruct.data GE exclude[1],cnt)

    ;The rest of the data processing stream will treat Nan's as missing values.
    IF cnt GT 0                 THEN gateDataStruct.data[nanInx] = !VALUES.F_NAN
    IF KEYWORD_SET(max_offTime)     THEN BEGIN
        offTimes = OFFTIMES2(gateDataStruct             $   
                ,SJUL           = sJul                  $
                ,FJUL           = fJul                  $
                ,max_offTime    = max_offTime           $   
                ,ONTIMES        = ontimes               $   
                ,MIN_ONTIME     = min_onTime            )
;        ; Save offtimes records to a file. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        fName$  = 'output/offtimes.'+NUMSTR(beam)+'.txt'
;        IF (gate EQ startGate) THEN SPAWN,'rm -f ' + fName$
;        OPENW,1,fName$,WIDTH=300,/APPEND
;        str$    = '********************************************************************************'
;        PRINTF,1,str$
;        str$    =   radar   + ' -'                                      $
;                + ' Beam: ' + NUMSTR(beam)                              $
;                + ' Gate: ' + NUMSTR(gate)                              $
;                + ' Time: ['+ JUL2STRING(sjul)+', ' + JUL2STRING(fJul) + ']'
;        PRINTF,1,str$
;        str$    = 'offTimes:'
;        PRINTF,1,str$
;        PRINTF,1,TRANSPOSE(JUL2STRING(offTimes))
;        str$    = 'onTimes:'
;        PRINTF,1,str$
;        PRINTF,1,TRANSPOSE(JUL2STRING(onTimes))
;        PRINTF,1,''
;        CLOSE,1

        ;Create array containing all of the off times.
        nOff    = N_ELEMENTS(offTimes) / 2
        IF nOff NE 0 THEN BEGIN
            offTimesIn      = DBLARR(4,nOff)
            offTimesIn[0,*] = beam
            offTimesIn[1,*] = gate
            offTimesIn[2,*] = offTimes[*,0]
            offTimesIn[3,*] = offTimes[*,1]
            IF N_ELEMENTS(offTimesArr) EQ 0 THEN BEGIN
                offTimesArr = TRANSPOSE(offTimesIn)
            ENDIF ELSE BEGIN
                offTimesArr = [offTimesArr,TRANSPOSE(offTimesIn)]
            ENDELSE
        ENDIF

        ;Create array containing all of the on times.
        nOn     = N_ELEMENTS(onTimes)  / 2
        IF nOn  NE 0 THEN BEGIN
            onTimesIn       = DBLARR(4,nOn)
            onTimesIn[0,*]  = beam
            onTimesIn[1,*]  = gate
            onTimesIn[2,*]  = onTimes[*,0]
            onTimesIn[3,*]  = onTimes[*,1]

            IF N_ELEMENTS(onTimesArr) EQ 0 THEN BEGIN
                onTimesArr = TRANSPOSE(onTimesIn)
            ENDIF ELSE BEGIN
                onTimesArr = [onTimesArr,TRANSPOSE(onTimesIn)]
            ENDELSE
        ENDIF
    ENDIF

;Check to see if WAVE_INT_RTI_PWR structure already exists, and if the
;preFFTRTIJulVec tag exists.  If so, extract that information into the time
;grid.

IF N_TAGS(WAVE_int_pwr_rti) NE 0 THEN BEGIN
    IF TAG_EXISTS(WAVE_int_pwr_rti,'preFFTRTIJulVec') THEN timeGrid = WAVE_int_pwr_rti.preFFTRTIJulVec
ENDIF
    dynFFT  = CALC_DYNFFT(gateDataStruct                $
                ,INTERPOLATE    = interp                $
                ,DETREND        = detrend               $
                ,WINDOWLENGTH   = winLen                $
                ,STEPLENGTH     = stepLen               $
                ,NOHANNING      = noHanning             $
                ,ONTIMES        = onTimes               $
                ,OFFTIMES       = offTimes              $
                ,TIMEGRID       = timeGrid              $
                ,/MAGNITUDE)

    ;Save entire dynamic FFT calculation to a common block variable.
    IF gate EQ startGate THEN BEGIN
        dims            = SIZE(dynFFT.FFT,/DIMENSIONS)
        rawDims         = N_ELEMENTS(gateDataStruct.time)
        preFFTdims      = N_ELEMENTS(dynFFT.preFFTTimeVec)
        wave_dynfft     = {                                                             $
             juls                    : dynFFT.time                                      $
            ,freq                    : dynFFT.freq                                      $
            ,fft                     : DBLARR(dims[0],dims[1],endGate+1)                $
            ,windowedTSR_deltaDays   : dynFFT.winTime                                   $
            ,windowedTSR             : DBLARR(dims[0],dims[1],endGate+1)                $ 
            ,preFFTtsr_juls          : dynFFT.preFFTTimeVec                             $
            ,preFFTtsr               : FLTARR(preFFTdims,endGate+1)                     $
            ,rawtsr_juls             : gateDataStruct.time                              $
            ,rawtsr                  : FLTARR(rawDims,endGate+1)                        $
            ,badFlag                 : FLTARR(rawDims,endGate+1)                        $
            }
    ENDIF
    wave_dynfft.fft[*,*,gate]           = dynFFT.fft
    wave_dynfft.windowedTSR[*,*,gate]   = dynFFT.windowedTimeSeries
    wave_dynfft.rawTSR[*,gate]          = gateDataStruct.data
    wave_dynfft.badFlag[*,gate]         = BYTARR(rawDims)
    wave_dynfft.preFFTtsr[*,gate]       = dynFFT.preFFTTSR
    IF nanInx[0] NE -1 THEN wave_dynfft.badFlag[nanInx,gate] = 1

    IF gate EQ startGate THEN BEGIN
        preFFTRTI       = dynFFT.preFFTTSR
    ENDIF ELSE BEGIN
        preFFTRTI       = [[preFFTRTI],[dynFFT.preFFTTSR]]
    ENDELSE

    blInx   = WHERE((dynFFT.freq GE bandLimits[0]) * (dynFFT.freq LE bandLimits[1]))
    df      = dynFFT.freq[1] - dynFFT.freq[0]
    psd     = dynFFT.fft^2
    IF KEYWORD_SET(dbScale)     THEN psd = 10.*ALOG10(psd)
    intPwr  = TOTAL(psd[*,blInx],2) * df

    ;Integrate entire calculated power spectral density band.
;    totPwr  = TOTAL(psd,2) * df

    ;Ratio of power in band of interest to pwr outside band of interest.
    ;From Bristow et al. [1996]
;    pwrRatio= intPwr / (totPwr - intPwr)

;    STOP

    IF N_ELEMENTS(waveRTI) EQ 0 THEN waveRTI = FLTARR(nGate,N_ELEMENTS(dynFFT.time))
    waveRTI[gate,*] = intPwr
ENDFOR

;Send list of on an off times to common block variable.
IF nOff NE 0 THEN WAVE_offTimes   = offTimesArr
IF nOn  NE 0 THEN WAVE_onTimes    = onTimesArr

dataStruct_out  = {julVec:              dynFFT.time                     $
                  ,data:                waveRTI                         $
                  ,preFFTRTIjulVec:     dynFFT.preFFTTimeVec            $
                  ,preFFTRTI:           TRANSPOSE(preFFTRTI)}

WAVE_int_pwr_rti= dataStruct_out
RETURN,dataStruct_out
END
