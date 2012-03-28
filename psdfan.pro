PRO PSDFAN
COMMON WAVE_BLK

test            = 0
date            = 20110926
date            = 20101119
time            = 1900

radar           = 'gbr'
;radar           = 'wal'
param           = 'power'
coords          = 'magn'
beamOfInt       = 7
bandLim         = [0.0005, 0.0015]
bandLim         = [0.0003, 0.0010]
prefft          = 1
constantScale   = 1

psdJulVec       = 1

RAD_WAVE_READ,date,radar,PARAM=param,BANDLIM=bandLim,FILENAME=fileName

IF ~KEYWORD_SET(preFFT) THEN BEGIN
    infoStruct      = wave_dataproc_info
    dataStruct      = WAVE_intpsd_data
    julVec          = dataStruct.intPwrRtiJulVec
    dataArr         = dataStruct.intPwrRtiArr
    grndArr         = dataStruct.intPwrRtiArrGround
ENDIF ELSE BEGIN
    infoStruct      = wave_dataproc_info
    dataStruct      = WAVE_intpsd_data
    julVec          = dataStruct.preFFTRtiJulVec
    dataArr         = dataStruct.preFFTRtiArr
    grndArr         = dataStruct.preFFTRtiArrGround
    IF KEYWORD_SET(psdJulVec) THEN julVec = dataStruct.intPwrRtiJulVec
ENDELSE
julStepVec      = julVec

xRange  = [-15, 25]
yRange  = [-35, 15]
xRange  = [-50, 50]
yRange  = [-45, 15]

;rotate  = 90.
IF KEYWORD_SET(constantScale) THEN BEGIN
    IF ~KEYWORD_SET(prefft) THEN BEGIN
        scale   = [0, MAX(dataArr)]
    ENDIF ELSE BEGIN
        absMin      = ABS(MIN(dataArr,/NAN))
        absMax      = ABS(MAX(dataArr,/NAN))
        IF absMin GE absMax THEN scale = [-absMin,absMin] ELSE scale = [-absMax,absMax]
    ENDELSE
ENDIF ;Constant Scale
SCALE   = [0,150./1E6]

nFrames = N_ELEMENTS(julVec)

SFJUL,date,time,testJul
testInx  = CLOSEST(testJul,julVec)

SET_FORMAT,/LANDSCAPE,/SARDINES
fileName$       = DIR('output/psdfan.ps',/PS)
FOR frk=0,nFrames-1 DO BEGIN
    IF KEYWORD_SET(test) THEN frk = testInx
    IF ~KEYWORD_SET(constantScale) THEN BEGIN
        IF ~KEYWORD_SET(preFFT) THEN BEGIN
            SCALE   = [0, MAX(dataArr[frk,*,*])]
        ENDIF ELSE BEGIN
            absMin      = ABS(MIN(dataArr[frk,*,*],/NAN))
            absMax      = ABS(MAX(dataArr[frk,*,*],/NAN))
            IF absMin GE absMax THEN scale = [-absMin,absMin] ELSE scale = [-absMax,absMax]
        ENDELSE
    ENDIF ;Not Constant Scale

    jul = julVec[frk]
    jul$        = JUL2STRING(jul)
    PRINFO,jul$+' ('+NUMSTR(frk)+' of '+NUMSTR(nFrames-1)+')'
    CLEAR_PAGE,/NEXT
    @timebar
    ;RAD_PSD_PLOT_SCAN_PANEL                                            $
    RAD_PSD_PLOT_SCAN                                                   $
        ,PARAM                  = param                                 $
;        ,DATE                   = date                                  $
;        ,TIME                   = time                                  $
        ,SCALE                  = scale                                 $
        ,JUL                    = jul                                   $
        ,XRANGE                 = xRange                                $
        ,YRANGE                 = yRange                                $
        ,ROTATE                 = rotate                                $
        ,PREFFT                 = prefft                                $
        ,COORDS                 = coords                                $
        ,/NO_CLEAR_PAGE                                                 $
        ,/WITH_INFO                                                     $
        ,/ISOTROPIC                                                     $
        ,/CONTINUOUS                                                    $
        ,SAVFILE                = savFile

    IF N_ELEMENTS(beamOfInt) NE 0 THEN BEGIN
        region                      = [beamOfInt, beamOfInt+1, 0, infoStruct.nGates]
        PRINT,region
    ENDIF
    OVERLAY_FOV                                                                 $
        ,JUL                    = jul                                           $
        ,ROTATE                 = rotate                                        $
        ,NAMES                  = radar                                         $
        ,NBEAMS                 = infoStruct.nBeams                             $
        ,NRANGES                = infoStruct.nGates                             $
        ,/NO_FILL                                                               $
        ,/NO_MARK_FILL                                                          $
        ,MARK_LINESTYLE         = 1                                             $
        ,MARK_LINECOLOR         = 254                                           $
        ,MARK_LINETHICK         = 1                                             $
        ,MARK_REGION            = region                                        $
        ,/ANNOTATE                                                              $
        ,COORDS                 = coords

        IF KEYWORD_SET(test) THEN BEGIN
            PS_CLOSE
            STOP
        ENDIF
ENDFOR
PS_CLOSE



STOP
END
