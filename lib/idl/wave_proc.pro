PRO WAVE_PROC                                                   $
    ,DATE               = date                                  $
    ,TIME               = time                                  $
    ,LONG               = long                                  $
    ,JULS               = juls                                  $
    ,RADAR              = radar                                 $
    ,PARAM              = param                                 $
    ,FILTER             = filter                                $
    ,AJGROUND           = ajGround                              $
    ,WINLEN             = winLen                                $
    ,STEPLEN            = stepLen                               $
    ,BANDLIM            = bandLim                               $
    ,MAX_OFFTIME        = max_offTime                           $
    ,INTERP             = interp                                $
    ,DETREND            = detrend                               $
    ,NO_HANNING         = no_hanning                            $
    ,MIN_ONTIME         = min_onTime                            $
    ,EXCLUDE            = exclude                               $
    ,SCALE              = scale                                 $
    ,DBSCALE            = dbScale                               $
    ,PCTPWRTHRESH       = pctPwrThresh                          $
    ,FNDPWRTHRESH       = fndPwrThresh                          $
    ,SCATTERFLAG        = scatterFlag                           $
    ,CATFILE            = catFile                               $
    ,CATPATH            = catPath                               $
    ,VERBOSE            = verbose

COMMON RAD_DATA_BLK
COMMON WAVE_BLK

TIMECHECK,date,time,juls,sjul,fjul,LONG=long
                                     radar      = GET_RADAR(radar)
IF ~KEYWORD_SET(param)          THEN param      = GET_PARAMETER()
IF ~KEYWORD_SET(filter)         THEN filter     = 0
IF ~KEYWORD_SET(winLen)         THEN winLen     = 3. * 60. * 60.        ;in sec
IF ~KEYWORD_SET(stepLen)        THEN stepLen    = 120.                  ;in sec
IF ~KEYWORD_SET(bandLim)        THEN bandLim    = [0.0020, 0.0070]      ;in Hz
IF ~KEYWORD_SET(max_offTime)    THEN max_offTime= 250.                  ;in sec
IF ~KEYWORD_SET(interp)         THEN interp     = 1.                    ;in sec
IF  N_ELEMENTS(detrend) EQ 0    THEN detrend    = -1
IF ~KEYWORD_SET(no_Hanning)     THEN no_Hanning = 0
IF ~KEYWORD_SET(min_onTime)     THEN min_onTime = 30. * 60.             ;in sec
IF ~KEYWORD_SET(exclude)        THEN exclude    = [-10000,10000]
IF ~KEYWORD_SET(scale)          THEN scale      = GET_SCALE()
IF ~KEYWORD_SET(dbScale)        THEN dbScale    = 0
IF  N_ELEMENTS(long) EQ 0       THEN long       = 0

SET_PARAMETER,param

;Add in WinLen/2 to each side of the analysis period.
winLenDay       = winLen / 86400.
sjulLoad        = sjul - winLenDay /2.
fjulLoad        = fjul + winLenDay /2.
SFJUL, dateLoad, timeLoad, sjulLoad, fjulLoad,/JUL_TO_DATE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Calculate the time grid that will be used before all of the processing starts.  This will then be passed to the interpolator, to ensure that the interpolated measurements for every beam are the same throughout a day.
interpDay       = interp / 86400.
timeLengthDays  = fJulLoad - sJulLoad
nData           = CEIL(timeLengthDays / interpDay)
dayGrid         = (FINDGEN(nData) / (nData - 1)) * timeLengthDays
julGrid         = dayGrid + sJulLoad

;Stick the time grid in a common block variable so that it can be read by other functions.
;This will get written over later.
WAVE_int_pwr_rti= {preFFTRTIJulVec:julGrid}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;RAD_FIT_READ,dateLoad,radar,TIME=timeLoad,FILTER=filter,AJGROUND=ajGround
RAD_FIT_READ,dateLoad,radar                                     $
    ,TIME               = timeLoad                              $
    ,FILTER             = filter                                $
    ,AJGROUND           = ajGround                              $
    ,CATPATH            = catPath                               $
    ,CATFILE            = catFile

data_index      = RAD_FIT_GET_DATA_INDEX()

;Quit routine if now data available.
IF data_index EQ -1 THEN BEGIN
    PRINFO,'No data available for ' + radar + '.'
    RETURN
ENDIF

nBeams                  = (*rad_fit_info[data_index]).nBeams
nGates                  = (*rad_fit_info[data_index]).nGates
preFftRtiArr            = FLTARR(nData,nBeams,nGates)
preFftRtiArrGround      = BYTARR(nData,nBeams,nGates)

;Populate the wave_dataproc_info common block structure.
wave_dataproc_info.date                 = date
wave_dataproc_info.time                 = time
wave_dataproc_info.juls                 = juls
wave_dataproc_info.radar                = radar
wave_dataproc_info.long                 = long
wave_dataproc_info.param                = param
wave_dataproc_info.filtered             = filter
wave_dataproc_info.ajground             = ajground
wave_dataproc_info.winlen               = winlen
wave_dataproc_info.steplen              = steplen
wave_dataproc_info.bandlim              = bandlim
wave_dataproc_info.max_offTime          = max_offTime
wave_dataproc_info.interp               = interp
wave_dataproc_info.detrend              = detrend
wave_dataproc_info.no_hanning           = no_hanning
wave_dataproc_info.min_ontime           = min_ontime
wave_dataproc_info.exclude              = exclude
wave_dataproc_info.scale                = scale
wave_dataproc_info.dbscale              = dbscale
wave_dataproc_info.pctpwrthresh         = pctpwrthresh
wave_dataproc_info.fndpwrthresh         = fndpwrthresh
wave_dataproc_info.verbose              = verbose


wave_dataproc_info.id                   = (*rad_fit_info[data_index]).id
wave_dataproc_info.name                 = (*rad_fit_info[data_index]).name
wave_dataproc_info.nBeams               = (*rad_fit_info[data_index]).nBeams
wave_dataproc_info.nGates               = (*rad_fit_info[data_index]).nGates
wave_dataproc_info.glat                 = (*rad_fit_info[data_index]).glat
wave_dataproc_info.glon                 = (*rad_fit_info[data_index]).glon
wave_dataproc_info.mlat                 = (*rad_fit_info[data_index]).mlat
wave_dataproc_info.mlon                 = (*rad_fit_info[data_index]).mlon
wave_dataproc_info.fitex                = (*rad_fit_info[data_index]).fitex
wave_dataproc_info.fitacf               = (*rad_fit_info[data_index]).fitacf
wave_dataproc_info.fit                  = (*rad_fit_info[data_index]).fit

FOR beam=0,nBeams-1 DO BEGIN
    RAD_SET_BEAM,beam
    PRINFO,NUMSTR(beam)
    beamInx         = WHERE((*rad_fit_data[data_index]).beam EQ beam,cnt)
    IF cnt LE 1 THEN CONTINUE
    julVec          = (*rad_fit_data[data_index]).juls[beamInx]
    gscatter        = (*rad_fit_data[data_index]).gscatter[beamInx,*]
    smSep           = (*rad_fit_data[data_index]).smsep[beamInx,*]
    lagfr           = (*rad_fit_data[data_index]).lagfr[beamInx,*]
    nData           = N_ELEMENTS(julVec)
    timeRes         = TIMERES(julVec) * 86400.
    str$            = 'paramData = (*rad_fit_data[data_index]).'+param+'[beamInx,*]'
    result          = EXECUTE(str$)

    ;Strictly enforce sJulLoad,fJulLoad time boundaries.  We may want to change this later,
    ;as we might get a better interpolation result without it.  However, I think that
    ;it should be fine because of all of the hanning windowing we end up doing.
    ;Furthermore, doing this really helps me to know exactly what data is going into
    ;the processing stream.
    timeInx         = WHERE((julVec GE sJulLoad) AND (julVec LE fJulLoad))
    julVec          = julVec[timeInx]
    paramData       = paramData[timeInx,*]
    smsep           = smsep[timeInx]
    lagfr           = lagfr[timeInx]
    gscatter        = gscatter[timeInx,*]

    IF ~KEYWORD_SET(scatterFlag) THEN scatterFlag = 0
    RAD_SET_SCATTERFLAG,scatterFlag
    wave_dataproc_info.scatterFlag      = scatterFlag

    IF N_ELEMENTS(scattercat) EQ 0 THEN scattercat = -1
    wave_dataproc_info.scattercat       = scattercat
    IF KEYWORD_SET(ajground) AND scattercat NE -1 THEN BEGIN
        CASE scatterCat OF
            0: gInx = WHERE(gScatter EQ 0,gCnt,COMPLEMENT=cInx,NCOMPLEMENT=cCnt) ;Plasmaspheric Scatter
            1: gInx = WHERE(gScatter EQ 1,gCnt,COMPLEMENT=cInx,NCOMPLEMENT=cCnt) ;Long-period ground scatter
            2: gInx = WHERE(gScatter EQ 2,gCnt,COMPLEMENT=cInx,NCOMPLEMENT=cCnt) ;High-velocity Ionospheric Scatter
            3: gInx = WHERE(gScatter EQ 3,gCnt,COMPLEMENT=cInx,NCOMPLEMENT=cCnt) ;Other
            ELSE:
        ENDCASE
    ENDIF ELSE BEGIN
        CASE scatterFlag OF
            1: gInx = WHERE(gScatter EQ 1,gCnt,COMPLEMENT=cInx,NCOMPLEMENT=cCnt) ;Ground Scatter
            2: gInx = WHERE(gScatter EQ 0,gCnt,COMPLEMENT=cInx,NCOMPLEMENT=cCnt) ;Ionospheric Scatter
            ELSE:
        ENDCASE
    ENDELSE

    IF KEYWORD_SET(cCnt) THEN paramData[cInx]     = !VALUES.F_NAN

    dataStruct      = {juls:julVec, data:paramData}
    intPwrRTIStruct = INT_PWR_RTI(dataStruct,bandLim                                $
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
                        ,VERBOSE                    = verbose                       )
    nRawTsr                 = N_ELEMENTS(wave_dynfft.rawtsr_juls)
    IF N_ELEMENTS(intPwrRtiArr) EQ 0 THEN BEGIN
        nData                   = N_ELEMENTS(intPwrRTIStruct.julVec)
        intPwrRtiArr            = FLTARR(nData,nBeams,nGates)
        intPwrRtiJulVec         = intPwrRTIStruct.julVec
        intPwrRtiArrGround      = BYTARR(nData,nBeams,nGates)

        nPreFFTtsr              = N_ELEMENTS(wave_dynfft.preFFTtsr_juls)

        nFreq                   = N_ELEMENTS(wave_dynfft.freq)

        wave_dynfft_data        = {                                             $
               juls                 : wave_dynfft.juls                          $
              ,freq                 : FLOAT(wave_dynfft.freq)                   $
              ,fft                  : FLTARR(nData,nFreq,nBeams,nGates)         $
              ,windowedTSR_deltaDays: FLOAT(wave_dynfft.windowedTSR_deltaDays)  $
              ,windowedTSR          : FLTARR(nData,nFreq,nBeams,nGates)         $
              ,preFFTtsr_juls       : wave_dynfft.preFFTtsr_juls                $
              ,preFFTtsr            : FLTARR(nPreFFTtsr,nBeams,nGates)          $
;              ,rawtsr_juls          : DBLARR(nRawTsr+5,nBeams)                    $
;              ,rawtsr               : FLTARR(nRawTsr+5,nBeams,nGates)             $
;              ,badflag              : FLTARR(nRawTsr+5,nBeams,nGates)             $
              }

        wave_rawtsr_data        = {                                             $
               rawtsr_juls          : PTR_NEW()                                 $
              ,rawtsr               : PTR_NEW()                                 $
              ,badFlag              : PTR_NEW()                                 $
              }

        wave_rawtsr_data                = REPLICATE(TEMPORARY(wave_rawtsr_data), nBeams)
        wave_rawtsr_data.rawtsr_juls    = PTRARR(nBeams,/ALLOCATE_HEAP)
        wave_rawtsr_data.rawtsr         = PTRARR(nBeams,/ALLOCATE_HEAP)
        wave_rawtsr_data.badflag        = PTRARR(nBeams,/ALLOCATE_HEAP)
    ENDIF

    intPwrRtiGround                     = PARAM_REGRID(julVec,gscatter,intPwrRtiJulVec)
    preFftRtiGround                     = PARAM_REGRID(julVec,gscatter,julGrid)

    intPwrRtiArrGround[*,beam,*]        = intPwrRtiGround
    preFftRtiArrGround[*,beam,*]        = preFftRtiGround

    intPwrRtiArr[*,beam,*] = TRANSPOSE(intPwrRTIStruct.data)
    preFftRtiArr[*,beam,*] = TRANSPOSE(intPwrRTIStruct.preFFTRti)

    wave_dynfft_data.fft[*,*,beam,*]                    = wave_dynfft.fft
    wave_dynfft_data.windowedTSR[*,*,beam,*]            = wave_dynfft.windowedTSR
    wave_dynfft_data.preFFTtsr[*,beam,*]                = wave_dynfft.preFFTtsr

    *wave_rawtsr_data[beam].rawtsr_juls = wave_dynfft.rawtsr_juls
    *wave_rawtsr_data[beam].rawtsr      = wave_dynfft.rawtsr
    *wave_rawtsr_data[beam].badflag     = BYTE(wave_dynfft.badflag)
ENDFOR  ;End beam loop.

intPwrRTIsmsep          = PARAM_REGRID(julVec,smsep,intPwrRtiJulVec)
intPwrRTIlagfr          = PARAM_REGRID(julVec,lagfr,intPwrRtiJulVec)
preFFTRTIsmsep          = PARAM_REGRID(julVec,smsep,julGrid)
preFFTRTIlagfr          = PARAM_REGRID(julVec,lagfr,julGrid)

WAVE_intpsd_data        = {                                                             $
     intPwrRtiJulVec                    :intPwrRtiJulVec                                $
    ,intPwrRtiArr                       :intPwrRtiArr                                   $
    ,intPwrRtiArrGround                 :intPwrRtiArrGround                             $ 
    ,intPwrRTIsmsep                     :intPwrRTIsmsep                                 $  
    ,intPwrRTIlagfr                     :intPwrRTIlagfr                                 $  
    ,preFftRtiJulVec                    :julGrid                                        $
    ,preFftRtiArr                       :preFftRtiArr                                   $
    ,preFftRtiArrGround                 :preFftRtiArrGround                             $
    ,preFFTRTIsmsep                     :preFFTRTIsmsep                                 $  
    ,preFFTRTIlagfr                     :preFFTRTIlagfr                                 $  
    } 


;BRISTOMETER

RAD_WAVE_READ,date,radar                                                                $
    ,PARAM                      = param                                                 $
    ,BANDLIM                    = bandLim                                               $
    ,/WRITE

HEAP_GC,/PTR   
RAD_FIT_SET_DATA_INDEX,-1
END
