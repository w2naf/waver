;+ 
; NAME: 
; WINDOWIZE
; 
; PURPOSE: 
; This function takes time-series data and organizes it into an array of vectors each with a specified time duration (window length).  This function is designed to work with CALC_DYNFFT in order to calculate dynamic spectra.  As such, this function incorporates certain signal processing function that are useful for this type of analysis.  This includes the ability to detrend and apply a Hanning Window to each vector of windowed data.
; 
; CATEGORY: 
; Signalprocessing
; 
; CALLING SEQUENCE: 
; result = WINDOWIZE( dataStruct [, windowLength] [, DETREND=detrend] [, NOHANNING=noHanning] [, EPOCHTIME=epochTime])
;
; INPUTS:
; dataStruct:  A data structure containing a time vector and a data vector.  The structure
; should have the form of:
;       dataStruct = {time:timeVector, data:dataVector} 
; dataStruct.time is assumed to be in units of days (for Julian Days) unless the EPOCHTIME
; keyword is set.  Also, all data input into this routine should be regularly sampled in time.
;
; OUTPUTS:
; This function returns a data structure of the following form:
;       result = {time:time, data:data, delta:dt}
;       
;       result.time:  Time vector in same units as the input.  Each time in this vector is
;               the center of a data vector time window.
;       result.data:  Two-dimensional array containing the orginal data split into windows.
;               The first dimension corresponds with time, and the second dimension corresponds
;               with the data.
;       result.delta: Time resolution in seconds of the original data set.
;       result.winTime: Vector of relative time for each window in original time units.
;
; OPTIONAL INPUTS:
; WINDOWLENGTH: Set this keyword to set the length of the time window in seconds over which 
; to compute each FFT.  Default of WINDOWLENGTH = 600 s.
;
; KEYWORD PARAMETERS:
; DETREND: Set this keyword to the degree polynomial to fit and then subtract from each set
; of windowed data.  By default, this is set to DETREND=1 which corresponds to a linear fit/
; detrending.  Set DETREND=0 to remove the average; set DETREND=-1 to disable detrending.
;
; NOHANNING: Set this keyword to disable the application of a Hanning window to each vector of
; windowed data.  Hanning windows are needed for proper FFT computation.
;
; EPOCHTIME: Set this keyword to indicate that the input time vector is in units of seconds,
; not days.
;
; EXAMPLE: 
; 
;
; MODIFICATION HISTORY: 
; Written by: Nathaniel Frissell, 2011
;-
FUNCTION WINDOWIZE,dataStruct_in,windowLength           $
    ,DETREND            = detrend                       $
    ,NOHANNING          = noHanning                     $
    ,EPOCHTIME          = epochTime                     $
    ,ONTIMES            = onTimes                       $
    ,OFFTIMES           = offtimes                      $
    ,timesOn_detrend    = timesOn_detrend               $
    ,timesOn_noHanning  = timesOn_noHanning             $
    ,STEPLENGTH         = stepLength

timeVec         = dataStruct_in.time
dataVec         = dataStruct_in.data
dataVecNan      = dataStruct_in.data

IF N_ELEMENTS(timesOn_detrend)   EQ 0 THEN timesOn_detrend   = 0
IF N_ELEMENTS(timesOn_noHanning) EQ 0 THEN timesOn_noHanning = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF ~KEYWORD_SET(onTimes)  THEN onTimes  = -1
IF ~KEYWORD_SET(offTimes) THEN offTimes = -1
IF onTimes[0] NE -1 THEN BEGIN
    nOn = N_ELEMENTS(onTimes)/2.
    FOR kk=0,nOn-1 DO BEGIN
        inx     = WHERE(timeVec GE onTimes[kk,0] AND timeVec LE onTimes[kk,1],cnt)
        IF cnt NE 0 THEN BEGIN
            IF timesOn_detrend GE 0 THEN BEGIN
                dataVec[inx] = dataVec[inx] - MEAN(dataVec[inx])
            ENDIF
            IF ~KEYWORD_SET(timesOn_noHanning) THEN dataVec[inx] = dataVec[inx] * HANNING(cnt,/DOUBLE)
        ENDIF
    ENDFOR
ENDIF
IF offTimes[0] NE -1 THEN BEGIN
    nOff        = N_ELEMENTS(offTimes)/2.
    FOR kk=0,nOff-1 DO BEGIN
        inx     = WHERE(timeVec GE offTimes[kk,0] AND timeVec LE offTimes[kk,1],cnt)
        IF cnt NE 0 THEN BEGIN
            dataVec[inx]        = 0
            ;Put this patch in to output NaN values in the pre-fft/preFFT time series for
            ;data points that were discarded by my on/off time algorithm.
            dataVecNan[inx]     = !VALUES.F_NAN
        ENDIF
    ENDFOR
ENDIF
;Provide a way to see what the whole time series looks like with the onTimes/offTimes applied.
preFFTTSR       = dataVec
IF N_ELEMENTS(dataVecNan) NE 0 THEN preFFTTSR = dataVecNan
preFFTTimeVec   = timeVec

;Debugging plots to make sure off/on marker is working correctly. - 25OCT2011/NAF
;offOn   = preFFTTSR
;offOn[*]= 0
;goodInx = WHERE(FINITE(preFFTTSR))
;IF goodInx[0] NE -1 THEN offOn[goodInx] = 1
;
;CLEAR_PAGE
;posit   = DEFINE_PANEL(1,2,0,0)
;PLOT,timeVec,dataVec                    $
;    ,/XSTYLE                            $
;    ,XTICKFORMAT = 'LABEL_DATE'         $
;;    ,XTITLE     = 'UT - ' + JUL2STRING(timeVec[0])      $
;    ,POSITION   = posit                 $
;    ,CHARSIZE   = 2
;
;posit   = DEFINE_PANEL(1,2,0,1)
;PLOT,timeVec,offOn                      $
;    ,TITLE      = 'offOn Plot'          $
;    ,YRANGE     = [-0.5, 1.5]           $
;    ,POSITION   = posit                 $
;    ,/XSTYLE                            $
;    ,XTICKFORMAT = 'LABEL_DATE'         $
;    ,XTITLE     = 'UT - ' + JUL2STRING(timeVec[0])      $
;    ,CHARSIZE   = 2
;
;STOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
startTime       = timeVec[0]
timeVec         = timeVec - startTime

IF ~KEYWORD_SET(windowLength)   THEN windowLength = 600.
IF ~KEYWORD_SET(stepLength)     THEN stepLength = windowLength / 2.
;Convert time vector to seconds if given in units of days (i.e. Julian Time).
IF ~KEYWORD_SET(epochTime)      THEN timeVec    = timeVec * 86400.D
IF ~KEYWORD_SET(detrend)        THEN detrend    = -1

;Determine time resolution of data.
timeShift       = SHIFT(timeVec,1)
dt              = ABS(timeShift - timeVec)
dt              = dt[1:*]
delt            = FLOAT(TOTAL(dt)) / N_ELEMENTS(dt)

nCol    = FLOOR(windowLength/delt)
nDp     = N_ELEMENTS(timeVec) - nCol    ;Number of Data Points
nDpStep = FLOOR(stepLength / delt)
IF nDpStep EQ 0 THEN nDpStep = 1        ;Step cannot be equal to zero.
nRow    = FLOOR(nDp / nDpStep)

IF KEYWORD_SET(noHanning) THEN han = 1. ELSE han = HANNING(nCol,/DOUBLE)
dataArr    = FLTARR(nCol,nRow)
timeVecNew = FLTARR(nRow)
winTime = windowLength * (FINDGEN(nCol)/(nCol-1) - 0.5)
FOR winI = 0,nRow-1 DO BEGIN
    winStart = winI * nDpStep 
    dataRow = dataVec[winStart:winStart+nCol-1] 

    IF  detrend GE 0 THEN BEGIN
        xAxis   = FINDGEN(N_ELEMENTS(dataRow))
        ;Treat NaN's as missing data.
        fntInx  = WHERE(FINITE(dataRow),nFinite)
        IF nFinite GT 1 THEN BEGIN
            result  = POLY_FIT(xAxis[fntInx],dataRow[fntInx],detrend,YFIT=yfit)
            dataRow[fntInx] = dataRow[fntInx] - yFit
        ENDIF ELSE dataRow[*] = !VALUES.F_NAN
    ENDIF

    dataArr[*,winI] = han * dataRow    ;Apply a Hanning window.
    timeVecNew[winI]= timeVec[winStart] + windowLength / 2.
ENDFOR
;timeVec = timeVec[FLOOR(nCol/2.):nRow-1 + FLOOR(nCol/2.)]
timeVec = timeVecNew

;Convert time back to Julian Days if needed.
IF ~KEYWORD_SET(epochTime)      THEN BEGIN
    timeVec     = timeVec / 86400.D
    winTime     = winTime / 86400.D
ENDIF

timeVec = timeVec + startTime
RETURN,{ time:          timeVec                         $
        ,data:          TRANSPOSE(dataArr)              $
        ,delta:         delt                            $
        ,winTime:       winTime                         $
        ,preFFTTSR:     preFFTTSR                       $
        ,preFFTTimeVec: preFFTTimeVec}
END
