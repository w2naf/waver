PRO PSDFAN_ALL
COMMON rad_data_blk
COMMON WAVE_BLK

test            = 1
rti             = 0
date            = [20110926, 20110926]
date            = [20101119, 20101119]
time            = [1200, 2400]

param           = 'power'
coords          = 'magn'
bandLim         = [0.0005, 0.0015]
bandLim         = [0.0003, 0.0010]
prefft          = 1
psdScale        = [0,150] / 1E6
preFFTScale     = 15. * [-1,1]
psdExclude      = [10,10000] / 1E6
zero_exclude    = 1
charSize        = 0.75
overLay_FOV     = 0

;Ground scatter flag. 0: plot all backscatter data 1: plot ground backscatter only 2: plot ionospheric backscatter only 3
gscatter        = 0             ;Ground scatter flag (ONLY affects RTI plots)
filter          = 1             ;filter radar data   (ONLY affects RTI plots)
rtiPwrScale     = [0., 30.]     ;                    (ONLY affects RTI plots)
rtiVelScale     = [-150., 150.] ;                    (ONLY affects RTI plots)


stepLenMin      = 10.   ;minutes
psdJulVec       = 1 ;Set this keyword to use the time vector of the PSD calculations
                    ;rather than that of the preFFT calculations.

radarVec        = ['bks', 'cve', 'cvw', 'fhe', 'fhw'            $   
                  ,'gbr', 'han', 'hok', 'inv', 'kap'            $   
                  ,'ksr', 'kod', 'pyk', 'pgr', 'rkn'            $   
                  ,'sas', 'sto', 'wal']

markBeam        = 0
beamOfInt       = [    7,    12,    12,     7,     7            $   
                  ,    7,     9,     4,     7,     7            $   
                  ,    1,     7,     0,    12,     7            $   
                  ,    7,     7,     7]

IF ~KEYWORD_SET(preFFT) THEN BEGIN
    exclude     = psdExclude
    scale       = psdScale
ENDIF ELSE BEGIN
    scale       = preFFTScale
ENDELSE

SFJUL,date,time,sjul,fjul

IF KEYWORD_SET(rti) THEN BEGIN
    RTIALL                                                  $
        ,FILTER             = filter                        $   
        ,DATE               = date                          $   
        ,TIME               = time                          $   
        ,RADARVEC           = radarVec                      $   
        ,BEAMOFINT          = beamOfInt                     $   
        ,GSCATTER           = gscatter                      $   
        ,RTIPWRSCALE        = rtiPwrScale                   $   
        ,RTIVELSCALE        = rtiVelScale
        stop
ENDIF

RAD_SET_SCATTERFLAG,0   ;Plot all scatter for PSD/preFFT plots

timeLenDay      = fJul - sJul
timeLenMin      = timeLenDay * 24. * 60.
nFrames         = FLOOR(timeLenMin / stepLenMin)
stepVec         = FINDGEN(nFrames) / (nFrames-1) * timeLenDay

julStepVec      = sJul + stepVec

isotropic       = 1
xyrng           = 50
xRange          = [-xyRng, xyRng]
yRange          = [-xyRng, xyRng]
yrange          = [-45, 15]
yrange          = [-45, 20]


;Create fov_info structure to store information about all radars
;being plotted.
fov_info_tmp    = {radar                : STRARR(1)     $
                  ,nbeams               : INTARR(1)     $
                  ,nranges              : INTARR(1)     $
                  ,lagfr                : INTARR(1)     $
                  ,smsep                : INTARR(1)     $
                  ,good                 : BYTARR(1)}

SET_FORMAT,/LANDSCAPE,/SARDINES
IF KEYWORD_SET(preFFT) THEN BEGIN
    fileName$       = DIR('output/preFFTfanall.ps',/PS)
ENDIF ELSE BEGIN
    fileName$       = DIR('output/psdfanall.ps',/PS)
ENDELSE

FOR frk=0,nFrames-1 DO BEGIN    ;Begin time/scan loop.
    jul         = julStepVec[frk]
    jul$        = JUL2STRING(jul)
    ;PRINFO,jul$+' ('+NUMSTR(frk)+' of '+NUMSTR(nFrames-1)+')'
    str$        = jul$+' ('+NUMSTR(frk)+' of '+NUMSTR(nFrames-1)+')'

    CLEAR_PAGE,/NEXT
    
    @timebar    ;Time progress bar.

    RAD_PSD_PLOT_SCAN                                                       $
        ,PARAM                      = param                                 $
        ,SCALE                      = scale                                 $
        ,JUL                        = jul                                   $
        ,XRANGE                     = xRange                                $
        ,YRANGE                     = yRange                                $
    ;    ,ROTATE                    = rotate                                $
        ,PREFFT                     = prefft                                $
        ,COORDS                     = coords                                $
        ,BANDLIM                    = bandLim                               $
        ,ISOTROPIC                  = isotropic                             $
        ,/NO_CLEAR_PAGE                                                     $
        ,/CONTINUOUS                                                        $
        ,/NO_DATA

    FOR rk=0,N_ELEMENTS(radarVec)-1 DO BEGIN    ; Begin Radar Data Overlay Loop
        radar           = radarVec[rk]
        PRINFO,radar + ' ' + str$

        PRINFO,'Starting file load.'
        savFile=0
        RAD_WAVE_READ,date,radar,PARAM=param,BANDLIM=bandLim,FILENAME=savFile,/INTPSD_ONLY
        PRINFO,'Finished with file: ' + savFile
        fov_info        = REPLICATE(fov_info_tmp,N_ELEMENTS(radarVec))

        ;Make sure data file exists, if not, skip.
        fTest           = FILE_TEST(savFile)
        IF ~fTest THEN  BEGIN
            PRINT,'Error!  SavFile does not exist!'
            CONTINUE
        ENDIF

        RAD_PSD_OVERLAY_SCAN                                                $
            ,COORDS                 = coords                                $
            ,JUL                    = jul                                   $
            ,PARAM                  = param                                 $
            ,SCALE                  = scale                                 $
            ,ROTATE                 = rotate                                $
            ,PREFFT                 = prefft                                $
            ,EXCLUDE                = exclude                               $
            ,CHARSIZE               = charSize                              $
            ,ZERO_EXCLUDE           = zero_exclude                          $
            ,/ANNOTATE

        IF ~KEYWORD_SET(preFFT) THEN BEGIN
            dataStruct  = WAVE_intpsd_data
            julVec      = dataStruct.intPwrRtiJulVec
            dataArr     = dataStruct.intPwrRtiArr
            grndArr     = dataStruct.intPwrRtiArrGround
            smsepArr    = dataStruct.intPwrRTIsmsep
            lagfrArr    = dataStruct.intPwrRTIlagfr
        ENDIF ELSE BEGIN
            dataStruct  = WAVE_intpsd_data
            julVec      = dataStruct.preFFTRtiJulVec
            dataArr     = dataStruct.preFFTRtiArr
            grndArr     = dataStruct.preFFTRtiArrGround
            smsepArr    = dataStruct.preFFTRTIsmsep
            lagfrArr    = dataStruct.preFFTRTIlagfr
        ENDELSE
            
        timeInx = WHERE(julVec GE jul,cnt)
        IF cnt GT 0 THEN timeInx = timeInx[0]
        IF cnt EQ 0 THEN timeInx = N_ELEMENTS(julVec)-1

        fov_info[rk].radar  = radar
        fov_info[rk].nBeams = wave_dataproc_info.nBeams
        fov_info[rk].nRanges= wave_dataproc_info.nGates
        fov_info[rk].lagfr  = lagFrArr[timeInx]
        fov_info[rk].smsep  = smSepArr[timeInx]
        fov_info[rk].good   = 1

        IF KEYWORD_SET(markBeam) THEN BEGIN
            region = [beamOfInt[rk], beamOfInt[rk]+1, 0, infoStruct.nGates]
            PRINFO,'preFFT Region: '
            PRINT,region
            OVERLAY_FOV                                                     $
               ,JUL                    = jul                               $
                ,ROTATE                 = rotate                            $
                ,NAMES                  = radar                             $
                ,NBEAMS                 = infoStruct.nBeams                 $
                ,NRANGES                = infoStruct.nGates                 $
                ,/NO_FILL                                                   $
                ,/NO_MARK_FILL                                              $
                ,MARK_LINESTYLE         = 2                                 $
                ,MARK_LINECOLOR         = 254                               $
                ,MARK_LINETHICK         = 3                                 $
                ,MARK_REGION            = region                            $
                ,LAGFR0                 = lagFr0                            $
                ,SMSEP0                 = smSepArr[timeInx]                 $
                ,/NO_FOV                                                    $
                ,CHARSIZE               = charSize                          $
                ;,/ANNOTATE                                                  $
                ,COORDS                 = coords
        ENDIF ;markBeam
    ENDFOR      ; End Radar Data Overlay Loop

    IF KEYWORD_SET(overlay_fov) THEN BEGIN
        FOR rk=0,N_ELEMENTS(radarVec)-1 DO BEGIN    ;Radar loop to overlay FOV's.
        IF ~KEYWORD_SET(fov_info[rk].good) THEN BEGIN
            STOP
            CONTINUE
        ENDIF
            OVERLAY_FOV                                                                 $
                ,JUL                    = jul                                           $
                ,ROTATE                 = rotate                                        $
                ,NAMES                  = fov_info[rk].radar                            $
                ,NBEAMS                 = fov_info[rk].nBeams                           $
                ,NRANGES                = fov_info[rk].nGates                           $
                ,/NO_FILL                                                               $
                ,/NO_MARK_FILL                                                          $
                ,CHARSIZE               = charSize                                      $
                ,FOV_LINESTYLE          = 2                                             $
                ,FOV_LINECOLOR          = 0                                             $
                ;,FOV_LINECOLOR          = GET_GRAY()                                    $
                ,FOV_LINETHICK          = 1                                             $
                ,MARK_LINESTYLE         = 1                                             $
                ,MARK_LINECOLOR         = GET_GRAY()                                    $
                ,MARK_LINETHICK         = 1                                             $
                ,LAGFR0                 = fov_info[rk].lagfr                            $
                ,SMSEP0                 = fov_info[rk].smsep                            $
    ;            ,/ANNOTATE                                                              $
                ,COORDS                 = coords
        ENDFOR ;Radar loop FOV Overlay.
    ENDIF       ;overlay_fov option
    IF KEYWORD_SET(test) THEN BEGIN
        PS_CLOSE
        STOP
    ENDIF
ENDFOR ;Time Loop
PS_CLOSE
END
