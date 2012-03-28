;+ 
; NAME: 
; CALC_DYNFFT
; 
; PURPOSE: 
; This procedure computes the dynamic FFT of a set of time series data.
;
; The maximum frequency calculated is given by:
;       fMax = 1/(2*dt)
; where dt is the time resolution of the data.
;
; Regularly spaced data is required; see notes on INTERPOLATE keyword for some
; additional info regarding this.
; 
; CATEGORY: 
; Signalprocessing
; 
; CALLING SEQUENCE: 
; result = CALC_DYNFFT( dataStruct [, INTERPOLATE=interpolate] [, DETREND=detrend] [ WINDOWLENGTH=windowLength] [, MAGNITUDE=magnitude] [, PHASE=phase] [, NORMALIZE=normalize] [, EPOCHTIME=epochTime])
;
; INPUTS:
; dataStruct:  A data structure containing a time vector and a data vector.  The structure
;; should have the form of:
;       dataStruct = {time:timeVector, data:dataVector} 
; dataStruct.time is assumed to be in units of days (for Julian Days) unless the EPOCHTIME
; keyword is set.
;
; OUTPUTS:
; This function returns a data structure of the following form:
;       result = {time:time, freq:freq, fft:FFT}
;       
;       result.time: Time vector in same units as the input.  Each time in this vector is
;               the center of an FFT time window.
;       result.freq: Frequency vector in Hertz.  Note that above fMax = 1/(2*dt), computed
;               FFT values fold over into the the reverse of the negative spectrum.  See
;               IDL help for FFT command for details.
;       result.fft:  Two-dimensional array containing the results of the FFT computation.
;               The first dimension corresponds with time, and the second dimension corresponds
;               with frequency.  If the MAGNITUDE, PHASE, or NORMALIZE keywords are set, then 
;               result.fft will contain magnitude, phase, or normalized magnitudes, respectively,
;               rather than the complex FFT result.
;       result.winTime: Vector of relative time for each window in original time units.
;       result.windowedTimeSeries: Two-dimensional array containing the data just prior to the application of the FFT.
;               
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
; INTERPOLATE: Set this keyword to a time resolution in seconds to interpolate the input
; data.  Interpolation is required to place radar data onto a regular time grid before
; computing the FFT.  If INTERPOLATE is not set, a default value of 5 seconds is used.
; To disable interpolation (useful if data set is already uniform in time), set
; INTERPOLATE = -1.
;
; DETREND: Set this keyword to the degree polynomial to fit and then subtract from each set
; of windowed data.  By default, this is set to DETREND=1 which corresponds to a linear fit/
; detrending.  Set DETREND=0 to remove the average; set DETREND=-1 to disable detrending.
;
; WINDOWLENGTH: Set this keyword to set the length of the time window in seconds over which 
; to compute each FFT.  Default of WINDOWLENGTH = 600 s.
;
; MAGNITUDE: Set this keyword to return the unnormalized magnitude of the FFT.
;
; PHASE: Set this keyword to return the phase of the FFT in radians.
;
; NORMALIZE: Set this keyword to return the normalized magnitude of the FFT.
;
; NANTHRESHOLD:  Set this keyword to calculate FFT's even for windows which have missing data (represented by NaN's).  This keyword represts a fraction of NaN's allowed with in a data window.  For example, if NANTHRESHOLD = 0.4, then the FFT of a data window will be calculated only if less than 40% of the data points within the window are NaN's.  The FFT of such a window will be calculated by running the calculation on a vector with the NaN's removed.  Because there are now less data points in the window than in the nominal case, the result frequency resolution will be lower.  To place the FFT's of these data windows on to the final grid, linear interpolation is used to generate a frequency vector which matches the rest of the data set. 
;
; EPOCHTIME: Set this keyword to indicate that the input time vector is in units of seconds,
; not days.
;
; TIMEGRID: Provide a time vector that you want the data to be interpolated to, rather than having the interpolator calculate one based on a delta time.
;
; EXAMPLE: 
; 
; COPYRIGHT:
; MODIFICATION HISTORY: 
; Written by: Nathaniel Frissell, 2011
;-
FUNCTION CALC_DYNFFT,dataStruct_in              $
    ,INTERPOLATE        = interpolate           $
    ,DETREND            = detrend               $
    ,WINDOWLENGTH       = windowlength          $
    ,MAGNITUDE          = magnitude             $
    ,PHASE              = phase                 $
    ,NORMALIZE          = normalize             $
    ,STEPLENGTH         = stepLength            $
    ,SCORE              = score                 $
    ,ONTIMES            = onTimes               $
    ,OFFTIMES           = offTimes              $
    ,NANTHRESHOLD       = NaNThreshold          $
    ,NOHANNING          = nohanning             $
    ,TIMEGRID           = timeGrid              $
    ,EPOCHTIME          = epochTime

IF ~KEYWORD_SET(interpolate)    THEN interpolate        = 5.
IF ~KEYWORD_SET(detrend)        THEN detrend            = 1.
IF ~KEYWORD_SET(windowlength)   THEN windowlength       = 600.
IF ~KEYWORD_SET(epochTime)      THEN epochTime          = 0

dataStruct      = dataStruct_in
dataStruct      = INTERPOLATOR(dataStruct,interpolate,EPOCHTIME=epochTime,TIMEGRID=timeGrid)
interpOut       = dataStruct

dataStruct      = WINDOWIZE(dataStruct, windowLength    $
                , DETREND       = detrend               $
                , EPOCHTIME     = epochTime             $
                , STEPLENGTH    = stepLength            $
                , NOHANNING     = nohanning             $
                , ONTIMES       = onTimes               $
                , OFFTIMES      = offTimes)

windowedTimeSeries = dataStruct.data

nWinTime        = N_ELEMENTS(dataStruct.data[0,*])
nTime           = N_ELEMENTS(dataStruct.data[*,0])
freq            = INDGEN(nWinTime)/(nWinTime*dataStruct.delta)
;Quickly calculate FFT of entire data array.  This only works for time windows without NaN's.
datafft         = FFT(dataStruct.data,DIMENSION=2)

;Calculate FFT for windows that contain missing data.  In order for the window to be valid,
;the fraction of NaN's present in a data window must be less than a specified NaNThreshold.
;Windows that contain missing data will have a lower frequency resolution than those which do not.  Therefore, the FFT's of these windows are linearly interpolated onto the original, higher-resolution grid.
IF KEYWORD_SET(nanThreshold) THEN BEGIN
    NaNs            = ~FINITE(dataStruct.data)
    nNanVec         = TOTAL(NaNs,2)
    nanFracVec      = nNanVec / nWinTime
    goodTimes       = WHERE((nanFracVec LE nanThreshold) AND (nanFracVec NE 0),nGoodTimes)
    IF nGoodTimes GT 0 THEN BEGIN
        FOR kk = 0, N_ELEMENTS(goodTimes)-1 DO BEGIN
            inx     = goodTimes[kk]
            window  = dataStruct.data[inx,*]
            goodInx = WHERE(FINITE(window),nGood)
            IF nGood GT 0 THEN BEGIN
                freqWin = INDGEN(nGood)/(nGood*dataStruct.delta)
                fftWin  = FFT(window[goodInx])
                fftInt  = INTERPOL(fftWin,freqWin,freq)

                dataFFT[inx,*]  = fftInt
                ;print,inx,nanfracvec[inx]
            ENDIF ;nGood GT 0
        ENDFOR
    ENDIF       ;nGoodTimes GT 0
ENDIF   ;KEYWORD_SET(nanThreshold)

IF KEYWORD_SET(magnitude)||KEYWORD_SET(normalize) THEN dataFFT = ABS(dataFFT)
IF KEYWORD_SET(normalize)       THEN dataFFT            = dataFFT / MAX(dataFFT)
IF KEYWORD_SET(phase)           THEN dataFFT            = ATAN(dataFFT,/PHASE)

IF KEYWORD_SET(score) THEN BEGIN
    FOR kk=0,N_ELEMENTS(dataFFT[*,0])-1 DO BEGIN
        tmp = dataFFT[kk,*]
        IF MAX(ABS(tmp),/NAN) GT 0 THEN tmp = ABS(tmp)/MAX(ABS(tmp),/NAN)
        tmp = tmp - MEAN(tmp,/NAN)
        dataFFT[kk,*] = tmp
    ENDFOR
ENDIF

RETURN, {time:                  dataStruct.time                 $
        ,freq:                  freq                            $
        ,fft:                   dataFFT                         $
        ,winTime:               dataStruct.winTime              $
        ,windowedTimeSeries:    windowedTimeSeries              $
        ,preFFTTimeVec:         dataStruct.preFFTTimeVec        $
        ,preFFTTSR:             dataStruct.preFFTTSR}
END
